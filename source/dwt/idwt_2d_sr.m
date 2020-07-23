function [alev_1_LL] = idwt_2d_sr(alev_LL, alev_HL, alev_LH, alev_HH, u0, u1, v0, v1, dwt_filter)
%IDWT_2D_SR is defined in Annex F.3.2 of IS15444-1:2016
%  called from IDWT


a = idwt_2d_interleave(alev_LL, alev_HL, alev_LH, alev_HH, u0, u1, v0, v1);
a = idwt_hor_sr(a, u0, u1, v0, v1, dwt_filter);
alev_1_LL = idwt_ver_sr(a, u0, u1, v0, v1, dwt_filter);
end
