function decode_j2k_sigprop_pass_raw(sig_LUT, p, hEBCOT_states, hEBCOT_elements, h_mq_dec, band_idx)

[J1, J2] = size(hEBCOT_elements.magnitude_array);
num_v_stripe = floor(J1 / 4);

j1_start = 1;
for n = 1:num_v_stripe
    for j2 = 1:J2
        for j1 = j1_start:j1_start + 3
            label_sig = get_context_labels_sig(sig_LUT, hEBCOT_states, j1, j2, band_idx);
            if hEBCOT_states.sigma(j1, j2) == 0 && label_sig > 0
                hEBCOT_elements.p(j1, j2) = p;
                hEBCOT_elements.bitplane(j1, j2) = h_mq_dec.get_raw_symbol();
                if hEBCOT_elements.bitplane(j1, j2) == 1
                    hEBCOT_states.update_sigma(1, j1, j2);
                    decode_j2k_sign_raw(hEBCOT_elements, h_mq_dec, j1, j2);
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
            label_sig = get_context_labels_sig(sig_LUT, hEBCOT_states, j1, j2, band_idx);
            if hEBCOT_states.sigma(j1, j2) == 0 && label_sig > 0
                hEBCOT_elements.p(j1, j2) = p;
                hEBCOT_elements.bitplane(j1, j2) = h_mq_dec.get_raw_symbol();
                if hEBCOT_elements.bitplane(j1, j2) == 1
                    hEBCOT_states.update_sigma(1, j1, j2);
                    decode_j2k_sign_raw(hEBCOT_elements, h_mq_dec, j1, j2);
                end
                hEBCOT_states.pi_(j1, j2) = 1;
            else
                hEBCOT_states.pi_(j1, j2) = 0;
            end
        end
    end
end
