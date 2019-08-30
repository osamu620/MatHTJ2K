classdef channel_definition_box < jp2_box_base
    properties
        N uint16
        Cn_i uint16
        Typ_i uint16
        Asoc_i uint16
    end
    methods
        function read_contents(inObj)
            inObj.N = get_word(inObj.DBox);
            for i = 1:inObj.N
                inObj.Cn_i(i) = get_word(inObj.DBox);
                inObj.Typ_i(i) = get_word(inObj.DBox);
                inObj.Asoc_i(i) = get_word(inObj.DBox);
            end
            inObj.is_read = true;
        end
    end
end