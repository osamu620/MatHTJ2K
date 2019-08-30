classdef jp2_packet < handle
    properties
        idx int32
        idx_c uint16
        idx_r uint8
        idx_l uint16
        px uint32
        py uint32
        header (1,:) uint8
        body (1,:) uint8
        is_emitted logical
    end
    methods
        function outObj = jp2_packet(c, r, l, px ,py)
            outObj.idx_c = c;
            outObj.idx_r = r;
            outObj.idx_l = l;
            outObj.px = px;
            outObj.py = py;
            outObj.is_emitted = false;
        end
    end
end