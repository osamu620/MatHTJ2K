function [alev_LL,alev_HL,alev_LH,alev_HH] = fdwt_2d_sd(alev_1_LL,u0,u1,v0,v1,dwt_filter)
%FDWT_2D_SD is defined in Annex F.4.2 of IS15444-1:2016
%  called from fdwt

a = fdwt_ver_sd(alev_1_LL, u0, u1, v0, v1, dwt_filter);
a = fdwt_hor_sd(a, u0, u1, v0, v1, dwt_filter);
[alev_LL, alev_HL, alev_LH, alev_HH] = fdwt_2d_deinterleave(a, u0, u1, v0, v1);
end

