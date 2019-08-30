function Y = fdwt_1d_sd(X, i0, i1, dwt_filter)
%FDWT_1D_SD is defined in Annex F.4.6 of IS15444-1:2016
%  called from fdwt_ver_sd and fdwt_hor_sd

if i0 == (i1-1) % For signals of length one
    if mod(i0, 2) == 0
        Y = X;
    else
        Y = X*2;
    end
else
    Xext = fdwt_1d_extd(X, i0, i1, dwt_filter);
    Y = fdwt_1d_filtd(Xext, i0, i1, dwt_filter);
end
