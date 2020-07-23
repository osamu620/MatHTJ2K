function dist = encode_j2k_sigprop_pass_raw(sig_LUT, hCodeblock, p, hEBCOT_states, hEBCOT_elements, h_mq_enc)
M_OFFSET = 1;
[J1, J2] = size(hEBCOT_elements.bitplane);
num_v_stripe = floor(J1 / 4);

CB_RESET = bitshift(bitand(hCodeblock.Cmodes, 2), -1);
if CB_RESET == true
    h_mq_enc.init_states_for_all_context();
end
CB_RESTART = bitshift(bitand(hCodeblock.Cmodes, 4), -2);
% RAW coder should be always initialized at RAW SigProp pass
h_mq_enc.init_raw();

hCodeblock.pass_idx = hCodeblock.pass_idx + 1;

L_start = h_mq_enc.L;

dist = 0.0;
DISTORTION_LSBS = 5;
SIGNIFICANCE_DISTORTIONS = 2^DISTORTION_LSBS;

[fs_lossless, fs_lossy] = init_fs_table;
fs_table = fs_lossy;
if hCodeblock.is_reversible == true && p == 0
    fs_table = fs_lossless;
end


j1_start = 1;
for n = 1:num_v_stripe
    for j2 = 1:J2
        for j1 = j1_start:j1_start + 3
            label_sig = get_context_labels_sig(sig_LUT, hEBCOT_states, j1, j2, hCodeblock.band_idx);
            if hEBCOT_states.sigma(j1, j2) == 0 && label_sig > 0
                h_mq_enc.emit_raw_symbol(hEBCOT_elements.bitplane(j1, j2));
                if hEBCOT_elements.bitplane(j1, j2) == 1
                    hEBCOT_states.update_sigma(1, j1, j2);
                    encode_j2k_sign_raw(hEBCOT_states, hEBCOT_elements, h_mq_enc, j1, j2);

                    val = double(hEBCOT_elements.magnitude_array(j1, j2)) ./ 2^double(p) ...
                        -floor(double(hEBCOT_elements.magnitude_array(j1, j2)) ./ 2^double(p));
                    val = bitand(floor(val * 2^DISTORTION_LSBS), SIGNIFICANCE_DISTORTIONS - 1);
                    dist = dist + fs_table(val + M_OFFSET);
                end
                hEBCOT_states.pi_(j1, j2) = 1;
            else
                hEBCOT_states.pi_(j1, j2) = 0;
            end
        end
    end
    j1_start = j1_start + 4;
end

if mod(J1, 4) ~= 0
    for j2 = 1:J2
        for j1 = j1_start:j1_start + mod(J1, 4) - 1
            label_sig = get_context_labels_sig(sig_LUT, hEBCOT_states, j1, j2, hCodeblock.band_idx);
            if hEBCOT_states.sigma(j1, j2) == 0 && label_sig > 0
                h_mq_enc.emit_raw_symbol(hEBCOT_elements.bitplane(j1, j2));
                if hEBCOT_elements.bitplane(j1, j2) == 1
                    hEBCOT_states.update_sigma(1, j1, j2);
                    encode_j2k_sign_raw(hEBCOT_states, hEBCOT_elements, h_mq_enc, j1, j2);

                    val = double(hEBCOT_elements.magnitude_array(j1, j2)) ./ 2^double(p) ...
                        -floor(double(hEBCOT_elements.magnitude_array(j1, j2)) ./ 2^double(p));
                    val = bitand(floor(val * 2^DISTORTION_LSBS), SIGNIFICANCE_DISTORTIONS - 1);
                    dist = dist + fs_table(val + M_OFFSET);
                end
                hEBCOT_states.pi_(j1, j2) = 1;
            else
                hEBCOT_states.pi_(j1, j2) = 0;
            end
        end
    end
end

if CB_RESTART == true
    h_mq_enc.raw_termination();
end
assert(h_mq_enc.buf_next >= h_mq_enc.buf_start);
untruncated_length = h_mq_enc.buf_next - h_mq_enc.buf_start;
h_mq_enc.buf_start = h_mq_enc.buf_next;

% temporal pass_length; optimal length will be computed later
hCodeblock.pass_length(hCodeblock.pass_idx) = untruncated_length;
h_mq_enc.take_reg_snap_shot(hCodeblock);
