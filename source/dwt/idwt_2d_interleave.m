function a = idwt_2d_interleave(alev_LL, alev_HL, alev_LH, alev_HH, u0, u1, v0, v1)
%IDWT_2D_INTERLEAVE is defined in Annex F.3.3 of IS15444-1:2016
%  called from IDWT_2D_SR

M_OFFSET = 1; % matlab offset

a = zeros(v1 - v0, u1 - u0);
%b=levLL
v_offset = mod(v0, 2);
u_offset = mod(u0, 2);
v = 0;
for vb = ceil(double(v0) / 2):ceil(double(v1) / 2) - 1
    u = 0;
    for ub = ceil(double(u0) / 2):ceil(double(u1) / 2) - 1
        a(2 * v + M_OFFSET + v_offset, 2 * u + M_OFFSET + u_offset) = alev_LL(v + M_OFFSET, u + M_OFFSET);
        u = u + 1;
    end
    v = v + 1;
end

%b=levHL
v = 0;
for vb = ceil(double(v0) / 2):ceil(double(v1) / 2) - 1
    u = 0;
    for ub = floor(double(u0) / 2):floor(double(u1) / 2) - 1
        a(2 * v + M_OFFSET + v_offset, 2 * u + 1 + M_OFFSET - u_offset) = alev_HL(v + M_OFFSET, u + M_OFFSET);
        u = u + 1;
    end
    v = v + 1;
end

%b=levLH
v = 0;
for vb = floor(double(v0) / 2):floor(double(v1) / 2) - 1
    u = 0;
    for ub = ceil(double(u0) / 2):ceil(double(u1) / 2) - 1
        a(2 * v + 1 + M_OFFSET - v_offset, 2 * u + M_OFFSET + u_offset) = alev_LH(v + M_OFFSET, u + M_OFFSET);
        u = u + 1;
    end
    v = v + 1;
end

%b=levHH
v = 0;
for vb = floor(double(v0) / 2):floor(double(v1) / 2) - 1
    u = 0;
    for ub = floor(double(u0) / 2):floor(double(u1) / 2) - 1
        a(2 * v + 1 + M_OFFSET - v_offset, 2 * u + 1 + M_OFFSET - u_offset) = alev_HH(v + M_OFFSET, u + M_OFFSET);
        u = u + 1;
    end
    v = v + 1;
end
% [M, N] = size(a);
% v_start = 1;
% u_start = 1;
% if M > (v1 - v0)
%     v_start = 2;u_start = 2;
% end
% if N > (u1 - u0)
%     u_start = 2;
% end
%
% a = a(v_start:v_start+v1-v0-1, u_start:u_start+u1-u0-1);
%
