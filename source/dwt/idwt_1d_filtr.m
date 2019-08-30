function X=idwt_1d_filtr(input,ii0,ii1,dwt_filter)
%IDWT_1D_FILTR is defined in Annex F.3.8 of IS15444-1:2016
%  called from IDWT_1D_SD

M_OFFSET = int32(1);% for MATLAB index

% Define lifting coefficients for Daubechies 9x7 filter.
% To get more accurate version, you may use d97coeff.m.
A = -1.586134342059924;
%A = -1.586134342;
B = -0.052980118572961;
%B = -0.052980118;
C =  0.882911075530934;
%C = 0.882911075;
D =  0.443506852043971;
%D = 0.443506852;
K =  1.230174104914001;%K = 636/517;%K = 100333/81560;%K = 1.2302;
%

% 16bit fixedpoint values
% A = -1.586120605468750;
% B = -0.052978515625000;
% C = 0.882934570312500;
% D = 0.443481445312500;
% K = 1.230163574218750;

% find index of start and end
i0 = int32(find(input.index==ii0, 1));%-M_OFFSET;
i1 = int32(find(input.index==ii1, 1));%-M_OFFSET;

% for mex
i0 = double(i0(1));
% for mex
i1 = double(i1(1));
Yext = input.coeff;

X = zeros(size(Yext));
switch dwt_filter
    case 1 %{'5x3', '5X3'}
        n = int32(floor(i0/2)):int32(floor(i1/2));
        %X(2*n+M_OFFSET) = Yext(2*n+M_OFFSET) - floor((Yext(2*n-1+M_OFFSET) + Yext(2*n+1+M_OFFSET) + 2)/4);
        X(2*n) = Yext(2*n) - floor((Yext(2*n-1) + Yext(2*n+1) + 2)/4);%HIGH-PASS
        % Eq. F-5
        n = int32(floor(i0/2)):int32(floor(i1/2)-1);
        %X(2*n+1+M_OFFSET) = Yext(2*n+1+M_OFFSET) + floor((X(2*n+M_OFFSET) + X(2*n+2+M_OFFSET))/2);
        X(2*n+1) = Yext(2*n+1) + floor((X(2*n) + X(2*n+2))/2);%LOW-PASS
        % Eq. F-6
        %X = X(i0+M_OFFSET:i1-1+M_OFFSET);% -1 is already done in calucation i1 line 29
        X = X(i0:i1-1);
    case 0 %{'9x7', '9X7'}
        %Eq. F-7
        % STEP 1
        n = int32(floor(i0/2)-1):int32(floor(i1/2)+1);
        %X(2*n+M_OFFSET) = K*Yext(2*n+M_OFFSET);
        X(2*n) = K*Yext(2*n); 
        % STEP 2
        n = int32(floor(i0/2)-2):int32(floor(i1/2)+1);
        %X(2*n+1+M_OFFSET) = (1/K)*Yext(2*n+1+M_OFFSET);
        X(2*n+1) = (1/K)*Yext(2*n+1);
        % STEP 3
        n = int32(floor(i0/2)-1):int32(floor(i1/2)+1);
        %X(2*n+M_OFFSET) = X(2*n+M_OFFSET) - D*(X(2*n-1+M_OFFSET) + X(2*n+1+M_OFFSET));
        X(2*n) = X(2*n) - D*(X(2*n-1) + X(2*n+1));
        % STEP 4
        n = int32(floor(i0/2)-1):int32(floor(i1/2));
        %X(2*n+1+M_OFFSET) = X(2*n+1+M_OFFSET) -C*(X(2*n+M_OFFSET) + X(2*n+2+M_OFFSET));
        X(2*n+1) = X(2*n+1) -C*(X(2*n) + X(2*n+2));
        % STEP 5
        n = int32(floor(i0/2)):int32(floor(i1/2));
        %X(2*n+M_OFFSET) = X(2*n+M_OFFSET) - B*(X(2*n-1+M_OFFSET) + X(2*n+1+M_OFFSET));
        X(2*n) = X(2*n) - B*(X(2*n-1) + X(2*n+1));
        % STEP 6
        n = int32(floor(i0/2)):int32(floor(i1/2)-1);
        %X(2*n+1+M_OFFSET) = X(2*n+1+M_OFFSET) - A*(X(2*n+M_OFFSET) + X(2*n+2+M_OFFSET));
        X(2*n+1) = X(2*n+1) - A*(X(2*n) + X(2*n+2));
        X = X(i0:i1-1);% -1 is already done in calucation i1 line 29
    otherwise
        error('Specified dwt filter is not supported.');
end

