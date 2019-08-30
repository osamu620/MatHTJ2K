classdef uuid_box < jp2_box_base
    properties
        UUID double
        DATA uint8
    end
    methods
        function read_contents(inObj)
            inObj.UUID = get_dword(inObj.DBox);
            for i = 1:3
                inObj.UUID = inObj.UUID*2^32 + get_dword(inObj.DBox);
            end
            if inObj.LBox > 24
                inObj.DATA = get_N_byte(inObj.DBox, inObj.LBox -(8+16));
            end
            inObj.is_read = true;
        end
    end
end
