function Y = fdwt_1d_filtd(input, ii0, ii1, dwt_filter) %#codegen
%FDWT_1D_FILTD is defined in Annex F.4.8 of IS15444-1:2016
%  called from fdwt_1d_sd

M_OFFSET = int32(1); % offset for MATLAB index

% Define lifting coefficients for Daubechies 9x7 filter.
% To get more accurate version, you may use d97coeff.m.
A = -1.586134342059924;
%A = -1.586134342;
B = -0.052980118572961;
%B = -0.052980118;
C = 0.882911075530934;
%C = 0.882911075;
D = 0.443506852043971;
%D = 0.443506852;
K = 1.230174104914001; %K = 636/517;%K = 100333/81560;%K = 1.2302;
%

% 16bit fixedpoint values
% A = -1.586120605468750;
% B = -0.052978515625000;
% C = 0.882934570312500;
% D = 0.443481445312500;
% K = 1.230163574218750;

% find index of start and end
i0 = int32(find(input.index == ii0, 1)) - M_OFFSET;
i1 = int32(find(input.index == ii1, 1)) - M_OFFSET;
% for codegen
i0 = i0(1);
i1 = i1(1);

ci0 = int32(ceil(double(i0(1)) / 2));
ci1 = int32(ceil(double(i1(1)) / 2));

Xext = input.coeff;
Y = zeros(size(Xext));

switch dwt_filter
    case 1 % CDF 5x3 filter, lossless
        n = ci0 - 1:ci1 - 1;
        % Eq. F-9
        Y(2 * n + 1 + M_OFFSET) = Xext(2 * n + 1 + M_OFFSET) - floor((Xext(2 * n + M_OFFSET) + Xext(2 * n + 2 + M_OFFSET)) / 2);

        n = ci0:ci1 - 1;
        % Eq. F-10
        Y(2 * n + M_OFFSET) = Xext(2 * n + M_OFFSET) + floor((Y(2 * n - 1 + M_OFFSET) + Y(2 * n + 1 + M_OFFSET) + 2) / 4);
    case 0 % Daubechies 9x7 filter, lossy
        %Eq. F-11
        % STEP 1
        n = ci0 - 2:ci1;
        Y(2 * n + 1 + M_OFFSET) = Xext(2 * n + 1 + M_OFFSET) + A * (Xext(2 * n + M_OFFSET) + Xext(2 * n + 2 + M_OFFSET));

        % STEP 2
        n = ci0 - 1:ci1;

        Y(2 * n + M_OFFSET) = Xext(2 * n + M_OFFSET) + B * (Y(2 * n - 1 + M_OFFSET) + Y(2 * n + 1 + M_OFFSET));

        % STEP 3
        n = ci0 - 1:ci1 - 1;
        Y(2 * n + 1 + M_OFFSET) = Y(2 * n + 1 + M_OFFSET) + C * (Y(2 * n + M_OFFSET) + Y(2 * n + 2 + M_OFFSET));

        % STEP 4
        n = ci0:ci1 - 1;
        Y(2 * n + M_OFFSET) = Y(2 * n + M_OFFSET) + D * (Y(2 * n - 1 + M_OFFSET) + Y(2 * n + 1 + M_OFFSET));

        % STEP 5
        COR_value = int32(-1); % begining of n is wrong in IS 15444-1....
        n = ci0 + COR_value:ci1 - 1;
        Y(2 * n + 1 + M_OFFSET) = (K) * Y(2 * n + 1 + M_OFFSET);

        % STEP 6
        n = ci0:ci1 - 1;
        Y(2 * n + M_OFFSET) = (1 / K) * Y(2 * n + M_OFFSET);
    case 3 % ROI mask for CDF 5x3 filter, lossless
        n = ci0 - 1:ci1 - 1;
        % Eq. F-9
        Y(2 * n + 1 + M_OFFSET) = bitor(Xext(2 * n + 1 + M_OFFSET), bitor(Xext(2 * n + M_OFFSET), Xext(2 * n + 2 + M_OFFSET)));

        n = ci0:ci1 - 1;
        % Eq. F-10
        Y(2 * n + M_OFFSET) = bitor(Xext(2 * n + M_OFFSET), bitor(Y(2 * n - 1 + M_OFFSET), Y(2 * n + 1 + M_OFFSET)));
    case 2 % ROI mask for Daubechies 9x7 filter, lossy
        %Eq. F-11
        % STEP 1
        n = ci0 - 2:ci1;
        Y(2 * n + 1 + M_OFFSET) = bitor(Xext(2 * n + 1 + M_OFFSET), bitor(Xext(2 * n + M_OFFSET), Xext(2 * n + 2 + M_OFFSET)));

        % STEP 2
        n = ci0 - 1:ci1;

        Y(2 * n + M_OFFSET) = bitor(Xext(2 * n + M_OFFSET), bitor(Y(2 * n - 1 + M_OFFSET), Y(2 * n + 1 + M_OFFSET)));

        % STEP 3
        n = ci0 - 1:ci1 - 1;
        Y(2 * n + 1 + M_OFFSET) = bitor(Y(2 * n + 1 + M_OFFSET), bitor(Y(2 * n + M_OFFSET), Y(2 * n + 2 + M_OFFSET)));

        % STEP 4
        n = ci0:ci1 - 1;
        Y(2 * n + M_OFFSET) = bitor(Y(2 * n + M_OFFSET), bitor(Y(2 * n - 1 + M_OFFSET), Y(2 * n + 1 + M_OFFSET)));
    otherwise
        error('Specified dwt filter is not supported.');
end
Y = Y(i0 + M_OFFSET:i1 + M_OFFSET - 1);