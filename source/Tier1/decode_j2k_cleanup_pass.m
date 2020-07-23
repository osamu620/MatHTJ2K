function decode_j2k_cleanup_pass(sig_LUT, p, hEBCOT_states, hEBCOT_elements, h_mq_dec, band_idx)
M_OFFSET = 1;
[J1, J2] = size(hEBCOT_elements.bitplane);
num_v_stripe = floor(J1 / 4);

label_run = 17; % run-mode
label_uni = 18; % uniform

label_sig4 = zeros(1, 4);

r = int32(0);
j1_start = 1;
for n = 1:num_v_stripe
    for j2 = 1:J2
        k = int32(4);
        while k > 0
            j1 = j1_start + 4 - k;
            r = int32(-1); %signifies not using run mode
            if mod(j1 - M_OFFSET, 4) == 0 && j1 - M_OFFSET <= J1 - 4

                for i = 0:3
                    label_sig4(i + M_OFFSET) = get_context_labels_sig(sig_LUT, hEBCOT_states, j1 + i, j2, band_idx);
                end
                if sum(label_sig4) == 0
                    x = h_mq_dec.mq_decoder(label_run);
                    if x == 0
                        r = int32(4);
                    else
                        r = int32(h_mq_dec.mq_decoder(label_uni));
                        r = 2 * r + int32(h_mq_dec.mq_decoder(label_uni));
                        hEBCOT_elements.bitplane(j1 + int32(r), j2) = 1;
                    end
                    k = k - r;
                end
                if k ~= 0
                    j1 = j1_start + 4 - k;
                end
            end
            if hEBCOT_states.sigma(j1, j2) == 0 && hEBCOT_states.pi_(j1, j2) == 0
                hEBCOT_elements.p(j1, j2) = p;
                if r >= 0
                    r = int32(r - 1);
                else
                    label_sig = get_context_labels_sig(sig_LUT, hEBCOT_states, j1, j2, band_idx);
                    hEBCOT_elements.bitplane(j1, j2) = h_mq_dec.mq_decoder(label_sig);
                end
                if hEBCOT_elements.bitplane(j1, j2) == 1
                    hEBCOT_states.update_sigma(1, j1, j2);
                    decode_j2k_sign(hEBCOT_states, hEBCOT_elements, h_mq_dec, j1, j2);
                end
            end
            k = k - 1;
        end
    end
    j1_start = j1_start + 4;
end

if mod(J1, 4) ~= 0
    for j2 = 1:J2
        for j1 = j1_start:j1_start + mod(J1, 4) - 1
            if hEBCOT_states.sigma(j1, j2) == 0 && hEBCOT_states.pi_(j1, j2) == 0
                hEBCOT_elements.p(j1, j2) = p;
                label_sig = get_context_labels_sig(sig_LUT, hEBCOT_states, j1, j2, band_idx);
                hEBCOT_elements.bitplane(j1, j2) = h_mq_dec.mq_decoder(label_sig);
                if hEBCOT_elements.bitplane(j1, j2) == 1
                    hEBCOT_states.update_sigma(1, j1, j2);
                    decode_j2k_sign(hEBCOT_states, hEBCOT_elements, h_mq_dec, j1, j2);
                end
            end
        end
    end
end
