classdef palette_box < jp2_box_base
    properties
        NE uint16
        NPC uint8
        B_i uint8
        C_ji uint16
    end
    methods
        function read_contents(inObj)
            inObj.NE = get_word(inObj.DBox);
            inObj.NPC = get_byte(inObj.DBox);
            for i = 1:inObj.NPC
                inObj.B_i(i) = get_byte(inObj.DBox);
            end
            for i = 1:inObj.NE
                for j = 1:inObj.NPC
                    if inObj.B_i(j) > 16
                        inObj.C_ji(i, j) = get_dword(inObj.DBox);
                    elseif inObj.B_i(j) > 8
                        inObj.C_ji(i, j) = get_word(inObj.DBox);
                    else
                        inObj.C_ji(i, j) = get_byte(inObj.DBox);
                    end
                end
            end
            inObj.is_read = true;
        end
    end
end