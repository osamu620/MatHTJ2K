function [output, composite_output, elapsedTime, time_for_blockcoding] = decode_HTJ2K(file_name, use_MEX, reduce_NL, is_float_output)
% decode_HTJ2K   : JPEG 2000 Part 1 (ISO/IEC 15444-1) and HTJ2K (JPEG 2000 Part 15, ISO/IEC 15444-15) decompression.
%
% Usage:
% [output, composite_output, total_processing_time(sec), block_copding_time(sec)] = decode_HTJ2K(filename, <use_MEX, is_float_output>)
%
% filename               : File name of compressed codestream or ".jp2" or ".jph" file.
% use_MEX, true or false : If true, MEX version of blockcoding algorithm is used. Default is true.
% reduce_NL              : Set the number of highest resolution levels to be discarded.
% (is_float_output       : experimental)
% August 29, 2019 (c) Osamu WATANABE, Takushoku University and Vrije Universiteit Brussel
%
% TODO: ICC profile interpretation.
M_OFFSET = 1;
coder.extrinsic('tic');
DEBUG = 1;

if nargin < 4
    is_float_output = false;
end
if nargin < 3
    reduce_NL = 0;
end
if nargin < 2
    use_MEX = true;
end
jp2Boxes = [];
if endsWith(file_name, '.jp2', 'IgnoreCase', true) || endsWith(file_name, '.jph', 'IgnoreCase', true)
    filebuf = memmapfile(file_name);
    j2c_source = jp2_data_source(filebuf.Data);
    jp2Boxes = jp2_boxes(j2c_source, 0);
    jp2Boxes.read_contents();
    j2c_source = jp2_data_source(jp2Boxes.codestream);
else
    filebuf = memmapfile(file_name);
    j2c_source = jp2_data_source(filebuf.Data);
end

time_start = tic;
time_for_blockcoding = 0.0;

%% load defined markers
JP2markers = jp2_markers;
main_header = j2k_main_header;

%% read main header
[PPM_header] = read_main_header(j2c_source, JP2markers, main_header);

% parse CAP 15, if necessary
if isempty(main_header.CAP) == false
    [main_header.Cap15_b14_15, main_header.Cap15_b13, main_header.Cap15_b12, ...
        main_header.Cap15_b12, main_header.Cap15_b5, main_header.Cap15_b0_4, ...
        main_header.Cap15_magb] = main_header.CAP.parse_Ccap15();
end
% determine number of tiles
numXtiles = ceil_quotient_int((main_header.SIZ.Xsiz - main_header.SIZ.XTOsiz), main_header.SIZ.XTsiz, 'uint32');
numYtiles = ceil_quotient_int((main_header.SIZ.Ysiz - main_header.SIZ.YTOsiz), main_header.SIZ.YTsiz, 'uint32');
% buffer for decoded components
output_YCbCr = cell(main_header.SIZ.Csiz, 1);
% buffer for inverse Color transform (size of components will be adjusted for inverse color trafo)
composite_output_RGB = zeros(ceil(double(main_header.SIZ.Ysiz) / 2^reduce_NL), ...
    ceil(double(main_header.SIZ.Xsiz) / 2^reduce_NL), main_header.SIZ.Csiz, 'double');

%% read all tile-parts
tile_Set = [];
for i = 1:numXtiles * numYtiles
    if isempty(tile_Set) == true
        tile_Set = jp2_tile;
    else
        tile_Set = add_tile(tile_Set);
    end
end
read_tiles(tile_Set, numXtiles, j2c_source, JP2markers, main_header, reduce_NL);

%% decode tile
reverseStr = '';
for n_tile = 1:length(tile_Set)
    currentTile = tile_Set(n_tile);
    if DEBUG == 1
        msg = sprintf('\r==== Decoding tile # %3d, %3d/%3d ====\n', currentTile.idx, currentTile.idx + 1, numXtiles * numYtiles);
        fprintf([reverseStr, msg]);
        reverseStr = repmat(sprintf('\b'), 1, length(msg));
    end
    currentTile.src_data.pos = 0;
    time_for_blockcoding = decode_tile(currentTile, main_header, PPM_header, use_MEX, reduce_NL, time_for_blockcoding);
    composite_output_RGB = currentTile.put_tile_into_composite_output(main_header, composite_output_RGB, reduce_NL);
    output_YCbCr = currentTile.put_tile_into_output(main_header, output_YCbCr, reduce_NL);
end

%% put decoded tile image into extracted corrdinate from reference grid
y_origin = ceil(double(main_header.SIZ.YOsiz) / 2^reduce_NL);
x_origin = ceil(double(main_header.SIZ.XOsiz) / 2^reduce_NL);
composite_output_RGB = composite_output_RGB(y_origin + M_OFFSET:end, x_origin + M_OFFSET:end, :);
for c = 0:main_header.SIZ.Csiz - 1
    output_YCbCr{c+M_OFFSET} = output_YCbCr{c+M_OFFSET} ...
        (ceil_quotient_int(main_header.SIZ.YOsiz, main_header.SIZ.YRsiz(c + M_OFFSET) * 2^reduce_NL, 'int32') + M_OFFSET:end, ...
        ceil_quotient_int(main_header.SIZ.XOsiz, main_header.SIZ.XRsiz(c + M_OFFSET) * 2^reduce_NL, 'int32') + M_OFFSET:end);
end

%% Inverse DC offset and clipping pixel value
is_signed = main_header.SIZ.get_is_signed();
bitDepth = double(main_header.SIZ.get_RI());
composite_output = composite_output_RGB;
output = output_YCbCr;

if is_float_output == true
    interpreted_as_int32 = int32(composite_output);
    out_as_single = zeros(size(interpreted_as_int32), 'single');
    for iRows = 1:main_header.SIZ.Ysiz
        for c = 0:main_header.SIZ.Csiz - 1
            out_as_single(iRows, :, c + M_OFFSET) = ...
                typecast(interpreted_as_int32(iRows, :, c + M_OFFSET), 'single');
        end
    end
    out_as_single(isnan(out_as_single)) = 0;
    composite_output = out_as_single;
    for c = 0:main_header.SIZ.Csiz - 1
        interpreted_as_int32 = int32(output{c + M_OFFSET});
        for iRows = 1:main_header.SIZ.Ysiz
            out_as_single(iRows, :) = ...
                typecast(interpreted_as_int32(iRows, :), 'single');
        end
        out_as_single(isnan(out_as_single)) = 0;
        output{c+M_OFFSET} = out_as_single;
    end
else
    for c = 0:main_header.SIZ.Csiz - 1
        BPC = double(bitand(main_header.SIZ.Ssiz(c + M_OFFSET), 127));
        DC_offset = 2^(BPC);
        if is_signed(c + M_OFFSET) == false
            composite_output(:, :, c + M_OFFSET) = composite_output_RGB(:, :, c + M_OFFSET) + DC_offset;
            %             if c == 0
            %                 output{c + M_OFFSET} = output{c + M_OFFSET} + DC_offset;
            %             end
        end
        % rounding to nearest integer
        composite_output(:, :, c + M_OFFSET) = round(composite_output(:, :, c + M_OFFSET));
        output{c+M_OFFSET} = round(output{c + M_OFFSET});
        % clipping the dynamic range
        tmp = composite_output(:, :, c + M_OFFSET);
        if is_signed(c + M_OFFSET) == false
            MAXVAL = 2^bitDepth(c + M_OFFSET) - 1;
            MINVAL = 0;
        else
            MAXVAL = 2^(bitDepth(c + M_OFFSET) - 1) - 1;
            MINVAL = -2^(bitDepth(c + M_OFFSET) - 1);
        end
        tmp(tmp > MAXVAL) = MAXVAL;
        tmp(tmp < MINVAL) = MINVAL;
        composite_output(:, :, c + M_OFFSET) = tmp;
    end
end

%% If the input file is .jp2 or .jph, color conversion may be used.
num_alpha = 0;
if isempty(jp2Boxes) == false
    [composite_output, num_alpha] = jp2_color_conversion(composite_output, jp2Boxes, main_header);
end

%% convert composite output into unsigned integer format
for c = 0:main_header.SIZ.Csiz - 1 - num_alpha
    BPC = double(bitand(main_header.SIZ.Ssiz(c + M_OFFSET), 127));
    DC_offset = 2^(BPC);
    if is_signed(c + M_OFFSET) == true
        composite_output(:, :, c + M_OFFSET) = composite_output_RGB(:, :, c + M_OFFSET) + DC_offset;
    end
    if BPC + 1 <= 8
        s_up = 8 - (BPC + 1);
        composite_output(:, :, c + M_OFFSET) = composite_output(:, :, c + M_OFFSET) .* 2^s_up;
        cName = 'uint8';
    elseif BPC + 1 <= 16
        s_up = 16 - (BPC + 1);
        composite_output(:, :, c + M_OFFSET) = composite_output(:, :, c + M_OFFSET) .* 2^s_up;
        cName = 'uint16';
    else
        s_up = 32 - (BPC + 1);
        composite_output(:, :, c + M_OFFSET) = composite_output(:, :, c + M_OFFSET) .* 2^s_up;
        cName = 'uint32';
    end
end
switch cName
    case 'uint8'
        composite_output = uint8(composite_output);
    case 'uint16'
        composite_output = uint16(composite_output);
    case 'uint32'
        composite_output = uint32(composite_output);
end
elapsedTime = toc(time_start);

%% end
delete(j2c_source);

fprintf('%f, %f\n', elapsedTime, time_for_blockcoding);