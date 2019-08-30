classdef QCD_marker < handle
    properties
        Lqcd uint16
        Sqcd uint8
        SPqcd uint16 % for reversible uint8 is enough
        is_read logical
    end
    methods
        function outObj = QCD_marker(nG, NL, transformation, is_derived, exponent, mantissa)
            if nargin == 0
                outObj.is_read = false;
            else
                outObj.Sqcd = 0;
                n = 0;
                if transformation == 1
                    % lossless
                    outObj.Lqcd = 4 + 3*NL;
                    n = NL*3 + 1;
                elseif is_derived == true
                    outObj.Lqcd = 5;
                    n = 1;
                    outObj.Sqcd = outObj.Sqcd + 1;
                else
                    outObj.Lqcd = 5 + 6*NL;
                    n = NL*3 + 1;
                    outObj.Sqcd = outObj.Sqcd + 2;
                end
                assert(nG < 8 && nG >= 0);
                outObj.Sqcd = outObj.Sqcd + bitshift(nG, 5);
                for i=1:n
                    if transformation == 1
                        % lossless
                        outObj.SPqcd(i) = exponent(i);
                    else
                        outObj.SPqcd(i) = bitshift(exponent(i), 11) ...
                            + mantissa(i);
                    end
                end
            end
        end
        function out = get_number_of_guard_bits(inObj)%uint8
            out = bitshift(bitand(bin2dec('11100000'), inObj.Sqcd), -5);
        end
        function out = get_exponent(inObj) %uint8
                n = length(inObj.SPqcd);
                out = zeros(1, n, 'uint8');
                if mod(inObj.Lqcd - 4, 3) == 0 % no-quantization, reversible
                    for i = 1:n
                        out(i) = bitshift(inObj.SPqcd(i), -3);
                    end
                else % quantized, irreversible, expounded
                    for i = 1:n
                        out(i) = bitshift(inObj.SPqcd(i), -11);
                    end
                end
        end
        function out = get_mantissa(inObj) %uint16
            n = length(inObj.SPqcd);
            out = zeros(1, n, 'uint16');
            mask_Low_11 = uint16(2^11-1);
            for i = 1:n
                out(i) = bitand(mask_Low_11, inObj.SPqcd(i));
            end
        end
        function out = is_derived(inObj) %logical
            switch bitand(bin2dec('00011111'), inObj.Sqcd)
                case 0 % no quantization
                    out = false;
                case 1 % scalar_quantization_derived
                    out = true;
                case 2 % scalar_quantization_expounded
                    out = false;
                otherwise
                    error('Sqcd value is incorrect.\n');
            end
        end
        function read_QCD(inObj, hDsrc)
            assert(isa(hDsrc,'jp2_data_source'));
            assert(isa(inObj,'QCD_marker'), 'input for read_QCD() shall be QCD_marker class.');
            inObj.Lqcd = get_word(hDsrc);
            if mod(inObj.Lqcd - 4, 3) == 0 %Lqcd == (4+3*handle_COD.number_of_decomposition_levels)
                NL = floor_quotient_int(inObj.Lqcd - 4, 3, 'uint8');
                %fprintf('no_quantization\n');
            elseif mod(inObj.Lqcd - 5, 6) == 0 %Lqcd == (5+6*handle_COD.number_of_decomposition_levels), or Lqcd== 5
                NL = floor_quotient_int(inObj.Lqcd - 5, 6, 'uint8');
            end
            %
            if NL == 0
                n = 1;
            else
                n = NL*3 + 1;
            end
            %
            inObj.Sqcd = get_byte(hDsrc);
            is_derived = false;
            SPqcx_size = 0;
            switch bitand(bin2dec('00011111'), inObj.Sqcd)
                case 0 % no quantization
                    SPqcx_size = 8;
                case 1 % scalar_quantization_derived
                    SPqcx_size = 16;
                    is_derived = true;
                case 2 % scalar_quantization_expounded
                    SPqcx_size = 16;
                otherwise
                    error('Sqcd value is incorrect.\n');
            end
            %
            if is_derived == false
                for i=1:n
                    if SPqcx_size == 8 % for reversible transform
                        % the first 5 bits are the exponent value of each subband's dynamic range
                        inObj.SPqcd(i) = get_byte(hDsrc);
                    else % for irreversible transform
                        inObj.SPqcd(i) = get_word(hDsrc);
                    end
                end
            else
                inObj.SPqcd = get_word(hDsrc);
            end
            %
            inObj.is_read = true;
        end
        function write_QCD(inObj, m, hDdst)
            assert(isa(hDdst,'jp2_data_destination'));
            assert(isa(inObj,'QCD_marker'), 'input for write_QCD() shall be QCD_marker class.');
            put_word(hDdst, m.QCD);
            put_word(hDdst, inObj.Lqcd);
            put_byte(hDdst, inObj.Sqcd);
            %
            is_reversible = false;
            if mod(inObj.Lqcd - 4, 3) == 0 %Lqcd == (4+3*handle_COD.number_of_decomposition_levels)
                NL = floor_quotient_int(inObj.Lqcd - 4, 3, 'uint8');
                is_reversible = true;
                %fprintf('no_quantization\n');
            elseif mod(inObj.Lqcd - 5, 6) == 0 %Lqcd == (5+6*handle_COD.number_of_decomposition_levels), or Lqcd== 5
                NL = floor_quotient_int(inObj.Lqcd - 5, 6, 'uint8');
            end
            %
            if NL == 0
                n = 1;
            else
                n = NL*3 + 1;
            end
            %
            for i=1:n
                if is_reversible == true
                    put_byte(hDdst, inObj.SPqcd(i));
                else
                    put_word(hDdst, inObj.SPqcd(i));
                end
            end
        end
    end
end