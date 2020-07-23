function out = idwt_hor_sr(in, u0, u1, v0, v1, dwt_filter)
%IDWT_HOR_SR is defined in Annex F.3.4 of IS15444-1:2016
%  called from IDWT_2D_SR

M_OFFSET = 1;

i0 = u0;
i1 = u1;

a = in;
out = zeros(size(a));

row = 1;
for v = v0:v1 - 1 % includes v = v0;
    Y = a(row, :);
    X = idwt_1d_sr(Y, i0, i1, dwt_filter);
    out(row, :) = X;
    row = row + 1;
end
