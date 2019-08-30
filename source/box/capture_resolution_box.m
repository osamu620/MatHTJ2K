classdef capture_resolution_box < jp2_box_base
    properties
        VRcN uint16
        VRcD uint16
        HRcN uint16
        HRcD uint16
        VRcE uint8
        HRcE uint8
    end
    methods
        function read_contents(inObj)
            inObj.VRcN = get_word(inObj.DBox);
            inObj.VRcD = get_word(inObj.DBox);
            inObj.HRcN = get_word(inObj.DBox);
            inObj.HRcD = get_word(inObj.DBox);
            inObj.VRcE = get_byte(inObj.DBox);
            inObj.HRcE = get_byte(inObj.DBox);
            inObj.is_read = true;
        end
    end
end