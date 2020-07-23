function [composite_out, num_alpha] = jp2_color_conversion(composite_in, jp2Boxes, main_header)
M_OFFSET = 1;

buf = composite_in;
alpha = [];
num_non_alpha = 0;
if isempty(jp2Boxes.headerBox.cdef) == false
    for c = 0:main_header.SIZ.Csiz - 1
        if jp2Boxes.headerBox.cdef.Typ_i(c + M_OFFSET) == 1
            alpha = buf(:, :, jp2Boxes.headerBox.cdef.Cn_i(c + M_OFFSET) + M_OFFSET) / max(max(buf(:, :, jp2Boxes.headerBox.cdef.Cn_i(c + M_OFFSET) + M_OFFSET)));
        else
            tmp(:, :, num_non_alpha + M_OFFSET) = buf(:, :, jp2Boxes.headerBox.cdef.Cn_i(c + M_OFFSET) + M_OFFSET);
            num_non_alpha = num_non_alpha + 1;
        end
    end
    composite_in = tmp .* alpha;
end
num_alpha = main_header.SIZ.Csiz - num_non_alpha;
if isempty(jp2Boxes.headerBox.pclr) == false
    for i = 1:size(buf, 1)
        for j = 1:size(buf, 2)
            composite_in(i, j, 1) = jp2Boxes.headerBox.pclr.C_ji(buf(i, j) + M_OFFSET, 1);
            composite_in(i, j, 2) = jp2Boxes.headerBox.pclr.C_ji(buf(i, j) + M_OFFSET, 2);
            composite_in(i, j, 3) = jp2Boxes.headerBox.pclr.C_ji(buf(i, j) + M_OFFSET, 3);
        end
    end
end
if isempty(jp2Boxes.headerBox.colr) == false
    BPC = double(jp2Boxes.headerBox.ihdr.BPC);
    EnumCS = jp2Boxes.headerBox.colr.EnumCS;
    if jp2Boxes.headerBox.colr.METH == 2 || jp2Boxes.headerBox.colr.METH == 3
        iccProfile = iccread('tmpicc.icc');

        switch iccProfile.Header.DeviceModel
            case 'ROMM'
                fprintf('INFO: Embedde icc profile indicates ROMM-RGB. Composite output is converted to sRGB.\n');
                composite_out = rommRGB2sRGB(composite_in);
            case 'eRGB'
                fprintf('INFO: Embedde icc profile indicates e-sRGB. Composite output is converted to sRGB.\n');
                composite_out = esRGB2sRGB(composite_in, double(BPC + 1));
            case {'GREY', 'GRAY'}
                fprintf('INFO: Embedde icc profile indicates Grayscale.\n');
                cform = makecform('graytrc', iccProfile, 'Direction', 'inverse');
                XYZ(:, :, 1) = zeros(size(composite_in));
                XYZ(:, :, 2) = composite_in;
                XYZ(:, :, 3) = zeros(size(composite_in));
                composite_out = applycform(XYZ / 2^(BPC + 1), cform);
                composite_out = round(composite_out .* 2^(BPC + 1));
        end
        delete tmpicc.icc;
    end
    Lmin = 0;
    Lmax = 0;
    if isempty(EnumCS) == false
        switch jp2Boxes.headerBox.colr.EnumCS
            case 16 % sRGB
                Lmin = 0;
                Lmax = 255;
                composite_out = composite_in;
            case 17 % greyscale
                Lmin = 0;
                Lmax = 1.0;
                if BPC > 127 % signed
                    fprintf('WARNING: EnumCS = 17 for signed data is invalid\n');
                else % unsigned
                    composite_out = composite_in;
                end
            case 18 % sYCC
                Lmin = 0;
                Lmax = 255;
                composite_tmp(:, :, 1) = composite_in(:, :, 1) / Lmax;
                composite_tmp(:, :, 2) = (composite_in(:, :, 2) - 128) / Lmax;
                composite_tmp(:, :, 3) = (composite_in(:, :, 3) - 128) / Lmax;
                composite_out = myycbcr2rgb(composite_tmp, 0);
                composite_out = round(255 * composite_out);
            case 20 % e-sRGB
                composite_out = esRGB2sRGB(composite_in, double(jp2Boxes.headerBox.ihdr.BPC + 1));
            case 21 % ROMM-RGB
                composite_out = rommRGB2sRGB(composite_in);
        end
    end
    is_signed = bitshift(bitand(BPC, 128), -7);
    if is_signed == true
        composite_out = composite_out + 2^BPC;
    end
else
    composite_out = composite_in;
end
