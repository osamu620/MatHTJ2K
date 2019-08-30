classdef resolution_info < handle
    properties
        idx uint8
        subbandInfo subband_info
        num_band uint8
        trx0 int32
        trx1 int32
        try0 int32
        try1 int32
        precinct_resolution precinct_info
        precinct_width uint32
        precinct_height uint32
        numprecinctwide uint32
        numprecincthigh uint32
        idx_c uint16
        is_empty logical
    end
    methods
        function outObj = add_to_resolution_info(inObj)
            tmpObj = resolution_info;
            outObj = [inObj tmpObj];
        end
        function add_subband_info_to_resolution_info(inObj, num_subband)
            inObj.num_band = num_subband;
            if num_subband == 1
                inObj.subbandInfo = add_to_subband_info(inObj.subbandInfo, 0);
            else
                for b = 1:num_subband
                    inObj.subbandInfo = add_to_subband_info(inObj.subbandInfo, b);
                end
            end
        end
        function add_precinct_subbands_to_resolution(inObj, pBand)
            inObj.precinct_subbands = [inObj.precinct_resolutionprecinct_subbands, pBand];
        end
    end
end