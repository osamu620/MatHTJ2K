classdef state_MEL_unPacker < handle
    properties
        MEL_pos uint32
        MEL_bits int8
        MEL_tmp uint8
    end
    methods
        function outObj = state_MEL_unPacker
            outObj.MEL_pos = 0;
            outObj.MEL_bits = 0;
            outObj.MEL_tmp = 0;
        end
    end
end