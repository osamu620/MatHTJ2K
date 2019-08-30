classdef QCC_marker < handle
    properties
        Lqcc uint16
        Cqcc uint16
        Sqcc uint8
        SPqcc uint16 % for reversible uint8 is enough
        is_read logical
    end
    methods
        function outObj = QCC_marker(Csiz, idx_c, nG, NL, is_reversible, is_derived, exponent, mantissa)
            if nargin == 0
                outObj.is_read = false;
            else
                outObj.Cqcc = idx_c;
                Lqcc_base = 5;
                if Csiz >= 257
                    Lqcc_base = Lqcc_base + 1;
                end
                outObj.Sqcc = 0;
                n = 0;
                if is_reversible == true
                    outObj.Lqcc = Lqcc_base + 3*NL;
                    n = NL*3 + 1;
                elseif is_derived == true
                    outObj.Lqcc = Lqcc_base + 1;
                    n = 1;
                    outObj.Sqcc = outObj.Sqcc + 1;
                else
                    outObj.Lqcc = Lqcc_base + 1 + 6*NL;
                    n = NL*3 + 1;
                    outObj.Sqcc = outObj.Sqcc + 2;
                end
                assert(nG < 8 && nG >= 0);
                outObj.Sqcc = outObj.Sqcc + bitshift(nG, 5);
                for i=1:n
                    if is_reversible == true
                        outObj.SPqcc(i) = exponent(i);
                    else
                        outObj.SPqcc(i) = bitshift(exponent(i), 11) ...
                            + mantissa(i);
                    end
                end
            end
        end
        function out = get_number_of_guard_bits(inObj)%uint8
            out = bitshift(bitand(bin2dec('11100000'), inObj.Sqcc), -5);
        end
        function out = get_exponent(inObj, NL, Csiz) %uint8
            n = length(inObj.SPqcc);
            out = zeros(1, n, 'uint8');
            if Csiz < 257
                if inObj.Lqcc == 5 + 3*NL % no-quantization, reversible
                    for i = 1:n
                        out(i) = bitshift(inObj.SPqcc(i), -3);
                    end
                elseif inObj.Lqcc == 6 + 6*NL % quantized, irreversible, expounded
                    for i = 1:n
                        out(i) = bitshift(inObj.SPqcc(i), -11);
                    end
                else % quantized, irreversible, derived
                    out = bitshift(inObj.SPqcc, -11);
                end
            else
                if inObj.Lqcc == 6 + 3*NL % no-quantization, reversible
                    for i = 1:n
                        out(i) = bitshift(inObj.SPqcc(i), -3);
                    end
                elseif inObj.Lqcc == 7 + 6*NL % quantized, irreversible, expounded
                    for i = 1:n
                        out(i) = bitshift(inObj.SPqcc(i), -11);
                    end
                else % quantized, irreversible, derived
                    out = bitshift(inObj.SPqcc, -11);
                end
            end
        end
        function out = get_mantissa(inObj) %uint16
            n = length(inObj.SPqcc);
            out = zeros(1, n, 'uint16');
            mask_Low_11 = uint16(2^11-1);
            for i = 1:n
                out(i) = bitand(mask_Low_11, inObj.SPqcc(i));
            end
        end
        function out = is_derived(inObj) %logical
            switch bitand(bin2dec('00011111'), inObj.Sqcc)
                case 0 % no quantization
                    out = false;
                case 1 % scalar_quantization_derived
                    out = true;
                case 2 % scalar_quantization_expounded
                    out = false;
                otherwise
                    error('Sqcc value is incorrect.\n');
            end
        end
        function read_QCC(inObj, hDsrc, Csiz)
            assert(isa(hDsrc,'jp2_data_source'));
            assert(isa(inObj,'QCC_marker'), 'input for read_QCC() shall be QCC_marker class.');
            inObj.Lqcc = get_word(hDsrc);
            if Csiz < 257
                inObj.Cqcc = get_byte(hDsrc);
                if mod(inObj.Lqcc - 5, 3) == 0
                    is_reversible = true;
                    NL = floor_quotient_int(inObj.Lqcc - 5, 3, 'uint8');
                elseif inObj.Lqcc == 6
                    NL = 0;% derived
                    is_reversible = false;
                else
                    NL = floor_quotient_int(inObj.Lqcc - 6, 6, 'uint8');
                    is_reversible = false;
                end
            else
                inObj.Cqcc = get_word(hDsrc);
                if mod(inObj.Lqcc - 6, 3) == 0
                    is_reversible = true;
                    NL = floor_quotient_int(inObj.Lqcc - 6, 3, 'uint8');
                elseif inObj.Lqcc == 7
                    NL = 0;% derived
                    is_reversible = false;
                else
                    NL = floor_quotient_int(inObj.Lqcc - 7, 6, 'uint8');
                    is_reversible = false;
                end
            end
            if NL == 0 % derived
                n = 1;
            else
                n = NL*3 + 1;
            end
            %
            inObj.Sqcc = get_byte(hDsrc);
            is_derived = false;
            SPqcx_size = 0;
            switch bitand(bin2dec('00011111'), inObj.Sqcc)
                case 0 % no quantization
                    assert(is_reversible == true);
                    SPqcx_size = 8;
                case 1 % scalar_quantization_derived
                    assert(is_reversible == false);
                    SPqcx_size = 16;
                    is_derived = true;
                case 2 % scalar_quantization_expounded
                    assert(is_reversible == false);
                    SPqcx_size = 16;
                otherwise
                    error('Sqcc value is incorrect.\n');
            end
            %
            if is_derived == false
                for i=1:n
                    if SPqcx_size == 8 % for reversible transform
                        % the first 5 bits are the exponent value of each subband's dynamic range
                        inObj.SPqcc(i) = get_byte(hDsrc);
                    else % for irreversible transform
                        inObj.SPqcc(i) = get_word(hDsrc);
                    end
                end
            else
                inObj.SPqcc = get_word(hDsrc);
            end
            %
            inObj.is_read = true;
        end
        function write_QCC(inObj, m, hDdst, Csiz, NL, transformation)
            assert(isa(hDdst,'jp2_data_destination'));
            assert(isa(inObj,'QCC_marker'), 'input for write_QCC() shall be QCC_marker class.');
            put_word(hDdst, m.QCC);
            put_word(hDdst, inObj.Lqcc);
            if Csiz < 257
                put_byte(hDdst, inObj.Cqcc);
            else
                put_word(hDdst, inObj.Cqcc);
            end
            
            put_byte(hDdst, inObj.Sqcc);
            
            if NL == 0 % derived
                n = 1;
            else
                n = NL*3 + 1;
            end
            %
            for i=1:n
                if transformation == 1 % 5x3 lossless
                    put_byte(hDdst, inObj.SPqcc(i));
                else % 9x7 lossy
                    put_word(hDdst, inObj.SPqcc(i));
                end
            end
        end
        function copy_from_QCD(inObj, idx_c, hQCD)
            inObj.Cqcc = idx_c;
            inObj.Sqcc = hQCD.Sqcd;
            inObj.SPqcc = hQCD.SPqcc;
        end
    end
end