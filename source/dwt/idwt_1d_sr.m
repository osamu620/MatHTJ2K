function X = idwt_1d_sr(Y, i0, i1, dwt_filter)
%IDWT_1D_SR is defined in Annex F.3.6 of IS15444-1:2016
%  called from idwt_ver_sr and idwt_hor_sr

if i0 == (i1-1) % For signals of length one
    if mod(i0, 2) == 0
        X = Y;
    else
        X = Y/2;
    end
else
    Yext = idwt_1d_extr(Y, i0, i1, dwt_filter);
    X = idwt_1d_filtr(Yext, i0, i1, dwt_filter);
end

