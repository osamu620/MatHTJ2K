classdef jp2_tile_component < handle
    properties
        idx_c uint8
        tcx0 int32
        tcy0 int32
        tcx1 int32
        tcy1 int32
        size_x uint32
        size_y uint32
        samples double
    end
    methods
        function outObj = jp2_tile_component(idx_c, tcx0, tcy0, tcx1, tcy1)
            outObj.idx_c = idx_c;
            outObj.tcx0 = tcx0;
            outObj.tcy0 = tcy0;
            outObj.tcx1 = tcx1;
            outObj.tcy1 = tcy1;
            outObj.size_x = tcx1 - tcx0;
            outObj.size_y = tcy1 - tcy0;
            outObj.samples = zeros(tcy1 - tcy0, tcx1 - tcx0, 'double');
        end
    end
end