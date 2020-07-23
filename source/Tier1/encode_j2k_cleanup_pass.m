function dist = encode_j2k_cleanup_pass(sig_LUT, hCodeblock, p, hEBCOT_states, hEBCOT_elements, h_mq_enc, is_bypass_segment)
M_OFFSET = 1;
[J1, J2] = size(hEBCOT_elements.bitplane);
num_v_stripe = floor(J1 / 4);

CB_RESET = bitshift(bitand(hCodeblock.Cmodes, 2), -1);
if CB_RESET == true
    h_mq_enc.init_states_for_all_context();
end
CB_RESTART = bitshift(bitand(hCodeblock.Cmodes, 4), -2);
if CB_RESTART == true || is_bypass_segment
    h_mq_enc.init_coder();
end

hCodeblock.pass_idx = hCodeblock.pass_idx + 1;

L_start = h_mq_enc.L;

label_run = 17; % run-mode
label_uni = 18; % uniform
label_sig4 = zeros(1, 4); % for RLC

dist = 0.0;
DISTORTION_LSBS = 5;
SIGNIFICANCE_DISTORTIONS = 2^DISTORTION_LSBS;

[fs_lossless, fs_lossy] = init_fs_table;
fs_table = fs_lossy;
if hCodeblock.is_reversible == true && p == 0
    fs_table = fs_lossless;
end

r = int32(-1);
j1_start = 1;
for n = 1:num_v_stripe
    for j2 = 1:J2
        for j1 = j1_start:j1_start + 3
            if mod(j1 - M_OFFSET, 4) == 0 && j1 - M_OFFSET <= J1 - 4
                r = int32(-1); %signifies not using run mode
                for i = 0:3
                    label_sig4(i + M_OFFSET) = get_context_labels_sig(sig_LUT, hEBCOT_states, j1 + i, j2, hCodeblock.band_idx);
                end
                if sum(label_sig4) == 0
                    r = int32(0);
                    while r < 4 && hEBCOT_elements.bitplane(j1 + r, j2) == 0
                        r = r + 1;
                    end
                    if r == 4
                        h_mq_enc.mq_encoder(0, label_run);
                    else
                        h_mq_enc.mq_encoder(1, label_run);
                        %h_mq_enc.mq_encoder(floor(r/2), label_uni);
                        h_mq_enc.mq_encoder(bitshift(r, -1), label_uni);
                        h_mq_enc.mq_encoder(mod(r, 2), label_uni);
                    end
                end
            end
            if hEBCOT_states.sigma(j1, j2) == 0 && hEBCOT_states.pi_(j1, j2) == 0
                if r >= 0
                    r = int32(r - 1);
                else
                    label_sig = get_context_labels_sig(sig_LUT, hEBCOT_states, j1, j2, hCodeblock.band_idx);
                    h_mq_enc.mq_encoder(hEBCOT_elements.bitplane(j1, j2), label_sig);
                end
                if hEBCOT_elements.bitplane(j1, j2) == 1
                    hEBCOT_states.update_sigma(1, j1, j2);
                    encode_j2k_sign(hEBCOT_states, hEBCOT_elements, h_mq_enc, j1, j2);
                    val = double(hEBCOT_elements.magnitude_array(j1, j2)) ./ 2^double(p) ...
                        -floor(double(hEBCOT_elements.magnitude_array(j1, j2)) ./ 2^double(p));
                    val = bitand(floor(val * 2^DISTORTION_LSBS), SIGNIFICANCE_DISTORTIONS - 1);
                    dist = dist + fs_table(val + M_OFFSET);
                end
            end
        end
    end
    j1_start = j1_start + 4;
end

if mod(J1, 4) ~= 0
    % no need to enter run-mode
    for j2 = 1:J2
        for j1 = j1_start:j1_start + mod(J1, 4) - 1
            if hEBCOT_states.sigma(j1, j2) == 0 && hEBCOT_states.pi_(j1, j2) == 0
                label_sig = get_context_labels_sig(sig_LUT, hEBCOT_states, j1, j2, hCodeblock.band_idx);
                h_mq_enc.mq_encoder(hEBCOT_elements.bitplane(j1, j2), label_sig);
                if hEBCOT_elements.bitplane(j1, j2) == 1
                    hEBCOT_states.update_sigma(1, j1, j2);
                    encode_j2k_sign(hEBCOT_states, hEBCOT_elements, h_mq_enc, j1, j2);
                    val = double(hEBCOT_elements.magnitude_array(j1, j2)) ./ 2^double(p) ...
                        -floor(double(hEBCOT_elements.magnitude_array(j1, j2)) ./ 2^double(p));
                    val = bitand(floor(val * 2^DISTORTION_LSBS), SIGNIFICANCE_DISTORTIONS - 1);
                    dist = dist + fs_table(val + M_OFFSET);
                end
            end
        end
    end
end
% SEGMARK, if present
CB_SEGMARK = bitshift(bitand(hCodeblock.Cmodes, 32), -5);
if CB_SEGMARK == true
    segmark = 10; % 0x0A
    for i = 1:4
        x = bitand(bitshift(segmark, -(4 - i)), 1);
        h_mq_enc.mq_encoder(x, label_uni);
    end
end

if CB_RESTART == true || is_bypass_segment == true
    h_mq_enc.mq_encoder_end();
    untruncated_length = h_mq_enc.buf_next - h_mq_enc.buf_start;
else
    untruncated_length = h_mq_enc.buf_next - sum(hCodeblock.pass_length(1:hCodeblock.pass_idx - 1));
end

if untruncated_length < 0
    untruncated_length = int32(0);
end

% temporal pass_length; optimal length will be computed later
hCodeblock.pass_length(hCodeblock.pass_idx) = untruncated_length;
h_mq_enc.take_reg_snap_shot(hCodeblock);
