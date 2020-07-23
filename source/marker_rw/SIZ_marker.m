classdef SIZ_marker < handle
    properties
        Lsiz uint16
        Rsiz uint16
        Xsiz uint32
        Ysiz uint32
        XOsiz uint32
        YOsiz uint32
        XTsiz uint32
        YTsiz uint32
        XTOsiz uint32
        YTOsiz uint32
        Csiz uint16
        Ssiz uint8
        XRsiz uint8
        YRsiz uint8
        signed_inputs logical
        component_bit_depth uint8
        needCAP logical
        is_read logical
    end
    methods
        function outObj = SIZ_marker(X, Y, XO, YO, XT, YT, XTO, YTO, C, S, XR, YR, is_signed, needCAP)
            if nargin == 0
                outObj.Lsiz = 0;
                outObj.Rsiz = 0;
                outObj.Xsiz = 0;
                outObj.Ysiz = 0;
                outObj.XOsiz = 0;
                outObj.YOsiz = 0;
                outObj.XTsiz = 0;
                outObj.YTsiz = 0;
                outObj.XTOsiz = 0;
                outObj.YTOsiz = 0;
                outObj.Csiz = 0;
                outObj.signed_inputs = false;
                outObj.needCAP = false;
                outObj.is_read = false;
            else
                if needCAP == true
                    R = 2^14;
                else
                    R = 0;
                end
                outObj.Lsiz = 38 + 3 * C;
                outObj.Rsiz = R;
                outObj.Xsiz = X;
                outObj.Ysiz = Y;
                outObj.XOsiz = XO;
                outObj.YOsiz = YO;
                outObj.XTsiz = XT;
                outObj.YTsiz = YT;
                outObj.XTOsiz = XTO;
                outObj.YTOsiz = YTO;
                outObj.Csiz = C;
                for i = 1:C
                    outObj.signed_inputs(i) = is_signed(i);
                    outObj.component_bit_depth(i) = S(i) + 1;
                    if is_signed(i) == true
                        S(i) = S(i) + 128;
                    end
                    outObj.Ssiz(i) = S(i);
                    outObj.XRsiz(i) = XR(i);
                    outObj.YRsiz(i) = YR(i);
                end

                outObj.needCAP = needCAP;
                outObj.is_read = false;
            end
        end
        function out = get_RI(inObj)
            out = zeros(1, inObj.Csiz, 'uint8');
            for i = 1:inObj.Csiz
                out(i) = bitand(inObj.Ssiz(i), 127) + 1;
            end
        end
        function out = get_is_signed(inObj)
            out = zeros(1, inObj.Csiz, 'uint8');
            for i = 1:inObj.Csiz
                out(i) = bitshift(bitand(inObj.Ssiz(i), 128), -7);
            end
        end
        function read_SIZ(inObj, hDsrc)
            assert(isa(hDsrc, 'jp2_data_source'));
            assert(isa(inObj, 'SIZ_marker'), 'input for read_SIZ() shall be SIZ_marker class.');
            %
            inObj.Lsiz = get_word(hDsrc);
            inObj.Rsiz = get_word(hDsrc);
            %
            Rsiz_2MSBs = bitshift(inObj.Rsiz, -14);
            if Rsiz_2MSBs >= 2
                error('This codestream uses Part 2 capabilities. Part 2 is not supported.\n');
            elseif Rsiz_2MSBs == 1
                inObj.needCAP = true;
            end
            %
            inObj.Xsiz = get_dword(hDsrc);
            inObj.Ysiz = get_dword(hDsrc);
            inObj.XOsiz = get_dword(hDsrc);
            inObj.YOsiz = get_dword(hDsrc);
            inObj.XTsiz = get_dword(hDsrc);
            inObj.YTsiz = get_dword(hDsrc);
            inObj.XTOsiz = get_dword(hDsrc);
            inObj.YTOsiz = get_dword(hDsrc);
            inObj.Csiz = get_word(hDsrc);
            assert(inObj.Csiz == (inObj.Lsiz - 38) / 3, 'Lsiz and/or Csiz are incorrect.\n');
            for iComponent = 1:inObj.Csiz
                inObj.Ssiz(iComponent) = get_byte(hDsrc);
                inObj.XRsiz(iComponent) = get_byte(hDsrc);
                inObj.YRsiz(iComponent) = get_byte(hDsrc);
                inObj.signed_inputs(iComponent) = false;
                if bitand(inObj.Ssiz(iComponent), 128) == 1
                    inObj.signed_inputs(iComponent) = true;
                end
                inObj.component_bit_depth(iComponent) = mod(inObj.Ssiz(iComponent), 128) + 1;
                assert(inObj.component_bit_depth(iComponent) <= 38, 'Component bit depth is too large.\n');
            end
            %
            inObj.is_read = true;
        end
        function write_SIZ(inObj, m, hDdst)
            assert(isa(hDdst, 'jp2_data_destination'));
            assert(isa(inObj, 'SIZ_marker'), 'input for write_SIZ() shall be SIZ_marker class.');
            assert(inObj.Lsiz == 38 + 3 * inObj.Csiz);
            put_word(hDdst, m.SIZ);
            put_word(hDdst, inObj.Lsiz);
            put_word(hDdst, inObj.Rsiz);
            put_dword(hDdst, inObj.Xsiz);
            put_dword(hDdst, inObj.Ysiz);
            put_dword(hDdst, inObj.XOsiz);
            put_dword(hDdst, inObj.YOsiz);
            put_dword(hDdst, inObj.XTsiz);
            put_dword(hDdst, inObj.YTsiz);
            put_dword(hDdst, inObj.XTOsiz);
            put_dword(hDdst, inObj.YTOsiz);
            put_word(hDdst, inObj.Csiz);
            for i = 1:inObj.Csiz
                put_byte(hDdst, inObj.Ssiz(i));
                put_byte(hDdst, inObj.XRsiz(i));
                put_byte(hDdst, inObj.YRsiz(i));
            end
        end
    end
end