classdef v_codeblock_body
    properties
        length uint32
        idx_x uint32
        idx_y uint32
        pos_x int32
        pos_y int32
        size_x uint16
        size_y uint16
        idx_c uint16
        num_passes uint8
        LBlock int32
        num_ZBP uint8
        already_included logical
        band_idx uint8
        precinct_idx uint32
        resolution_idx uint8
        component_idx uint8 %%%%%% will be deleted!!!
        Cmodes uint16
        fast_skip_passes uint8
        layer_start uint32
        layer_passes uint32
        compressed_data uint8
        quantized_coeffs int32
        N_b int32
        dwt_coeffs double
        M_b uint8
        W_b double
        Delta_b double
        normalized_delta double
        pass_length int32
        pass_idx int32
        distortion_changes double
        truncation_points uint8
        RD_slope uint16
        is_reversible logical
        mq_C uint32
        mq_A uint16
        mq_t int16
        mq_T uint8
        mq_L int32
    end
    methods
        function outObj = v_codeblock_body(inObj)
            outObj.length = inObj.length;
            outObj.idx_x = inObj.idx_x;
            outObj.idx_y = inObj.idx_y;
            outObj.pos_x = inObj.pos_x;
            outObj.pos_y = inObj.pos_y;
            outObj.size_x = inObj.size_x;
            outObj.size_y = inObj.size_y;
            outObj.idx_c = inObj.idx_c;
            outObj.num_passes = inObj.num_passes;
            outObj.LBlock = inObj.LBlock;
            outObj.num_ZBP = inObj.num_ZBP;
            outObj.already_included = inObj.already_included;
            outObj.band_idx = inObj.band_idx;
            outObj.precinct_idx = inObj.precinct_idx;
            outObj.resolution_idx = inObj.resolution_idx;
            outObj.component_idx = inObj.component_idx;
            outObj.Cmodes = inObj.Cmodes;
            outObj.fast_skip_passes = inObj.fast_skip_passes;
            outObj.layer_start = inObj.layer_start;
            outObj.layer_passes = inObj.layer_passes;
            outObj.compressed_data = inObj.compressed_data;
            outObj.quantized_coeffs = inObj.quantized_coeffs;
            outObj.N_b = inObj.N_b;
            outObj.dwt_coeffs = inObj.dwt_coeffs;
            outObj.M_b = inObj.M_b;
            outObj.W_b = inObj.W_b;
            outObj.Delta_b = inObj.Delta_b;
            outObj.normalized_delta = inObj.normalized_delta;
            outObj.pass_length = inObj.pass_length;
            outObj.pass_idx = inObj.pass_idx;
            outObj.distortion_changes = inObj.distortion_changes;
            outObj.truncation_points = inObj.truncation_points;
            outObj.RD_slope = inObj.RD_slope;
            outObj.is_reversible = inObj.is_reversible;
            outObj.mq_C = inObj.mq_C;
            outObj.mq_A = inObj.mq_A;
            outObj.mq_t = inObj.mq_t;
            outObj.mq_T = inObj.mq_T;
            outObj.mq_L = inObj.mq_L;
        end
    end
end