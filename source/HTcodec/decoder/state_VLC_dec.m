classdef state_VLC_dec < handle
    properties
        VLC_pos uint32
        VLC_last uint8
        VLC_tmp uint8
        VLC_bits uint8
    end
    methods
        function outObj = state_VLC_dec(p, l, t, b)
            outObj.VLC_pos = p;
            outObj.VLC_last = l;
            outObj.VLC_tmp = t;
            outObj.VLC_bits = b;
        end
    end
end