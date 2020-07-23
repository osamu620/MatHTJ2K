function out = fdwt_hor_sd(in, u0, u1, v0, v1, dwt_filter)
%FDWT_HOR_SD is defined in Annex F.4.4 of IS15444-1:2016
%  called from fdwt_2d_sd

M_OFFSET = 1;

i0 = u0;
i1 = u1;

a = in;
out = zeros(size(a));

row = 1;
for v = v0:v1 - 1 % includes v = v0;
    X = a(row, :);
    Y = fdwt_1d_sd(X, i0, i1, dwt_filter);
    out(row, :) = Y;
    row = row + 1;
end
