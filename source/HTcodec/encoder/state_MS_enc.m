classdef state_MS_enc < handle
    properties
        MS_pos uint32
        MS_bits uint8
        MS_max uint8
        MS_tmp uint8
    end
    methods
        function outObj = state_MS_enc
            outObj.MS_pos = 0;
            outObj.MS_bits = 0;
            outObj.MS_max = 8;
            outObj.MS_tmp = 0;
        end
    end
end