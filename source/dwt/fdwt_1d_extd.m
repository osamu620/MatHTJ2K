function Xext = fdwt_1d_extd(X,i0,i1,dwt_filter)
%FDWT_1D_EXTD is defined in Annex F.4.7 of IS15444-1:2016
%  called from fdwt_1d_sd 

M_OFFSET = 1;
table_i0  = [2 4;1 3];
table_i1 = [1 3;2 4];

ty_left  = mod(i0,2) + M_OFFSET;
ty_right = mod(i1,2) + M_OFFSET;

switch dwt_filter
    case 1 %{'5x3','5X3'}
        tx = 1;
    case 0 %{'9x7','9X7'}
        tx = 2;
    otherwise
        error('Specified dwt filter is not supported.');
end
i_left  = table_i0(ty_left, tx);
i_right = table_i1(ty_right, tx);

Xext = struct(...
    'coeff', [zeros(1,i_left) X zeros(1,i_right)], ...
    'index', zeros(1, length([zeros(1,i_left) X zeros(1,i_right)]), 'int32'));

Xext.index(i_left+M_OFFSET:i_left+length(X)) = i0:i1-1;%0:length(X)-1;
%Xext -4 -3 -2 -1 1 2 ..

BOUNDARY_LEFT = i_left;
for i=1:i_left
    Xext.index(BOUNDARY_LEFT-i+M_OFFSET) = i0-i;
    Xext.coeff(BOUNDARY_LEFT-i+M_OFFSET) = X(PSEo(i0-i,i0,i1)-i0+M_OFFSET);
end

BOUNDARY_RIGHT = i_left+length(X);%-1;
for i=1:i_right
    Xext.index(BOUNDARY_RIGHT+i) = BOUNDARY_RIGHT+i-1-i_left+i0;%(BOUNDARY_RIGHT-i_left)+i;
    Xext.coeff(BOUNDARY_RIGHT+i) = X(PSEo(BOUNDARY_RIGHT+i-1-i_left+i0,i0,i1)-i0+M_OFFSET);%X(PSEo(BOUNDARY_RIGHT-i_left+i,i0,i1)+M_OFFSET);
end
%--------
    function out = PSEo(i,i0,i1)
        out = i0 + min([mod(i-i0, 2*(i1-i0-1)) 2*(i1-i0-1)-mod(i-i0, 2*(i1-i0-1))]);
    end
%--------
end

