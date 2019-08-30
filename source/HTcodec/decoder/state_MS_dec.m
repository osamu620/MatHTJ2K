classdef state_MS_dec < handle
    properties
        MS_pos uint32
        MS_bits uint8 
        MS_tmp  uint8
        MS_last uint8
    end
    methods
        function outObj = state_MS_dec
            outObj.MS_pos = 0;
            outObj.MS_bits = 0;
            outObj.MS_tmp = 0;
            outObj.MS_last = 0;
        end
    end
end