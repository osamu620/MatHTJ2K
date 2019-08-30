function j2k_block_encoder(hCodeblock)
%function out_vCodeblock = j2k_block_encoder(vCodeblock)
%hCodeblock = vCodeblock.return_to_hCodeblock();

M_OFFSET = 1;

states_EBCOT = ebcot_states(hCodeblock.size_x, hCodeblock.size_y);
values_EBCOT = ebcot_elements(hCodeblock.size_x, hCodeblock.size_y);
s = sign(hCodeblock.quantized_coeffs);
s(s == 0) = 1;
values_EBCOT.set_sign_array(s);
values_EBCOT.magnitude_array = abs(hCodeblock.quantized_coeffs);

v_tmp = int32(0);
for i = 1:hCodeblock.size_y
    for j = 1:hCodeblock.size_x
        v_tmp = bitor(values_EBCOT.magnitude_array(i, j), v_tmp);
    end
end

K = int32(hCodeblock.M_b);% use K_b_max if there are ROI adjustments

while K > 0 && 2^(K-1) > v_tmp
    K = K - 1;
end
mq_reg_enc = mq_enc;

hCodeblock.num_ZBP = int8(hCodeblock.M_b) - int8(K);
hCodeblock.num_passes = 3*K - 2;
hCodeblock.pass_length = zeros(1, hCodeblock.num_passes);
hCodeblock.distortion_changes =  zeros(1, hCodeblock.num_passes);
hCodeblock.truncation_points =  zeros(1, hCodeblock.num_passes);
hCodeblock.pass_idx = 0;
hCodeblock.mq_C = zeros(1, hCodeblock.num_passes);
hCodeblock.mq_A = zeros(1, hCodeblock.num_passes);
hCodeblock.mq_t = zeros(1, hCodeblock.num_passes);
hCodeblock.mq_T = zeros(1, hCodeblock.num_passes);
hCodeblock.mq_L = zeros(1, hCodeblock.num_passes);

if hCodeblock.num_passes > 0
    %% Encoding passes
    %hCodeblock.pass_length = zeros(1, hCodeblock.num_passes, 'int32');
    for p = int32(K-1):-1:0
        values_EBCOT.bitplane = bitand(values_EBCOT.magnitude_array, 2^int32(p)) / 2^int32(p);
        if p < K - 1
            % significance propagation pass
            encode_j2k_sigprop_pass(hCodeblock, p, states_EBCOT, values_EBCOT, mq_reg_enc);
            % magnitude refinement pass
            encode_j2k_magref_pass(hCodeblock, p, states_EBCOT, values_EBCOT, mq_reg_enc);
        end
        % cleanup pass
        encode_j2k_cleanup_pass(hCodeblock, p, states_EBCOT, values_EBCOT, mq_reg_enc);
    end 
    %% temporal termination
    L_start = mq_reg_enc.L;
    mq_reg_enc.mq_encoder_end();
    % The last coding pass must include a length with MQ-termination
    L_end = mq_reg_enc.L;
    hCodeblock.pass_length(hCodeblock.pass_idx) = hCodeblock.pass_length(hCodeblock.pass_idx) + L_end - L_start;
    %% output
    hCodeblock.compressed_data = mq_reg_enc.byte_stream(1:mq_reg_enc.L);
    hCodeblock.length = length(hCodeblock.compressed_data);
    hCodeblock.codeword_segments = mq_reg_enc.L;
    %% distortion estimation
    find_feasible_truncation_points(hCodeblock);
else
    mq_reg_enc.te
    hCodeblock.compressed_data = uint8(0);%dummy
    hCodeblock.length = 0;
    hCodeblock.codeword_segments = 0;
end
%out_vCodeblock = v_codeblock_body(hCodeblock);
