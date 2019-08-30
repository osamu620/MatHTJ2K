classdef COD_marker < handle
    properties
        Lcod uint16
        Scod uint8
        SGcod uint32
        SPcod uint8
        is_read logical
    end
    methods
        % Constructor
        function outObj = COD_marker(is_maximum_precincts, use_SOP, use_EPH ...
                , progression_order, number_of_layers, multiple_component_transform ...
                , number_of_decomposition_levels, codeblock_width_exponent, codeblock_height_exponent ...
                , codeblock_style, transformation, PPx, PPy)
            if nargin == 0
                outObj.is_read = false;
            else
                % Lcod
                if is_maximum_precincts == true
                    outObj.Lcod = 12;
                else
                    assert(is_maximum_precincts == false);
                    assert(length(PPx) == length(PPy));
                    outObj.Lcod = 13 + number_of_decomposition_levels;
                end
                
                % Scod
                outObj.Scod = 0;
                if is_maximum_precincts == false
                    outObj.Scod = outObj.Scod + 1;
                end
                if use_SOP == true
                    outObj.Scod = outObj.Scod + 2;
                end
                if use_EPH == true
                    outObj.Scod = outObj.Scod + 4;
                end
                 
                % SGcod parameters
                outObj.SGcod = 0;
                outObj.SGcod = outObj.SGcod  + progression_order*2^24;
                outObj.SGcod = outObj.SGcod  + number_of_layers*2^8;
                outObj.SGcod = outObj.SGcod  + multiple_component_transform;
                
                % SPcod parameters
                outObj.SPcod(1) = number_of_decomposition_levels;
                if outObj.Lcod ~= 12
                    assert(outObj.Lcod == 13 + number_of_decomposition_levels, 'Lcod is incorrect.');
                end
                
                assert(codeblock_width_exponent >= 0 && codeblock_width_exponent <= 8);
                assert(codeblock_height_exponent >= 0 && codeblock_height_exponent <= 8);
                assert(codeblock_width_exponent + codeblock_height_exponent <= 10);
                outObj.SPcod(2) = codeblock_width_exponent;
                outObj.SPcod(3) = codeblock_height_exponent;
                
                
                outObj.SPcod(4) = codeblock_style;
                
                outObj.SPcod(5) = transformation;
                
                M_OFFSET = 1;
                if is_maximum_precincts == false
                    for i=0:number_of_decomposition_levels
                        if length(PPx) >= (i+M_OFFSET)
                            lastPPx = PPx(i+M_OFFSET);
                        end
                        if length(PPx) >= (i+M_OFFSET)
                            lastPPy = PPy(i+M_OFFSET);
                        end
                        outObj.SPcod(6+number_of_decomposition_levels-i) = lastPPx + 16*lastPPy;
                    end
                end
                
            end
        end
        function out = is_maximum_precincts(inObj)
            if bitand(inObj.Scod, 1) == 0
                out = true;
            else
                out = false;
            end
        end
        function out = is_use_SOP(inObj)
            if bitand(inObj.Scod, 2) == 2
                out = true;
            else
                out = false;
            end
        end
        function out = is_use_EPH(inObj)
            if bitand(inObj.Scod, 4) == 4
                out = true;
            else
                out = false;
            end
        end
        function out = get_progression_order(inObj)
            out = uint8(bitshift(inObj.SGcod, -24));
        end
        function out = get_number_of_layers(inObj)
            out = uint16(bitand(bitshift(inObj.SGcod, -8), 2^16-1));
        end
        function out = get_multiple_component_transform(inObj)
            out = uint8(bitand(inObj.SGcod, 2^8-1));
        end
        function out = get_number_of_decomposition_levels(inObj)
            out = inObj.SPcod(1);
        end
        function out = get_codeblock_size_in_exponent(inObj)
            height = inObj.SPcod(3) + 2;
            width = inObj.SPcod(2) + 2;
            assert(width >= 2 && width <= 10);
            assert(height >= 2 && height <= 10);
            assert(width + height <= 12);
            out = [width, height];
        end
        function out = is_selective_arithmetic_coding_bypass(inObj)
            if bitand(inObj.SPcod(4), 2^0) == 2^0
                out = true;
            else
                out = false;
            end
        end
        function out = is_reset_context_probabilities(inObj)
            if bitand(inObj.SPcod(4), 2^1) == 2^1
                out = true;
            else
                out = false;
            end
        end
        function out = is_termination_on_each_coding_pass(inObj)
            if bitand(inObj.SPcod(4), 2^2) == 2^2
                out = true;
            else
                out = false;
            end
        end
        function out = is_vertically_causal_context(inObj)
            if bitand(inObj.SPcod(4), 2^3) == 2^3
                out = true;
            else
                out = false;
            end
        end
        function out = is_predictable_termination(inObj)
            if bitand(inObj.SPcod(4), 2^4) == 2^4
                out = true;
            else
                out = false;
            end
        end
        function out = is_segmentation_symbols(inObj)
            if bitand(inObj.SPcod(4), 2^5) == 2^5
                out = true;
            else
                out = false;
            end
        end
        function out = get_codeblock_style(inObj)
            out = inObj.SPcod(4);
        end
        function out = get_transformation(inObj)
            out = inObj.SPcod(5);
        end
        function out = get_precinct_size_in_exponent(inObj)
            x_0F = uint8(15);
            x_F0 = uint8(240);
            M_OFFSET = 1;
            NL = get_number_of_decomposition_levels(inObj);
            out = zeros(NL + 1, 2);
            for i = 0:NL
                if is_maximum_precincts(inObj) == false
                    out(i+M_OFFSET,1) = bitand(inObj.SPcod(6+i), x_0F); % PPx
                    out(i+M_OFFSET,2) = bitshift(bitand(inObj.SPcod(6+i), x_F0), -4); % PPy
                else
                    out(i+M_OFFSET,1) = 15;% maximum_precincts
                    out(i+M_OFFSET,2) = 15;% maximum_precincts
                end
            end
        end
        function read_COD(inObj, hDsrc)
            assert(isa(hDsrc,'jp2_data_source'));
            assert(isa(inObj,'COD_marker'), 'input for read_COD() shall be COD_marker class.');
            % Lcod
            inObj.Lcod = get_word(hDsrc);
            % Scod
            inObj.Scod = get_byte(hDsrc);
            % SGcod parameters
            inObj.SGcod = get_dword(hDsrc);
            % SPcod parameters
            NL = get_byte(hDsrc);
            if is_maximum_precincts(inObj) == false
                inObj.SPcod = zeros(1,5 + 1+ NL);
            else
                inObj.SPcod = zeros(1,5);
            end
            
            inObj.SPcod(1) = NL;
            if inObj.Lcod ~= 12
                assert(inObj.Lcod == 13 + get_number_of_decomposition_levels(inObj), 'Lcod is incorrect.');
            end
            inObj.SPcod(2) = get_byte(hDsrc);
            inObj.SPcod(3) = get_byte(hDsrc);
            inObj.SPcod(4) = get_byte(hDsrc);
            inObj.SPcod(5) = get_byte(hDsrc);
            if is_maximum_precincts(inObj) == false
                for i=0:get_number_of_decomposition_levels(inObj)
                    inObj.SPcod(6+i) = get_byte(hDsrc);
                end
            end
            inObj.is_read = true;
        end
        function write_COD(inObj, m, hDdst)
            assert(isa(hDdst,'jp2_data_destination'));
            assert(isa(inObj,'COD_marker'), 'input for wirte_COD() shall be COD_marker class.');
            put_word(hDdst, m.COD);
            put_word(hDdst, inObj.Lcod);
            put_byte(hDdst, inObj.Scod);
            put_dword(hDdst, inObj.SGcod);
            n = length(inObj.SPcod);
            for i = 1:n
                put_byte(hDdst, inObj.SPcod(i));
            end
        end
    end
end