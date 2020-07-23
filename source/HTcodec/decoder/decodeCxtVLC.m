function [rho, u_off, emb_k, emb_1] = decodeCxtVLC(context, Dcup, Pcup, Lcup, state_VLC_dec, dec_CxtVLC_table) %#codegen

b_low = int32(state_VLC_dec.VLC_tmp);
b_upp = int32(modDcup(Dcup, state_VLC_dec.VLC_pos, Lcup));
word = b_upp * int32(2)^int32(state_VLC_dec.VLC_bits) + b_low;
cwd = bitand(word, 127);

idx = cwd + context * 128 + int32(1);
len = dec_CxtVLC_table(idx, 1);
for i = 1:len
    importVLCBit(Dcup, Pcup, Lcup, state_VLC_dec);
end
rho = dec_CxtVLC_table(idx, 2);
u_off = dec_CxtVLC_table(idx, 3);
emb_k = dec_CxtVLC_table(idx, 4);
emb_1 = dec_CxtVLC_table(idx, 5);

%% Naive implementation(slow)
% if q < QW
%     dec_CxtVLC_table = get_dec_CxtVLC_table_0;
% else
%     dec_CxtVLC_table = get_dec_CxtVLC_table_1;
% end
% len = int32(1);
% cwd = importVLCBit(Dcup, Pcup, Lcup, state_VLC_dec);
% val = test_match(dec_CxtVLC_table, context, cwd, len);
% while isempty(val) == true
%     bit = importVLCBit(Dcup, Pcup, Lcup, state_VLC_dec);
%     cwd = bitor(cwd, bitshift(bit, len));
%     len = len + 1;
%     val = test_match(dec_CxtVLC_table, context, cwd, len);
% end
% % %equivalent to get_match()
% % rho = val(2);
% % u_off = val(3);
% % emb_k = val(4);
% % emb_1 = val(5);
% [rho, u_off, emb_k, emb_1] = get_match(val);
%
%     function val = test_match(t, c, w, lw)
%         tmp0 = t(t(:,1)==c,:);
%         tmp1 = tmp0(tmp0(:,6) == w, :);
%         tmp2 = tmp1(tmp1(:,7) == lw,:);
%         if size(tmp2, 1) == 1
%             val = tmp2;
%         else
%             val = [];
%         end
%     end
%
%     function [rho, u_off, emb_k, emb_1] = get_match(t, c, w, lw)
%         tmp0 = t(t(:,1)==c,:);
%         tmp1 = tmp0(tmp0(:,6) == w, :);
%         tmp2 = tmp1(tmp1(:,7) == lw,:);
%         rho = tmp2(2);
%         u_off = tmp2(3);
%         emb_k = tmp2(4);
%         emb_1 = tmp2(5);
%     end
end
