function dist = encode_j2k_magref_pass_raw(sig_LUT, hCodeblock, p, hEBCOT_states, hEBCOT_elements, h_mq_enc)
M_OFFSET = 1;
[J1, J2] = size(hEBCOT_elements.bitplane);
num_v_stripe = floor(J1/4);

CB_RESET = bitshift(bitand(hCodeblock.Cmodes , 2), -1);
if CB_RESET == true
    h_mq_enc.init_states_for_all_context();
end
CB_RESTART = bitshift(bitand(hCodeblock.Cmodes , 4), -2);
if CB_RESTART == true
    h_mq_enc.init_raw();
end

hCodeblock.pass_idx = hCodeblock.pass_idx + 1;

L_start = h_mq_enc.L;

label_mag = 0; % for MATLAB coder

dist = 0.0;
DISTORTION_LSBS = 5;
REFINEMENT_DISTORTIONS = 2^(DISTORTION_LSBS+1);

[fm_lossless, fm_lossy] = init_fm_table;
fm_table = fm_lossy;
if hCodeblock.is_reversible == true && p == 0
    fm_table = fm_lossless;
end

j1_start = 1;
for n = 1:num_v_stripe
    for j2 = 1:J2
        for j1 = j1_start:j1_start + 3
            if hEBCOT_states.sigma(j1, j2) == 1 && hEBCOT_states.pi_(j1, j2) == 0
                h_mq_enc.emit_raw_symbol(hEBCOT_elements.bitplane(j1, j2));
                hEBCOT_states.sigma_(j1, j2) = hEBCOT_states.sigma(j1, j2);
               
                val = hEBCOT_elements.magnitude_array(j1, j2);
                val = bitshift(int32(val), 31 - int32(hCodeblock.M_b));
                val = bitshift(val, int32(hCodeblock.M_b) - p);
                val = bitshift(val, -(31 - DISTORTION_LSBS));
                val = bitand(val, REFINEMENT_DISTORTIONS - 1);
                
                dist = dist + fm_table(val + M_OFFSET);
            end
        end
    end
    j1_start = j1_start + 4;
end

if mod(J1, 4) ~= 0
    for j2 = 1:J2
        for j1 = j1_start:j1_start + mod(J1, 4) - 1
            if hEBCOT_states.sigma(j1, j2) == 1 && hEBCOT_states.pi_(j1, j2) == 0
                h_mq_enc.emit_raw_symbol(hEBCOT_elements.bitplane(j1, j2));
                hEBCOT_states.sigma_(j1, j2) = hEBCOT_states.sigma(j1, j2);
                
                val = hEBCOT_elements.magnitude_array(j1, j2);
                val = bitshift(int32(val), 31 - int32(hCodeblock.M_b));
                val = bitshift(val, int32(hCodeblock.M_b) - p);
                val = bitshift(val, -(31 - DISTORTION_LSBS));
                val = bitand(val, REFINEMENT_DISTORTIONS - 1);
                dist = dist + fm_table(val + M_OFFSET);
            end
        end
    end
end

h_mq_enc.raw_termination();

assert(h_mq_enc.buf_next >= h_mq_enc.buf_start);
untruncated_length = h_mq_enc.buf_next - h_mq_enc.buf_start;
h_mq_enc.buf_start = h_mq_enc.buf_next;

% temporal pass_length; optimal length will be computed later
hCodeblock.pass_length(hCodeblock.pass_idx) = untruncated_length;
h_mq_enc.take_reg_snap_shot(hCodeblock);
