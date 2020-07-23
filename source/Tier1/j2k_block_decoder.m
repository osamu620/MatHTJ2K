function [q_b_bar, N_b] = j2k_block_decoder(vCodeblock, ROIshift)
M_OFFSET = 1;

% retrieve codeblock style from COD marker
CB_BYPASS = bitand(vCodeblock.Cmodes, 1);
CB_RESET = bitshift(bitand(vCodeblock.Cmodes, 2), -1);
CB_RESTART = bitshift(bitand(vCodeblock.Cmodes, 4), -2);
CB_CAUSAL = bitshift(bitand(vCodeblock.Cmodes, 8), -3);
CB_ERTERM = bitshift(bitand(vCodeblock.Cmodes, 16), -4);
CB_SEGMARK = bitshift(bitand(vCodeblock.Cmodes, 32), -5);
label_uni = 18; % uniform, for SEGMARK

% set EBCOT states
states_EBCOT = ebcot_states(vCodeblock.size_x, vCodeblock.size_y);
values_EBCOT = ebcot_elements(vCodeblock.size_x, vCodeblock.size_y);
states_EBCOT.is_causal = CB_CAUSAL;

% default: all layers will be decoded.
num_layer = length(vCodeblock.layer_passes);
num_decode_pass = sum(vCodeblock.layer_passes(1:num_layer));
% buffer for all compressed bytes in a code block
compressed_byte = vCodeblock.compressed_data;
% import compressed data into MQ decoder byte-buffer
mq_reg_dec = mq_dec(compressed_byte);
mq_reg_dec.set_tables();

% Loop-up table for context determination
sig_LUT = get_sig_LUT;

% number of magnitude bit-planes
K = int32(vCodeblock.M_b) - int32(vCodeblock.num_ZBP);
num_passes = 3 * K - 2;
% maximum number of passes, if truncated actual number of passes will be smaller than this.
max_passes = uint32(3 * (int32(vCodeblock.M_b) + ROIshift - int32(vCodeblock.num_ZBP)) - 2);
% pass index
z = uint32(0);
% pass category (0 = sig, 1 = mag, 2 = cleanup)
k = 2;
% bit-plane index, starting from MSB
p = K - 1 + ROIshift;
values_EBCOT.p(:) = p;

% number of passes in a current codeword segment
current_segment_passes = uint32(0);

bitpos = 0;
segment_pos = uint32(0);

% threshold of pass index in BYPASS mode
bypass_threshold = 0;
if CB_BYPASS == true
    bypass_threshold = 10;
end
% flag for bypass mode
is_bypass = false;

while z < num_decode_pass
    if k == 3
        values_EBCOT.set_maginitude_bitplane(p);
        values_EBCOT.clear_bitplane();
        k = 0;
        p = p - 1;
        bitpos = bitpos + 1;
    end
    if current_segment_passes == 0
        segment_start = z;
        current_segment_passes = max_passes;
        if bypass_threshold > 0
            % BYPASS mode
            if z < bypass_threshold
                current_segment_passes = bypass_threshold - z;
            elseif k == 2 % cleanup pass
                current_segment_passes = uint32(1);
                is_bypass = false;
            else
                current_segment_passes = uint32(2);
                is_bypass = true;
            end
        end
        if CB_RESTART == true
            current_segment_passes = uint32(1);
        end
        if (z + uint32(current_segment_passes)) > num_decode_pass
            current_segment_passes = num_decode_pass - z;
            if num_decode_pass < max_passes
                % truncated
            end
        end
        segment_bytes = uint32(0);
        for n = 0:current_segment_passes - 1
            segment_bytes = segment_bytes + uint32(vCodeblock.pass_length(z + n + M_OFFSET));
        end
        mq_reg_dec.init_coder(segment_pos, segment_bytes, is_bypass);
        segment_pos = segment_pos + segment_bytes;
    end
    if z == 0 || CB_RESET == true
        mq_reg_dec.init_states_for_all_context();
    end

    if k == 0
        if is_bypass == true
            decode_j2k_sigprop_pass_raw(sig_LUT, p, states_EBCOT, values_EBCOT, mq_reg_dec, vCodeblock.band_idx);
        else
            decode_j2k_sigprop_pass(sig_LUT, p, states_EBCOT, values_EBCOT, mq_reg_dec, vCodeblock.band_idx);
        end
    elseif k == 1
        if is_bypass == true
            decode_j2k_magref_pass_raw(p, states_EBCOT, values_EBCOT, mq_reg_dec);
        else
            decode_j2k_magref_pass(sig_LUT, p, states_EBCOT, values_EBCOT, mq_reg_dec, vCodeblock.band_idx);
        end
    else
        decode_j2k_cleanup_pass(sig_LUT, p, states_EBCOT, values_EBCOT, mq_reg_dec, vCodeblock.band_idx);
        if CB_SEGMARK == true
            r = int32(0);
            for i = 1:4
                r = 2 * r + int32(mq_reg_dec.mq_decoder(label_uni));
            end
            if r ~= 10
                fprintf('%d is not equal to 10. Broken codeblock has been detected by SEGMARK\n', r);
            end
        end
    end
    current_segment_passes = current_segment_passes - 1;
    if current_segment_passes == 0
        mq_reg_dec.finish();
    end
    z = z + 1;
    k = k + 1;
end

% if decoding was ended at not cleanup pass, we should flush bitplane.
if k ~= 0
    values_EBCOT.set_maginitude_bitplane(p);
end
vCodeblock.N_b = int32(vCodeblock.M_b) - values_EBCOT.p;

% ROI decoding
if ROIshift > 0
    tmp = double(values_EBCOT.magnitude_array);
    tmp(tmp >= 2^double(ROIshift)) = bitshift(tmp(tmp >= 2^double(ROIshift)), -ROIshift);
    [i, j] = find(double(values_EBCOT.magnitude_array) >= 2^double(ROIshift));
    vCodeblock.N_b(i, j) = vCodeblock.M_b;
    values_EBCOT.magnitude_array = int32(tmp);
end
vCodeblock.quantized_coeffs = values_EBCOT.sign_array .* values_EBCOT.magnitude_array;
q_b_bar = vCodeblock.quantized_coeffs;
N_b = vCodeblock.N_b;
