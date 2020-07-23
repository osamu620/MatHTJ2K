classdef subband_info < handle
    properties
        idx uint8
        pos_x int32
        pos_y int32
        size_x uint32
        size_y uint32
        dwt_coeffs = []
        epsilon_b uint8
        mantissa_b uint16
        Delta_b double
        normalized_delta double
        M_b uint8
        N_b uint8
        W_b double
        is_reversible logical
        idx_c uint16
    end
    methods
        function outObj = subband_info(id, px, py, sx, sy, data, eb, nGb)
            if nargin == 0
                outObj.idx = 0;
            elseif nargin == 1
                outObj.idx = id;
            else
                outObj.idx = id;
                outObj.pos_x = px;
                outObj.pos_y = py;
                outObj.size_x = sx;
                outObj.size_y = sy;
                outObj.dwt_coeffs = data;
                outObj.epsilon_b = eb;
                outObj.M_b = nGb + eb - 1;
            end
        end
        function outObj = add_to_subband_info(inObj, b, px, py, sx, sy, data, eb, nGb)
            if nargin < 3
                tmpObj = subband_info(b);
            else
                tmpObj = subband_info(b, px, py, sx, sy, data, eb, nGb);
            end
            outObj = [inObj, tmpObj];
        end
    end
end