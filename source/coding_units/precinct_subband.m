classdef precinct_subband < handle
    properties
        precinct_idx_x uint32
        precinct_idx_y uint32
        band_idx uint8
        epsilon_b uint8
        mantissa_b uint16
        Delta_b double
        normalized_delta double
        W_b double
        msb_mse double
        M_b uint8
        N_b uint8
        pos_x int32
        pos_y int32
        size_x uint32
        size_y uint32
        inclusionInfo tagTree
        ZBPInfo tagTree
        numCblksX uint32
        numCblksY uint32
        CblkSizX uint16
        CblkSizY uint16
        Cblks codeblock_body
        quantized_coeffs
        dwt_coeffs
        is_reversible logical
        is_zero_length logical
        idx_c uint16
    end
    methods
        function outObj = precinct_subband(px, py, b, x, y, w, h, eb, mb, ncx, ncy, cw, ch)
            if nargin == 0
                outObj.precinct_idx_x = uint32(0);
                outObj.precinct_idx_y = uint32(0);
                outObj.band_idx = uint8(0);
                outObj.epsilon_b = uint8(0);
                outObj.mantissa_b = uint16(0);
                outObj.M_b = uint8(0);
                outObj.pos_x = int32(0);
                outObj.pos_y = int32(0);
                outObj.size_x = uint32(0);
                outObj.size_y = uint32(0);
                outObj.numCblksX = uint32(0);
                outObj.numCblksY = uint32(0);
                outObj.CblkSizX = uint16(0);
                outObj.CblkSizY = uint16(0);
                outObj.is_zero_length = true;
            elseif nargin == 7
                outObj.precinct_idx_x = px;
                outObj.precinct_idx_y = py;
                outObj.band_idx = b;
                outObj.epsilon_b = uint8(0);
                outObj.M_b = uint8(0);
                outObj.pos_x = x;
                outObj.pos_y = y;
                outObj.size_x = w;
                outObj.size_y = h;
                outObj.numCblksX = uint32(0);
                outObj.numCblksY = uint32(0);
                outObj.CblkSizX = uint16(0);
                outObj.CblkSizY = uint16(0);
                outObj.is_zero_length = true;
            else
                outObj.precinct_idx_x = px;
                outObj.precinct_idx_y = py;
                outObj.band_idx = b;
                outObj.epsilon_b = eb;
                outObj.M_b = mb;
                outObj.pos_x = x;
                outObj.pos_y = y;
                outObj.size_x = w;
                outObj.size_y = h;
                outObj.numCblksX = ncx;
                outObj.numCblksY = ncy;
                outObj.CblkSizX = cw;
                outObj.CblkSizY = ch;
                outObj.is_zero_length = true;
            end
        end
        function add_codeblockinfo_to_pband(inObj, cblk)
            inObj.Cblks = [inObj.Cblks, cblk];
        end
    end
end