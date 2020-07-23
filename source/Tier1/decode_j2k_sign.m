function decode_j2k_sign(hEBCOT_states, hEBCOT_elements, h_mq_dec, j1, j2) %#codegen

scan_window_sigma = hEBCOT_states.dummy_sigma(j1:j1 + 2, j2:j2 + 2);
scan_window_sigma(2, 2) = 0;
if hEBCOT_states.is_causal == true && mod(j1, 4) == 0
    scan_window_sigma(3, :) = 0;
end
scan_window_sign = hEBCOT_elements.dummy_sign(j1:j1 + 2, j2:j2 + 2);
scan_window_sign(2, 2) = 0;

% scan_window is now ready
khi_h = scan_window_sign(2, 1) * scan_window_sigma(2, 1) + scan_window_sign(2, 3) * scan_window_sigma(2, 3);
khi_v = scan_window_sign(1, 2) * scan_window_sigma(1, 2) + scan_window_sign(3, 2) * scan_window_sigma(3, 2);
khi_h_ = sign(khi_h) * min(1, abs(khi_h));
khi_v_ = sign(khi_v) * min(1, abs(khi_v));

% for MATLAB coder
label = 0;
khi_flip = 0;

%determine sign context k_sign
if (khi_h_ == 1) && (khi_v_ == 1)
    label = 13;
    khi_flip = 1;
end
if (khi_h_ == 1) && (khi_v_ == 0)
    label = 12;
    khi_flip = 1;
end
if (khi_h_ == 1) && (khi_v_ == -1)
    label = 11;
    khi_flip = 1;
end
if (khi_h_ == 0) && (khi_v_ == 1)
    label = 10;
    khi_flip = 1;
end
if (khi_h_ == 0) && (khi_v_ == 0)
    label = 9;
    khi_flip = 1;
end
if (khi_h_ == 0) && (khi_v_ == -1)
    label = 10;
    khi_flip = -1;
end
if (khi_h_ == -1) && (khi_v_ == 1)
    label = 11;
    khi_flip = -1;
end
if (khi_h_ == -1) && (khi_v_ == 0)
    label = 12;
    khi_flip = -1;
end
if (khi_h_ == -1) && (khi_v_ == -1)
    label = 13;
    khi_flip = -1;
end

x = h_mq_dec.mq_decoder(label);
if x == 0
    hEBCOT_elements.update_sign_array(khi_flip, j1, j2);
else
    hEBCOT_elements.update_sign_array(khi_flip * (-1), j1, j2);
end
