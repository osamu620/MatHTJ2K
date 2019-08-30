classdef state_VLC_enc < handle
    properties
        VLC_bits uint8
        VLC_tmp uint8
        VLC_pos uint32
        VLC_last uint8
    end
    methods
        function outObj = state_VLC_enc
            outObj.VLC_bits = 4;
            outObj.VLC_tmp = 15;
            outObj.VLC_pos = 1;
            outObj.VLC_last = 255;
        end
    end
end