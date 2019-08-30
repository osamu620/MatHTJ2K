function label = get_context_labels_sig(sig_LUT, hEBCOT_states, j1, j2, band)

scan_window_sigma = hEBCOT_states.dummy_sigma(j1:j1+2, j2:j2+2);
scan_window_sigma(2, 2) = 0;
if hEBCOT_states.is_causal == true && mod(j1, 4) == 0
    scan_window_sigma(3, :) = 0;
end

% scan_window is now ready
k_h = uint8(scan_window_sigma(2,1)+scan_window_sigma(2,3));% horizontal
k_v = uint8(scan_window_sigma(1,2)+scan_window_sigma(3,2));% vertical
k_d = uint8(scan_window_sigma(1,1)+scan_window_sigma(1,3)+scan_window_sigma(3,1)+scan_window_sigma(3,3)); % diagonal

label = sig_LUT(uint8(15)*k_h+uint8(5)*k_v+k_d+uint8(1), band+uint8(1));

%% non LUT version
% switch band
%     case 0 %% LL 
%         if (k_h == 2)
%             label = 8;
%         end
%         if (k_h == 1) && (k_v >= 1)
%             label = 7;
%         end
%         if (k_h == 1) && (k_v == 0 ) && (k_d >= 1)
%             label = 6;
%         end
%         if (k_h == 1) && (k_v == 0 ) && (k_d == 0)
%             label = 5;
%         end
%         if (k_h == 0) && (k_v == 2)
%             label = 4;
%         end
%         if (k_h == 0) && (k_v == 1)
%             label = 3;
%         end
%         if (k_h == 0) && (k_v == 0 ) && (k_d >= 2)
%             label = 2;
%         end
%         if (k_h == 0) && (k_v == 0 ) && (k_d == 1)
%             label = 1;
%         end
%         if (k_h == 0) && (k_v == 0 ) && (k_d == 0)
%             label = 0;
%         end
%     case 1 % HL
%         if (k_v == 2)
%             label = 8;
%         end
%         if (k_h >= 1) && (k_v == 1)
%             label = 7;
%         end
%         if (k_h == 0) && (k_v == 1 ) && (k_d >= 1)
%             label = 6;
%         end
%         if (k_h == 0) && (k_v == 1 ) && (k_d == 0)
%             label = 5;
%         end
%         if (k_h == 2) && (k_v == 0)
%             label = 4;
%         end
%         if (k_h == 1) && (k_v == 0)
%             label = 3;
%         end
%         if (k_h == 0) && (k_v == 0 ) && (k_d >= 2)
%             label = 2;
%         end
%         if (k_h == 0) && (k_v == 0 ) && (k_d == 1)
%             label = 1;
%         end
%         if (k_h == 0) && (k_v == 0 ) && (k_d == 0)
%             label = 0;
%         end
%     case 2 % LH
%         if (k_h == 2)
%             label = 8;
%         end
%         if (k_h == 1) && (k_v >= 1)
%             label = 7;
%         end
%         if (k_h == 1) && (k_v == 0 ) && (k_d >= 1)
%             label = 6;
%         end
%         if (k_h == 1) && (k_v == 0 ) && (k_d == 0)
%             label = 5;
%         end
%         if (k_h == 0) && (k_v == 2)
%             label = 4;
%         end
%         if (k_h == 0) && (k_v == 1)
%             label = 3;
%         end
%         if (k_h == 0) && (k_v == 0 ) && (k_d >= 2)
%             label = 2;
%         end
%         if (k_h == 0) && (k_v == 0 ) && (k_d == 1)
%             label = 1;
%         end
%         if (k_h == 0) && (k_v == 0 ) && (k_d == 0)
%             label = 0;
%         end
%     case 3 % HH
%         k_hv=k_h+k_v;
%         if (k_d >= 3)
%             label = 8;
%         end
%         if (k_d == 2) && (k_hv >= 1)
%             label = 7;
%         end
%         if (k_d == 2) && (k_hv == 0 )
%             label = 6;
%         end
%         if (k_d == 1) && (k_hv >= 2 )
%             label = 5;
%         end
%         if (k_d == 1) && (k_hv == 1 )
%             label = 4;
%         end
%         if (k_d == 1) && (k_hv == 0 )
%             label = 3;
%         end
%         if (k_d == 0) && (k_hv >= 2 )
%             label = 2;
%         end
%         if (k_d == 0) && (k_hv == 1 )
%             label = 1;
%         end
%         if (k_d == 0) && (k_hv == 0 )
%             label = 0;
%         end
%     otherwise
%         label = -1;
% end
