function [q_b_bar, N_b] = HT_block_decode(vCodeblock, ROIshift)
M_OFFSET = 1;

if vCodeblock.num_passes > 3
    % number of placeholder passes;
    P_0 = max(diff([0, (find(~(vCodeblock.pass_length == 0))), numel(vCodeblock.pass_length) + 1]) - 1) / 3;
elseif vCodeblock.length == 0 && vCodeblock.num_passes ~= 0
    assert(vCodeblock.num_passes == 3);
    P_0 = 1;
else
    P_0 = 0;
end
S_skip = 0; % number of preceding HT Sets; currently multi HT is not supported.
QW = ceil_quotient_int(vCodeblock.size_x, 2, 'uint16');
QH = ceil_quotient_int(vCodeblock.size_y, 2, 'uint16');
empty_passes = P_0 * 3;
num_passes = vCodeblock.num_passes - empty_passes;
K_max_prime = ROIshift + int32(vCodeblock.M_b);
p = K_max_prime - int32(vCodeblock.num_ZBP) - int32(P_0) - 1;

if num_passes > 0
    all_segments = find(vCodeblock.pass_length);
    HT_Cleanup_segment = uint8(vCodeblock.compressed_data(1:vCodeblock.pass_length(all_segments(1))));
    if num_passes > 1 && length(all_segments) > 1
        HT_Refinement_segment = uint8(vCodeblock.compressed_data( ...
            vCodeblock.pass_length(all_segments(1)) + 1: ...
            vCodeblock.pass_length(all_segments(1)) + sum(vCodeblock.pass_length(all_segments(2:end)))));
    elseif num_passes > 1 && length(all_segments) == 1 %% is it correct?
        HT_Refinement_segment = uint8(0); %% is it correct?
    else
        HT_Refinement_segment = [];
    end

    %% HT cleanup pass decoding
    S_blk = int32(P_0 + vCodeblock.num_ZBP + S_skip);
    [mu_n, s_n, sigma_n] = HT_Cleanup_decode(uint8(HT_Cleanup_segment), QW, QH);

    % clip padded coefficients for quad-based scan
    mu_n = mu_n(1:vCodeblock.size_y, 1:vCodeblock.size_x);
    s_n = s_n(1:vCodeblock.size_y, 1:vCodeblock.size_x);
    sigma_n = sigma_n(1:vCodeblock.size_y, 1:vCodeblock.size_x);

    q_b_bar = int32(mu_n);

    z_n = zeros(size(mu_n), 'int32');
    r_n = zeros(size(mu_n), 'int32');

    %% HT SigProp pass decoding
    if num_passes > 1
        CB_CAUSAL = bitshift(bitand(vCodeblock.Cmodes, 8), -3);
        state_SP = state_SP_dec(HT_Refinement_segment);
        [s_n, z_n, r_n] = HT_SigProp_decode(sigma_n, s_n, CB_CAUSAL, state_SP);
    end

    %% HT MagRef pass decoding
    if num_passes > 2
        assert(num_passes == 3);
        state_MR = state_MR_dec(HT_Refinement_segment);
        [z_n, r_n] = HT_MagRef_decode(sigma_n, z_n, r_n, state_MR);
    end

    N_b = ones(size(mu_n), 'int32') * (S_blk + 1) + z_n; % number of decoded magnitude bit-planes
    q_b_bar(z_n ~= 0) = 2 * q_b_bar(z_n ~= 0) + r_n(z_n ~= 0);
    q_b_bar = q_b_bar .* 2.^(p - z_n);

    % ROI decoding ... not perfect..
    M_b = int32(vCodeblock.M_b);
    if ROIshift > 0
        q_b_bar(q_b_bar < 2^ROIshift) = q_b_bar(q_b_bar < 2^ROIshift) * 2^ROIshift;
        N_b(:, :) = M_b;
        q_b_bar = q_b_bar ./ 2^(ROIshift);
    end
    q_b_bar = (1 - 2 * s_n) .* q_b_bar;

else
    % no coding pass required to be decoded
    q_b_bar = zeros(vCodeblock.size_y, vCodeblock.size_x, 'int32');
    N_b = zeros(size(q_b_bar), 'int32');
end
