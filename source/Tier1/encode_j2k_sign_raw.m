function encode_j2k_sign_raw(hEBCOT_states, hEBCOT_elements, h_mq_enc, j1, j2)

s = hEBCOT_elements.sign_array(j1, j2);

if s >= 0
    h_mq_enc.emit_raw_symbol(0);
else
    h_mq_enc.emit_raw_symbol(1);
end

