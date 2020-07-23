classdef state_MEL_enc < handle
    properties
        MEL_k uint8
        MEL_run uint8
        MEL_t uint8
    end
    methods
        function outObj = state_MEL_enc
            outObj.MEL_k = 0;
            outObj.MEL_run = 0;
            outObj.MEL_t = 1;
        end
    end
end
