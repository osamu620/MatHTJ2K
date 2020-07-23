function [alev_LL, alev_HL, alev_LH, alev_HH] = fdwt_2d_deinterleave(a, u0, u1, v0, v1)
%FDWT_2D_DEINTERLEAVE is defined in Annex F.4.5 of IS15444-1:2016
%  called from fdwt_2d_sd

M_OFFSET = 1; % matlab offset

% alev_LL = zeros(ceil(v1/2)-1-ceil(v0/2)+1, ceil(u1/2)-1-ceil(u0/2)+1);
% alev_HL = zeros(ceil(v1/2)-1-ceil(v0/2)+1, floor(u1/2)-1-floor(u0/2)+1);
% alev_LH = zeros(floor(v1/2)-1-floor(v0/2)+1, ceil(u1/2)-1-ceil(u0/2)+1);
% alev_HH = zeros(floor(v1/2)-1-floor(v0/2)+1, floor(u1/2)-1-floor(u0/2)+1);

alev_LL = zeros(ceil(double(v1) / 2) - ceil(double(v0) / 2), ceil(double(u1) / 2) - ceil(double(u0) / 2));
alev_HL = zeros(ceil(double(v1) / 2) - ceil(double(v0) / 2), ceil((double(u1) - 1) / 2) - ceil((double(u0) - 1) / 2));
alev_LH = zeros(ceil((double(v1) - 1) / 2) - ceil((double(v0) - 1) / 2), ceil(double(u1) / 2) - ceil(double(u0) / 2));
alev_HH = zeros(ceil((double(v1) - 1) / 2) - ceil((double(v0) - 1) / 2), ceil((double(u1) - 1) / 2) - ceil((double(u0) - 1) / 2));

v_offset = mod(v0, 2);
u_offset = mod(u0, 2);
v = 0;
for vb = ceil(double(v0) / 2):ceil(double(v1) / 2) - 1
    u = 0;
    for ub = ceil(double(u0) / 2):ceil(double(u1) / 2) - 1
        alev_LL(v + M_OFFSET, u + M_OFFSET) = a(2 * v + M_OFFSET + v_offset, 2 * u + M_OFFSET + u_offset);
        u = u + 1;
    end
    v = v + 1;
end

%b=levHL
v = 0;
for vb = ceil(double(v0) / 2):ceil(double(v1) / 2) - 1
    u = 0;
    for ub = floor(double(u0) / 2):floor(double(u1) / 2) - 1
        alev_HL(v + M_OFFSET, u + M_OFFSET) = a(2 * v + M_OFFSET + v_offset, 2 * u + 1 + M_OFFSET - u_offset);
        u = u + 1;
    end
    v = v + 1;
end

%b=levLH
v = 0;
for vb = floor(double(v0) / 2):floor(double(v1) / 2) - 1
    u = 0;
    for ub = ceil(double(u0) / 2):ceil(double(u1) / 2) - 1
        alev_LH(v + M_OFFSET, u + M_OFFSET) = a(2 * v + 1 + M_OFFSET - v_offset, 2 * u + M_OFFSET + u_offset);
        u = u + 1;
    end
    v = v + 1;
end

%b=levHH
v = 0;
for vb = floor(double(v0) / 2):floor(double(v1) / 2) - 1
    u = 0;
    for ub = floor(double(u0) / 2):floor(double(u1) / 2) - 1
        alev_HH(v + M_OFFSET, u + M_OFFSET) = a(2 * v + 1 + M_OFFSET - v_offset, 2 * u + 1 + M_OFFSET - u_offset);
        u = u + 1;
    end
    v = v + 1;
end


% %b=levLL
% alev_LL = zeros(ceil(v1/2)-1-ceil(v0/2)+1, ceil(u1/2)-1-ceil(u0/2)+1);
% for vb = ceil(v0/2):ceil(v1/2)-1
%     for ub = ceil(u0/2):ceil(u1/2)-1
%         alev_LL(vb+M_OFFSET,ub+M_OFFSET) = a(2*vb+M_OFFSET,2*ub+M_OFFSET);
%     end
% end
%
% %b=levHL
% alev_HL = zeros(ceil(v1/2)-1-ceil(v0/2)+1, floor(u1/2)-1-floor(u0/2)+1);
% for vb = ceil(v0/2):ceil(v1/2)-1
%     for ub = floor(u0/2):floor(u1/2)-1
%         alev_HL(vb+M_OFFSET,ub+M_OFFSET) = a(2*vb+M_OFFSET,2*ub+1+M_OFFSET);
%     end
% end
%
% %b=levLH
% alev_LH = zeros(floor(v1/2)-1-floor(v0/2)+1, ceil(u1/2)-1-ceil(u0/2)+1);
% for vb = floor(v0/2):floor(v1/2)-1
%     for ub = ceil(u0/2):ceil(u1/2)-1
%         alev_LH(vb+M_OFFSET,ub+M_OFFSET) = a(2*vb+1+M_OFFSET,2*ub+M_OFFSET);
%     end
% end
%
% %b=levHH
% alev_HH = zeros(floor(v1/2)-1-floor(v0/2)+1, floor(u1/2)-1-floor(u0/2)+1);
% for vb = floor(v0/2):floor(v1/2)-1
%     for ub = floor(u0/2):floor(u1/2)-1
%         alev_HH(vb+M_OFFSET,ub+M_OFFSET) = a(2*vb+1+M_OFFSET,2*ub+1+M_OFFSET);
%     end
% end
