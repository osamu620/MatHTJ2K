function Yext = idwt_1d_extr(Y, i0, i1, dwt_filter)
%IDWT_1D_EXTR is defined in Annex F.3.7 of IS15444-1:2016
%  called from IDWT_1D_SD

M_OFFSET = 1;
table_i0 = [1, 3; 2, 4]; % +1 is needed to avoid negative index for 'n' inside idwt_1d_filtr.m
table_i1 = [2, 4; 1, 3]; % +1 is needed to avoid negative index for 'n' inside idwt_1d_filtr.m

ty_left = mod(i0, 2) + M_OFFSET;
ty_right = mod(i1, 2) + M_OFFSET;

switch dwt_filter
    case 1 %{'5x3','5X3'}
        tx = 1;
    case 0 %{'9x7','9X7'}
        tx = 2;
    otherwise
        error('Specified dwt filter is not supported.');
end
i_left = table_i0(ty_left, tx);
i_right = table_i1(ty_right, tx);

Yext = struct( ...
    'coeff', [zeros(1, i_left), Y, zeros(1, i_right)], ...
    'index', zeros(1, length([zeros(1, i_left), Y, zeros(1, i_right)]), 'int32'));

Yext.index(i_left + M_OFFSET:i_left + length(Y)) = i0:i1 - 1; %0:length(Y)-1;
%Xext -4 -3 -2 -1 1 2 ..

BOUNDARY_LEFT = i_left;
for i = 1:i_left
    Yext.index(BOUNDARY_LEFT - i + M_OFFSET) = i0 - i;
    Yext.coeff(BOUNDARY_LEFT - i + M_OFFSET) = Y(PSEo(i0 - i, i0, i1) - i0 + M_OFFSET);
end

BOUNDARY_RIGHT = i_left + length(Y); %i_left+length(Y)-1;
for i = 1:i_right
    Yext.index(BOUNDARY_RIGHT + i) = BOUNDARY_RIGHT + i - 1 - i_left + i0;
    Yext.coeff(BOUNDARY_RIGHT + i) = Y(PSEo(BOUNDARY_RIGHT + i - 1 - i_left + i0, i0, i1) - i0 + M_OFFSET);
end
%--------
    function out = PSEo(i, i0, i1)
        out = i0 + min([mod(i - i0, 2 * (i1 - i0 - 1)), 2 * (i1 - i0 - 1) - mod(i - i0, 2 * (i1 - i0 - 1))]);
    end
%--------
end
