classdef state_SP_enc < handle
    properties
        SP_pos uint32
        SP_bits uint8
        SP_max uint8
        SP_tmp uint8
        SP_buf uint8
    end
    methods
        function outObj = state_SP_enc
            outObj.SP_pos = 0;
            outObj.SP_bits = 0;
            outObj.SP_max = 8;
            outObj.SP_tmp = 0;
            outObj.SP_buf = zeros(1, 2048, 'uint8');
        end
    end
end