classdef state_MR_enc < handle
    properties
        MR_pos uint32
        MR_bits uint8 
        MR_tmp uint8
        MR_last uint8
        MR_buf uint8
    end
    methods
        function outObj = state_MR_enc
            outObj.MR_pos = 0;
            outObj.MR_bits = 0;
            outObj.MR_tmp = 0;
            outObj.MR_last = 255;
            outObj.MR_buf = zeros(1, 2048, 'uint8');
        end
    end
end