classdef COC_marker < handle
    properties
        Lcoc uint16
        Ccoc uint16
        Scoc uint8
        SPcoc uint8
        is_read logical
    end
    methods
        % Constructor
        function outObj = COC_marker(Csiz, idx_c, is_maximum_precincts ...
                , number_of_decomposition_levels, codeblock_width_exponent, codeblock_height_exponent ...
                , codeblock_style, transformation, PPx, PPy)
            if nargin == 0
                outObj.is_read = false;
            else
                outObj.Ccoc = idx_c;
                outObj.Lcoc = 9;
                if Csiz >= 257
                    outObj.Lcoc = outObj.Lcoc + 1;
                end
                % Lcoc
                if is_maximum_precincts == false
                    assert(length(PPx) == length(PPy));
                    outObj.Lcoc = outObj.Lcoc + 1;
                    outObj.Lcoc = outObj.Lcoc + number_of_decomposition_levels;
                end
                
                % Scoc
                outObj.Scoc = 0;
                if is_maximum_precincts == false
                    outObj.Scoc = outObj.Scoc + 1;
                end
                
                % SPcoc parameters
                outObj.SPcoc(1) = number_of_decomposition_levels;
                assert(codeblock_width_exponent >= 0 && codeblock_width_exponent <= 8);
                assert(codeblock_height_exponent >= 0 && codeblock_height_exponent <= 8);
                assert(codeblock_width_exponent + codeblock_height_exponent <= 10);
                outObj.SPcoc(2) = codeblock_width_exponent;
                outObj.SPcoc(3) = codeblock_height_exponent;
                
                
                outObj.SPcoc(4) = codeblock_style;
                
                outObj.SPcoc(5) = transformation;
                
                M_OFFSET = 1;
                if is_maximum_precincts == false
                    for i=0:number_of_decomposition_levels
                        if length(PPx) >= (i+M_OFFSET)
                            lastPPx = PPx(i+M_OFFSET);
                        end
                        if length(PPx) >= (i+M_OFFSET)
                            lastPPy = PPy(i+M_OFFSET);
                        end
                        outObj.SPcoc(6+number_of_decomposition_levels-i) = lastPPx + 16*lastPPy;
                    end
                end
                
            end
        end
        function out = is_maximum_precincts(inObj)
            if bitand(inObj.Scoc, 1) == 0
                out = true;
            else
                out = false;
            end
        end
        function out = get_number_of_decomposition_levels(inObj)
            out = inObj.SPcoc(1);
        end
        function out = get_codeblock_size_in_exponent(inObj)
            height = inObj.SPcoc(3) + 2;
            width = inObj.SPcoc(2) + 2;
            assert(width >= 2 && width <= 10);
            assert(height >= 2 && height <= 10);
            assert(width + height <= 12);
            out = [width, height];
        end
        function out = is_selective_arithmetic_coding_bypass(inObj)
            if bitand(inObj.SPcoc(4), 2^0) == 2^0
                out = true;
            else
                out = false;
            end
        end
        function out = is_reset_context_probabilities(inObj)
            if bitand(inObj.SPcoc(4), 2^1) == 2^1
                out = true;
            else
                out = false;
            end
        end
        function out = is_termination_on_each_coding_pass(inObj)
            if bitand(inObj.SPcoc(4), 2^2) == 2^2
                out = true;
            else
                out = false;
            end
        end
        function out = is_vertically_causal_context(inObj)
            if bitand(inObj.SPcoc(4), 2^3) == 2^3
                out = true;
            else
                out = false;
            end
        end
        function out = is_predictable_termination(inObj)
            if bitand(inObj.SPcoc(4), 2^4) == 2^4
                out = true;
            else
                out = false;
            end
        end
        function out = is_segmentation_symbols(inObj)
            if bitand(inObj.SPcoc(4), 2^5) == 2^5
                out = true;
            else
                out = false;
            end
        end
        function out = get_codeblock_style(inObj)
            out = inObj.SPcoc(4);
        end
        function out = get_transformation(inObj)
            out = inObj.SPcoc(5);
        end
        function out = get_precinct_size_in_exponent(inObj)
            x_0F = uint8(15);
            x_F0 = uint8(240);
            M_OFFSET = 1;
            NL = get_number_of_decomposition_levels(inObj);
            out = zeros(NL + 1, 2);
            for i = 0:NL
                if is_maximum_precincts(inObj) == false
                    out(i+M_OFFSET,1) = bitand(inObj.SPcoc(6+i), x_0F); % PPx
                    out(i+M_OFFSET,2) = bitshift(bitand(inObj.SPcoc(6+i), x_F0), -4); % PPy
                else
                    out(i+M_OFFSET,1) = 15;% maximum_precincts
                    out(i+M_OFFSET,2) = 15;% maximum_precincts
                end
            end
        end
        function read_COC(inObj, hDsrc, Csiz)
            assert(isa(hDsrc,'jp2_data_source'));
            assert(isa(inObj,'COC_marker'), 'input for read_COC() shall be COC_marker class.');
            % Lcoc
            inObj.Lcoc = get_word(hDsrc);
            assert(inObj.Lcoc >=9 && inObj.Lcoc <= 43);
            % Ccoc
            Lcoc_base = 9;
            if Csiz < 257
                inObj.Ccoc = get_byte(hDsrc);
            else
                inObj.Ccoc = get_word(hDsrc);
                Lcoc_base = Lcoc_base + 1;
            end
            % Scoc
            inObj.Scoc = get_byte(hDsrc);
           
            % SPcoc parameters
            inObj.SPcoc(1) = get_byte(hDsrc);
            
            if inObj.is_maximum_precincts() == false
                Lcoc_base = Lcoc_base + 1;
                assert(inObj.Lcoc == Lcoc_base + get_number_of_decomposition_levels(inObj), 'Lcoc is incorrect.');
            else
                assert(inObj.Lcoc == Lcoc_base, 'Lcoc is incorrect.');
            end
            
            inObj.SPcoc(2) = get_byte(hDsrc);
            inObj.SPcoc(3) = get_byte(hDsrc);
            inObj.SPcoc(4) = get_byte(hDsrc);
            inObj.SPcoc(5) = get_byte(hDsrc);
            if is_maximum_precincts(inObj) == false
                for i=0:get_number_of_decomposition_levels(inObj)
                    inObj.SPcoc(6+i) = get_byte(hDsrc);
                end
            end
            inObj.is_read = true;
        end
        function write_COC(inObj, m, hDdst, Csiz)
            assert(isa(hDdst,'jp2_data_destination'));
            assert(isa(inObj,'COC_marker'), 'input for wirte_COC() shall be COC_marker class.');
            put_word(hDdst, m.COC);
            NL = inObj.get_number_of_decomposition_levels();
            if inObj.is_maximum_precincts() == true
                if Csiz < 257
                    inObj.Lcoc = 9;
                else
                    inObj.Lcoc = 10;
                end
            else
                if Csiz < 257
                    inObj.Lcoc = 10 + NL;
                else
                    inObj.Lcoc = 11 + NL;
                end
            end
            put_word(hDdst, inObj.Lcoc);
            if Csiz < 257
                put_byte(hDdst, inObj.Ccoc);
            else
                put_word(hDdst, inObj.Ccoc);
            end
            put_byte(hDdst, inObj.Scoc);
            n = length(inObj.SPcoc);
            for i = 1:n
                put_byte(hDdst, inObj.SPcoc(i));
            end
        end
        function copy_from_COD(inObj, idx_c, hCOD)
            inObj.Ccoc = uint16(idx_c);
            inObj.Scoc = bitand(hCOD.Scod, 1);% only precinct size
            inObj.SPcoc = hCOD.SPcod;
        end
        function fix_params(inObj, Csiz)
            NL = inObj.get_number_of_decomposition_levels();
            if inObj.is_maximum_precincts() == true
                if Csiz < 257
                    inObj.Lcoc = 9;
                else
                    inObj.Lcoc = 10;
                end
            else
                inObj.SPcoc = inObj.SPcoc(1:6+NL);
                if Csiz < 257
                    inObj.Lcoc = 10 + NL;
                else
                    inObj.Lcoc = 11 + NL;
                end
            end
        end
    end
end