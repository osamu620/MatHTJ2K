function out = fdwt_ver_sd(in, u0, u1, v0, v1, dwt_filter)
%FDWT_VER_SD is defined in Annex F.4.3 of IS15444-1:2016
%  called from fdwt_2d_sd


M_OFFSET = 1;

i0 = v0;
i1 = v1;

a = in;
out = zeros(size(a));

col = 1;
for u = u0:u1 - 1 % includes u = u0;
    X = a(:, col);
    X = reshape(X, 1, length(X));
    Y = fdwt_1d_sd(X, i0, i1, dwt_filter);
    Y = reshape(Y, length(Y), 1);
    out(:, col) = Y;
    col = col + 1;
end
