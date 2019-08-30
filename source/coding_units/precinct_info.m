classdef precinct_info < handle
    properties
        idx_x uint8
        idx_y uint8
        pos_x int32
        pos_y int32
        size_x uint32
        size_y uint32
        precinct_subbands precinct_subband
    end
    methods
        function outObj = precinct_info(x, y, Etcrp_x, Etcrp_y, Ftcrp_x, Ftcrp_y, r, hBandInfo)
            outObj.idx_x = uint8(x);
            outObj.idx_y = uint8(y);
            outObj.pos_x = Etcrp_x;
            outObj.pos_y = Etcrp_y;
            if r == 0
                sr = uint32(0);
            else
                sr = uint32(1);
            end
            size_x = uint32(Ftcrp_x - Etcrp_x);
            size_y = uint32(Ftcrp_y - Etcrp_y);
            if log2(double(size_x)) < sr
                size_x = sr;
            end
            if log2(double(size_y)) < sr
                size_y = sr;
            end
            outObj.size_x = size_x;
            outObj.size_y = size_y;
            b_x_tab = int32([0 1 0 1]);
            b_y_tab = int32([0 0 1 1]);
            
            for b = 1:length(hBandInfo)
                b_x = b_x_tab(hBandInfo(b).idx + 1);
                b_y = b_y_tab(hBandInfo(b).idx + 1);

                Etcrpb_x = ceil_quotient_int(Etcrp_x - b_x, 2^sr, 'int32');
                Etcrpb_y = ceil_quotient_int(Etcrp_y - b_y, 2^sr, 'int32');
                Ftcrpb_x = ceil_quotient_int(Ftcrp_x - b_x, 2^sr, 'int32');
                Ftcrpb_y = ceil_quotient_int(Ftcrp_y - b_y, 2^sr, 'int32');
                
                outObj.precinct_subbands = [outObj.precinct_subbands precinct_subband(x, y, hBandInfo(b).idx, Etcrpb_x, Etcrpb_y, uint32(Ftcrpb_x - Etcrpb_x), uint32(Ftcrpb_y - Etcrpb_y))];
                outObj.precinct_subbands(b).dwt_coeffs = zeros(outObj.precinct_subbands(b).size_y, outObj.precinct_subbands(b).size_x);
                outObj.precinct_subbands(b).quantized_coeffs = zeros(outObj.precinct_subbands(b).size_y, outObj.precinct_subbands(b).size_x);
            end
        end
    end
end