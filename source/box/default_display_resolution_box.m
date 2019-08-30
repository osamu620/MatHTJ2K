classdef default_display_resolution_box < jp2_box_base
    properties
        VRdN uint16
        VRdD uint16
        HRdN uint16
        HRdD uint16
        VRdE uint8
        HRdE uint8
    end
    methods
        function read_contents(inObj)
            inObj.VRdN = get_word(inObj.DBox);
            inObj.VRdD = get_word(inObj.DBox);
            inObj.HRdN = get_word(inObj.DBox);
            inObj.HRdD = get_word(inObj.DBox);
            inObj.VRdE = get_byte(inObj.DBox);
            inObj.HRdE = get_byte(inObj.DBox);
            inObj.is_read = true;
        end
    end
end