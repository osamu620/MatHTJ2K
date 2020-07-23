function out = idwt_ver_sr(in, u0, u1, v0, v1, dwt_filter)
%IDWT_VER_SR is defined in Annex F.3.5 of IS15444-1:2016
%  called from IDWT_2D_SR


M_OFFSET = 1;

i0 = v0;
i1 = v1;

a = in;
out = zeros(size(a));

col = 1;
for u = u0:u1 - 1 % includes u = u0;
    Y = a(:, col);
    Y = reshape(Y, 1, length(Y));
    X = idwt_1d_sr(Y, i0, i1, dwt_filter);
    X = reshape(X, length(X), 1);
    out(:, col) = X;
    col = col + 1;
end
