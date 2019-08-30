function decode_j2k_sign_raw(hEBCOT_elements, h_mq_dec, j1, j2)

x = h_mq_dec.get_raw_symbol();
if x == 0
    hEBCOT_elements.update_sign_array(1, j1, j2);
else
    hEBCOT_elements.update_sign_array(-1, j1, j2);
end