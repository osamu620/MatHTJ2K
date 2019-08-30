function [cwd, len] = pack_UVLC_codeword_components_reversed_table(enc_table_UVLC, u1, u2)

u_in1 = u1;
u_in2 = int32(0);
if nargin == 3
    u_in2 = u2;
end

idx = bitshift(u_in2, int32(5))+ u_in1 + int32(1);
cwd = enc_table_UVLC(idx);
len = bitand(cwd, int32(255));
cwd = bitshift(cwd, -8);







