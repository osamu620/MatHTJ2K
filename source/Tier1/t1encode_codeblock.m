function elapsedTime = t1encode_codeblock(use_MEX, hPband, hCodeblock, idx_x, idx_y)

M_OFFSET = 1;

%% set values for a codeblock struct
hCodeblock.idx_x = idx_x;
hCodeblock.idx_y = idx_y;
hCodeblock.quantized_coeffs = hPband.quantized_coeffs( ...
    hCodeblock.pos_y + M_OFFSET:hCodeblock.pos_y + int32(hCodeblock.size_y), ...
    hCodeblock.pos_x + M_OFFSET:hCodeblock.pos_x + int32(hCodeblock.size_x));
hCodeblock.is_reversible = hPband.is_reversible;

if bitand(bitshift(hCodeblock.Cmodes, -6), 1) ~= 0
    p = int32(0); % p = 0 means no HT MagRef segment will be generated.
    CB_CAUSAL = bitshift(bitand(hCodeblock.Cmodes, 8), -3);
    tic;
    if nnz(hCodeblock.quantized_coeffs) == 0
        % if no coefficient is significant, nothing to do here.
        hCodeblock.compressed_data = [];
        hCodeblock.pass_length = 0;
    else

        %% HT Cleanup encoding
        if use_MEX == true
            [hCodeblock.compressed_data, hCodeblock.num_passes, hCodeblock.pass_length] = ...
                HT_block_encode_mex(hCodeblock.quantized_coeffs, p, CB_CAUSAL);
        else
            [hCodeblock.compressed_data, hCodeblock.num_passes, hCodeblock.pass_length] = ...
                HT_block_encode(hCodeblock.quantized_coeffs, p, CB_CAUSAL); % non-MEX
        end
    end
    elapsedTime = toc;

    hCodeblock.length = sum(hCodeblock.pass_length);

    if hCodeblock.length == 0
        hCodeblock.num_passes = 0;
    end

    hCodeblock.num_ZBP = hPband.M_b - 1 - uint8(p);
else

    %% J2K Part 1 block encoding
    % find missing MSB (number of zero bit planes:num_ZBP)
    v_tmp = int32(0);
    magnitude_array = abs(hCodeblock.quantized_coeffs);
    for i = 1:hCodeblock.size_y
        for j = 1:hCodeblock.size_x
            v_tmp = bitor(magnitude_array(i, j), v_tmp);
        end
    end

    % K is the actual number of magnitude bits
    K = int32(hCodeblock.M_b); % use K_b_max if there are ROI adjustments
    while K > 0 && 2^(K - 1) > v_tmp
        K = K - 1;
    end

    % set codeblock attributes
    hCodeblock.num_ZBP = int8(hCodeblock.M_b) - int8(K);
    hCodeblock.num_passes = 3 * K - 2;
    hCodeblock.pass_length = zeros(1, hCodeblock.num_passes);
    hCodeblock.distortion_changes = zeros(1, hCodeblock.num_passes);
    hCodeblock.truncation_points = zeros(1, hCodeblock.num_passes);
    hCodeblock.pass_idx = 0;
    hCodeblock.mq_C = zeros(1, hCodeblock.num_passes);
    hCodeblock.mq_A = zeros(1, hCodeblock.num_passes);
    hCodeblock.mq_t = zeros(1, hCodeblock.num_passes);
    hCodeblock.mq_T = zeros(1, hCodeblock.num_passes);
    hCodeblock.mq_L = zeros(1, hCodeblock.num_passes);

    % for mex, use *_mex function
    vCodeblock = v_codeblock_body(hCodeblock);
    tic;
    if use_MEX == true
        vCodeblock = j2k_block_encoder_v_mex(vCodeblock, K, hPband.msb_mse);
    else
        vCodeblock = j2k_block_encoder_v(vCodeblock, K, hPband.msb_mse); % non MEX
    end
    elapsedTime = toc;
    hCodeblock.copy_from_vCodeblock(vCodeblock);

    % for mex
    if sum(hCodeblock.pass_length) == 0
        hCodeblock.compressed_data = [];
    end

    hPband.Cblks((idx_x - 1) + (idx_y - 1) * hPband.numCblksX + M_OFFSET) = hCodeblock;
end
