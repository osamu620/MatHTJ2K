classdef xml_box < jp2_box_base
    properties
        DATA uint8
    end
    methods
        function read_contents(inObj)
            inObj.DATA = get_N_byte(inObj.DBox, inObj.LBox -8);
            inObj.is_read = true;
        end
    end
end
