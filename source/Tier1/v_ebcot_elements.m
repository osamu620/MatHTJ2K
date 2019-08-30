classdef v_ebcot_elements
    properties
        sign_array int32
        dummy_sign int32
        magnitude_array int32
        p_idx int32
        bitplane int32
        p int32
    end
    methods
        function outObj = v_ebcot_elements(inObj)
            outObj.sign_array = inObj.sign_array;
            outObj.dummy_sign = inObj.dummy_sign;
            outObj.magnitude_array = inObj.magnitude_array;
            outObj.p_idx = inObj.p_idx;
            outObj.bitplane = inObj.bitplane;
            outObj.p = inObj.p;
        end
    end
end