function decode_j2k_magref_pass(sig_LUT, p, hEBCOT_states, hEBCOT_elements, h_mq_dec, band_idx)
[J1, J2] = size(hEBCOT_elements.bitplane);
num_v_stripe = floor(J1 / 4);

label_mag = 0; % for MATLAB coder

j1_start = 1;
for n = 1:num_v_stripe
    for j2 = 1:J2
        for j1 = j1_start:j1_start + 3
            if hEBCOT_states.sigma(j1, j2) == 1 && hEBCOT_states.pi_(j1, j2) == 0
                hEBCOT_elements.p(j1, j2) = p;
                label_sig = get_context_labels_sig(sig_LUT, hEBCOT_states, j1, j2, band_idx);
                if (hEBCOT_states.sigma_(j1, j2) == 0) && (label_sig == 0)
                    label_mag = 14;
                elseif (hEBCOT_states.sigma_(j1, j2) == 0) && (label_sig > 0)
                    label_mag = 15;
                elseif (hEBCOT_states.sigma_(j1, j2) == 1)
                    label_mag = 16;
                end
                hEBCOT_elements.bitplane(j1, j2) = h_mq_dec.mq_decoder(label_mag);
                hEBCOT_states.sigma_(j1, j2) = hEBCOT_states.sigma(j1, j2);
            end
        end
    end
    j1_start = j1_start + 4;
end

if mod(J1, 4) ~= 0
    for j2 = 1:J2
        for j1 = j1_start:j1_start + mod(J1, 4) - 1
            if hEBCOT_states.sigma(j1, j2) == 1 && hEBCOT_states.pi_(j1, j2) == 0
                hEBCOT_elements.p(j1, j2) = p;
                label_sig = get_context_labels_sig(sig_LUT, hEBCOT_states, j1, j2, band_idx);
                if (hEBCOT_states.sigma_(j1, j2) == 0) && (label_sig == 0)
                    label_mag = 14;
                elseif (hEBCOT_states.sigma_(j1, j2) == 0) && (label_sig > 0)
                    label_mag = 15;
                elseif (hEBCOT_states.sigma_(j1, j2) == 1)
                    label_mag = 16;
                end
                hEBCOT_elements.bitplane(j1, j2) = h_mq_dec.mq_decoder(label_mag);
                hEBCOT_states.sigma_(j1, j2) = hEBCOT_states.sigma(j1, j2);
            end
        end
    end
end
