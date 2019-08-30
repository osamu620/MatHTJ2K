function out_vCodeblock = j2k_block_encoder_v(vCodeblock, K, msb_mse) %#codegen

M_OFFSET = 1;

hCodeblock = codeblock_body(vCodeblock);

% retrieve codeblock style from COD marker
CB_BYPASS  = bitand(hCodeblock.Cmodes , 1);
%CB_RESET   = bitshift(bitand(hCodeblock.Cmodes , 2), -1); % this flag is processed in each pass
CB_RESTART = bitshift(bitand(hCodeblock.Cmodes , 4), -2);
CB_CAUSAL  = bitshift(bitand(hCodeblock.Cmodes , 8), -3);
CB_ERTERM  = bitshift(bitand(hCodeblock.Cmodes ,16), -4);
%CB_SEGMARK = bitshift(bitand(hCodeblock.Cmodes ,32), -5); % this flag is processed in cleanup pass
%label_uni = 18; % uniform, for SEGMARK

states_EBCOT = ebcot_states(hCodeblock.size_x, hCodeblock.size_y);% hCodeblock.states_EBCOT;
values_EBCOT = ebcot_elements(hCodeblock.size_x, hCodeblock.size_y);% shCodeblock.values_EBCOT;
states_EBCOT.is_causal = CB_CAUSAL;

s = sign(hCodeblock.quantized_coeffs);
s(s == 0) = 1;
values_EBCOT.set_sign_array(s);
values_EBCOT.magnitude_array = abs(hCodeblock.quantized_coeffs);
% Loop-up table for context determination
sig_LUT = get_sig_LUT;

mq_reg_enc = mq_enc;
mq_reg_enc.set_tables();
mq_reg_enc.init_states_for_all_context();
mq_reg_enc.init_coder();
%mq_reg_enc.buf_next = -1;

DISTORTION_LUT_SCALE = 2^16;
pass_wmse_scale = msb_mse / DISTORTION_LUT_SCALE;
pass_wmse_scale = pass_wmse_scale / 2^16;
for i = hCodeblock.num_ZBP:-1:1
    pass_wmse_scale = pass_wmse_scale * 0.25;
end
dist = 0.0;
if hCodeblock.num_passes > 0
    %% Encoding passes
    for p = int32(K-1):-1:0
        values_EBCOT.bitplane = bitand(values_EBCOT.magnitude_array, 2^int32(p)) / 2^int32(p);
        is_bypass_segment = false;
        if p < K - 1
            if CB_BYPASS == true && p < K - 4
                is_bypass_segment = true;
                % significance propagation pass
                dist = encode_j2k_sigprop_pass_raw(sig_LUT, hCodeblock, p, states_EBCOT, values_EBCOT, mq_reg_enc);
                hCodeblock.distortion_changes(hCodeblock.pass_idx) = pass_wmse_scale * dist;
                % magnitude refinement pass
                dist = encode_j2k_magref_pass_raw(sig_LUT, hCodeblock, p, states_EBCOT, values_EBCOT, mq_reg_enc);
                hCodeblock.distortion_changes(hCodeblock.pass_idx) = pass_wmse_scale * dist;
            else
                % significance propagation pass
                dist = encode_j2k_sigprop_pass(sig_LUT, hCodeblock, p, states_EBCOT, values_EBCOT, mq_reg_enc);
                hCodeblock.distortion_changes(hCodeblock.pass_idx) = pass_wmse_scale * dist;
                % magnitude refinement pass
                dist = encode_j2k_magref_pass(sig_LUT, hCodeblock, p, states_EBCOT, values_EBCOT, mq_reg_enc);
                hCodeblock.distortion_changes(hCodeblock.pass_idx) = pass_wmse_scale * dist;
            end
        end
        
        % cleanup pass
        dist = encode_j2k_cleanup_pass(sig_LUT, hCodeblock, p, states_EBCOT, values_EBCOT, mq_reg_enc, is_bypass_segment);
        hCodeblock.distortion_changes(hCodeblock.pass_idx) = pass_wmse_scale * dist;
        % if the end of the initial sucessive AC segments, we need to terminate and to know the length of each coding pass. 
        if CB_BYPASS == true && CB_RESTART == false && p == K - 4 
            mq_reg_enc.terminate_segment(hCodeblock, hCodeblock.pass_idx);
            mq_reg_enc.buf_next = mq_reg_enc.buf_next + 1; % Plus 1 is because every first byte in an arithmetic codeword segment is skipped.
            mq_reg_enc.L = mq_reg_enc.buf_next;
        end

        % move to next bitplane..
        pass_wmse_scale = pass_wmse_scale * 0.25;
    end
    
    %% temporal termination
    if CB_RESTART == false && CB_BYPASS == false
        mq_reg_enc.terminate_segment(hCodeblock, hCodeblock.num_passes);
    end
    %% construct compressed byte buffer from terminated MQ or RAW segments
    buf = zeros(1, sum(hCodeblock.pass_length), 'uint8');
    buf = construct_compressed_data(buf, hCodeblock, mq_reg_enc);
    hCodeblock.compressed_data = buf;
    hCodeblock.length = length(hCodeblock.compressed_data);
    
    %% find convex hull
    find_feasible_truncation_points(hCodeblock);
else
    hCodeblock.compressed_data = uint8(0);%dummy
    hCodeblock.length = 0;
end
out_vCodeblock = v_codeblock_body(hCodeblock);
