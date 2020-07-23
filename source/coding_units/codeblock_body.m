classdef codeblock_body < handle
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
        component_idx uint8 %%%%% will be deleted!!!
        Cmodes uint16
        fast_skip_passes uint8
        layer_start uint32 % 1, :65535
        layer_passes uint32 % 1, :65535
        compressed_data uint8 %1, :16384
        quantized_coeffs int32 %:128x:128
        N_b int32 %:128x:128
        dwt_coeffs double %:128x:128
        M_b uint8
        W_b double
        Delta_b double
        normalized_delta double
        pass_length int32 %:165
        pass_idx int32 %:165
        distortion_changes double %:165
        truncation_points uint8 %:165
        %tp_lengths (1, :) int32%:165
        RD_slope uint16 %:165
        is_reversible logical
        mq_C uint32 %:165
        mq_A uint16 %:165
        mq_t int16 %:165
        mq_T uint8 %:165
        mq_L int32 %:165
    end
    methods
        function outObj = codeblock_body(inObj, c, ix, iy, pos_x, pos_y, size_x, size_y, b_idx, p_idx, r_idx, Cmodes, num_layers, M_b, W_b, Delta_b, normalized_delta)
            if nargin == 0

                %%
                outObj.length = uint32(0);
                outObj.idx_x = uint32(0); %
                outObj.idx_y = uint32(0); %
                outObj.pos_x = int32(0); %
                outObj.pos_y = int32(0); %
                outObj.size_x = uint16(0); %
                outObj.size_y = uint16(0); %
                outObj.idx_c = uint16(0); %
                outObj.num_passes = uint8(0);
                outObj.LBlock = int32(3);
                outObj.num_ZBP = uint8(0);
                outObj.already_included = false;
                outObj.band_idx = uint8(0); %
                outObj.precinct_idx = uint32(0); %
                outObj.resolution_idx = uint8(0); %
                outObj.component_idx = uint8(0); %
                outObj.Cmodes = uint16(0); %
                outObj.fast_skip_passes = uint8(0);
                outObj.layer_start = uint32(0);
                outObj.layer_passes = uint32(0);
                outObj.compressed_data = uint8(0);
                outObj.pass_length = int32(0);
                outObj.pass_idx = int32(0);
                outObj.distortion_changes = 0;
                outObj.truncation_points = uint8(0);
                %outObj.tp_lengths = 0;
                outObj.RD_slope = uint16(0);
                outObj.is_reversible = false;
                outObj.mq_C = uint32(0);
                outObj.mq_A = uint16(0);
                outObj.mq_t = int16(0);
                outObj.mq_T = uint8(0);
                outObj.mq_L = int32(0);
            elseif nargin == 1

                %%
                assert(inObj.size_x <= 128 && inObj.size_y <= 128 && inObj.size_x * inObj.size_y <= 4096);
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
            else
                outObj.length = uint32(0);
                outObj.idx_x = ix; %
                outObj.idx_y = iy; %
                outObj.pos_x = pos_x; %
                outObj.pos_y = pos_y; %
                outObj.size_x = size_x; %
                outObj.size_y = size_y; %
                outObj.idx_c = c; %
                outObj.num_passes = uint8(0);
                outObj.LBlock = int32(3);
                outObj.num_ZBP = uint8(0);
                outObj.already_included = false;
                outObj.band_idx = b_idx; %
                outObj.precinct_idx = p_idx; %
                outObj.resolution_idx = r_idx; %
                outObj.component_idx = uint8(c); %
                outObj.Cmodes = Cmodes; %
                outObj.fast_skip_passes = uint8(0);
                outObj.layer_start = zeros(1, num_layers, 'uint32');
                outObj.layer_passes = zeros(1, num_layers, 'uint32');
                outObj.compressed_data = uint8(0);
                outObj.M_b = M_b;
                outObj.W_b = W_b;
                outObj.Delta_b = Delta_b;
                outObj.normalized_delta = normalized_delta;
                outObj.pass_length = int32(0);
                outObj.pass_idx = int32(0);
                outObj.distortion_changes = 0;
                outObj.truncation_points = uint8(0);
                outObj.RD_slope = uint16(0);
                outObj.is_reversible = false;
                outObj.mq_C = uint32(0);
                outObj.mq_A = uint16(0);
                outObj.mq_t = int16(0);
                outObj.mq_T = uint8(0);
                outObj.mq_L = int32(0);
            end
        end
        function outObj = add_codeblock_body(inObj)
            tmpObj = codeblock_body;
            outObj = [inObj, tmpObj];
        end
        function set_attributes(inObj, c, r, b, p, x, y)
            inObj.idx_x = x;
            inObj.idx_y = y;
            inObj.band_idx = b;
            inObj.precinct_idx = p;
            inObj.resolution_idx = r;
            inObj.component_idx = c;
        end
        function copy_from_vCodeblock(inObj, vCodeblock)
            assert(isa(vCodeblock, 'v_codeblock_body'));
            inObj.length = vCodeblock.length;
            inObj.idx_x = vCodeblock.idx_x;
            inObj.idx_y = vCodeblock.idx_y;
            inObj.pos_x = vCodeblock.pos_x;
            inObj.pos_y = vCodeblock.pos_y;
            inObj.size_x = vCodeblock.size_x;
            inObj.size_y = vCodeblock.size_y;
            inObj.idx_c = vCodeblock.idx_c;
            inObj.num_passes = vCodeblock.num_passes;
            inObj.LBlock = vCodeblock.LBlock;
            inObj.num_ZBP = vCodeblock.num_ZBP;
            inObj.already_included = vCodeblock.already_included;
            inObj.band_idx = vCodeblock.band_idx;
            inObj.precinct_idx = vCodeblock.precinct_idx;
            inObj.resolution_idx = vCodeblock.resolution_idx;
            inObj.component_idx = vCodeblock.component_idx;
            inObj.Cmodes = vCodeblock.Cmodes;
            inObj.fast_skip_passes = vCodeblock.fast_skip_passes;
            inObj.layer_start = vCodeblock.layer_start;
            inObj.layer_passes = vCodeblock.layer_passes;
            inObj.compressed_data = vCodeblock.compressed_data;
            inObj.quantized_coeffs = vCodeblock.quantized_coeffs;
            inObj.N_b = vCodeblock.N_b;
            inObj.dwt_coeffs = vCodeblock.dwt_coeffs;
            inObj.M_b = vCodeblock.M_b;
            inObj.W_b = vCodeblock.W_b;
            inObj.Delta_b = vCodeblock.Delta_b;
            inObj.normalized_delta = vCodeblock.normalized_delta;
            inObj.pass_length = vCodeblock.pass_length;
            inObj.pass_idx = vCodeblock.pass_idx;
            inObj.distortion_changes = vCodeblock.distortion_changes;
            inObj.truncation_points = vCodeblock.truncation_points;
            inObj.RD_slope = vCodeblock.RD_slope;
            inObj.is_reversible = vCodeblock.is_reversible;
            inObj.mq_C = vCodeblock.mq_C;
            inObj.mq_A = vCodeblock.mq_A;
            inObj.mq_t = vCodeblock.mq_t;
            inObj.mq_T = vCodeblock.mq_T;
            inObj.mq_L = vCodeblock.mq_L;
        end
    end
end