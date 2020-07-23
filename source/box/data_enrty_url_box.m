classdef data_enrty_url_box < jp2_box_base
    properties
        VERS uint8
        FLAG uint32
        LOC uint8
    end
    methods
        function read_contents(inObj)
            inObj.VERS = get_byte(inObj.DBox);
            inObj.FLAG = get_dword(inObj.DBox);
            assert(inObj.VERS == 0 && inObj.FLAG == 0);
            inObj.LOC = get_N_byte(inObj.DBox, inObj.LBox - (4 + 4 + 1 + 4));
            inObj.is_read = true;
        end
    end
end
