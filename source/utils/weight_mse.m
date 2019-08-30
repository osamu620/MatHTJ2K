function Weight = weight_mse(Level, transform)
% WEIGHT_MSE : calculate the energy gain of DWT subbands with octave-reconstruction.
%
% output = weight_mse(dwt_level, transform);
%        = [nLL nHL nLH nHH n-1HL n-1LH n-1HH ... 1HL 1LH 1HH]
%
% Note: DC-gain of Synthesis_Low must be 2,
%       and Nyquist-gain of Synthesis_High must be 1.
%
% This M-file is written based on,
% [1] A.Bilgin, P.J.Sementilli, F.Sheng, and M.W.Marcellin,
% "Scalable Image Coding Using Reversible Integer Wavelet Transform, "
% IEEE Trans. on Image Processing, Vol.9, No.11, pp. 1972--1977, Nov.2000.
% [2] J. W. Woods and T. Naveen, "A filter based bit allocation scheme for subband compression of HDTV,"
% in IEEE Transactions on Image Processing, vol. 1, no. 3, pp. 436-440, July 1992.
% doi: 10.1109/83.148618, URL: http://ieeexplore.ieee.org/stamp/stamp.jsp?tp=&arnumber=148618&isnumber=3937

if Level == 0
    Weight = 1;
    return;
else
    Weight = zeros(1, 1+Level*3);
end
%% 5X3 filter's synthesis coefficients
scdf53l = [0.5 1 0.5]/1;
scdf53h = [-1 -2 6 -2 -1]/8;


%% 16-bit fixed-point representation of 9x7 filter
sl=[
  -0.091247558593750
  -0.057556152343750
   0.591247558593750
   1.115112304687500
   0.591247558593750
  -0.057556152343750
  -0.091247558593750
    ];
sh=[
   0.026733398437500
   0.016845703125000
  -0.078247070312500
  -0.266845703125000
   0.602966308593750
  -0.266845703125000
  -0.078247070312500
   0.016845703125000
   0.026733398437500
   ];

%% 16-bit fixed-point representation of 9x7 filter
ah=[
  0.091247558593750
  -0.057556152343750
   -0.591247558593750
   1.115112304687500
   -0.591247558593750
  -0.057556152343750
  0.091247558593750
    ];
al=[
   0.026733398437500
   -0.016845703125000
  -0.078247070312500
  0.266845703125000
   0.602966308593750
  0.266845703125000
  -0.078247070312500
   -0.016845703125000
   0.026733398437500
   ];

%% 9X7 filter's synthesis coefficients
sd97l =[
    -0.091271763114250
    -0.057543526228500
    0.591271763114250
    1.115087052457000
    0.5912717631142500
    -0.05754352622850
    -0.091271763114250];
sd97h =[
    0.026748757410811
    0.016864118442875
    -0.078223266528990
    -0.266864118442875
    0.602949018236360
    -0.266864118442875
    -0.078223266528990
    0.016864118442875
    0.026748757410811]*2;

%% 9X7 filter's analysis coefficients
ad97h =[
    0.091271763114250
    -0.057543526228500
    -0.591271763114250
    1.115087052457000
    -0.591271763114250
    -0.057543526228500
    0.091271763114250];
ad97l =[
    0.026748757410810
    -0.016864118442875
    -0.078223266528990
    0.266864118442875
    0.602949018236360
    0.266864118442875
    -0.078223266528990
    -0.016864118442875
    0.026748757410810];
%% 9X7 filter coefficients from Kakadu v7
kdu_sl = [
    -0.091272
    -0.057544
    0.591272
    1.115087
    0.591272
    -0.057544
    -0.091272];
kdu_sh =[
    0.053498
    0.033728
    -0.156446
    -0.533728
    1.205898
    -0.533728
    -0.156446
    0.033728
    0.053498
    ];
%%
if transform == 0 % irreversible dwt
    Synthesis_Low = sd97l';%kdu_sl;%scdf53l;
    Synthesis_High = sd97h';%kdu_sh;%scdf53h;
    % show symthesis lowpass DC-gain
    %sum(Synthesis_Low)
    % show symthesis highass Nyquist-gain
    %sum(Synthesis_High.*[1 -1 1 -1 1 -1 1 -1 1]')
else
    Synthesis_Low = scdf53l;
    Synthesis_High = scdf53h;
    % show symthesis lowpass DC-gain
    %sum(Synthesis_Low)
    % show symthesis highass Nyquist-gain
    %sum(Synthesis_High.*[1 -1 1 -1 1])
end

%%%%%
L = Synthesis_Low;
H = Synthesis_High;

LL = ones(1,Level);
LH = ones(1,Level);
HL = ones(1,Level);
HH = ones(1,Level);

Gl = L;
Gh = H;

for i=1:Level
    w_high = sum(Gh.^2);
    w_low = sum(Gl.^2);
    HH(i) = w_high * w_high;
    LH(i) = w_high * w_low;
    HL(i) = w_low * w_high;
    LL(i) = w_low * w_low;
    Gl = conv(L,upsmpl(Gl,2));
    Gh = conv(L,upsmpl(Gh,2));% convolution with "L" for Octave reconstruction!!!!
end

idx = 1;
for i=Level:-1:1
    if i == Level
        Weight(idx) = LL(i);
        idx = idx + 1;
    end
    Weight(idx) = HL(i);
    idx = idx + 1;
    Weight(idx) = LH(i);
    idx = idx + 1;
    Weight(idx) = HH(i);
    idx = idx + 1;
end