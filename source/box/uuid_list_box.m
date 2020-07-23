classdef uuid_list_box < jp2_box_base
    properties
        NU uint16
        UUID_i double
    end
    methods
        function read_contents(inObj)
            inObj.NU = get_word(inObj.DBox);
            for i = 1:inObj.NU
                for j = 1:4
                    inObj.UUID_i(i) = inObj.UUID_i(i) * 2^32 + get_dword(inObj.DBox);
                end
            end
            inObj.is_read = true;
        end
    end
end
