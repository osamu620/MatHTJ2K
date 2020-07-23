classdef state_MELPacker_enc < handle
    properties
        MEL_pos uint32
        MEL_rem uint8
        MEL_tmp uint8
    end
    methods
        function outObj = state_MELPacker_enc
            outObj.MEL_pos = 0;
            outObj.MEL_rem = 8;
            outObj.MEL_tmp = 0;
        end
    end
end