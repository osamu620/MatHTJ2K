classdef state_MEL_decoder < handle
    properties
        MEL_k uint8
        MEL_run uint8
        MEL_one uint8
        MEL_E uint8
    end
    methods
        function outObj = state_MEL_decoder
            outObj.MEL_k = 0;
            outObj.MEL_run = 0;
            outObj.MEL_one = 0;
            outObj.MEL_E = uint8(get_MEL_exponent_table);
        end
    end
end