classdef component_mapping_box < jp2_box_base
    properties
        CMP_i uint16
        MTYP_i uint8
        PCOL_i uint8
    end
    methods
        function read_contents(inObj)
            num_bytes = 8; %LBox + TBox
            i = 1;
            while num_bytes < inObj.LBox
                inObj.CMP_i(i) = get_word(inObj.DBox);
                inObj.MTYP_i(i) = get_byte(inObj.DBox);
                inObj.PCOL_i(i) = get_byte(inObj.DBox);
                num_bytes = num_bytes + 4;
                i = i +1;
            end
            inObj.is_read = true;
        end
    end
end