function gain = get_BIBO_gain(Level, transform)

if Level == 0
    gain = 1;
    return;
else
    gain = zeros(1, 1 + Level * 3);
end

%% 5X3 filter's analysis coefficients
acdf53l = [-1, 2, 6, 2, -1] / 8;
acdf53h = [-0.5, 1, -0.5] / 1;

%% 9X7 filter's analysis coefficients
ad97h = [; ...
    0.091271763114250; ...
    -0.057543526228500; ...
    -0.591271763114250; ...
    1.115087052457000; ...
    -0.591271763114250; ...
    -0.057543526228500; ...
    0.091271763114250];
ad97l = [; ...
    0.026748757410810; ...
    -0.016864118442875; ...
    -0.078223266528990; ...
    0.266864118442875; ...
    0.602949018236360; ...
    0.266864118442875; ...
    -0.078223266528990; ...
    -0.016864118442875; ...
    0.026748757410810];

%%
if transform == 0 % irreversible dwt
    Analysis_Low = ad97l';
    Analysis_High = ad97h';
else
    Analysis_Low = acdf53l;
    Analysis_High = acdf53h;
end

%%
L = Analysis_Low;
H = Analysis_High;

LL = ones(1, Level);
LH = ones(1, Level);
HL = ones(1, Level);
HH = ones(1, Level);

Gl = L;
Gh = H;

for i = 1:Level
    g_high = sum(abs(Gh));
    g_low = sum(abs(Gl));
    HH(i) = g_high * g_high;
    LH(i) = g_high * g_low;
    HL(i) = g_low * g_high;
    LL(i) = g_low * g_low;
    Gl = conv(L, upsmpl(Gl, 2));
    Gh = conv(L, upsmpl(Gh, 2)); % convolution with "L" for Octave reconstruction!!!!
end

idx = 1;
for i = Level:-1:1
    if i == Level
        gain(idx) = LL(i);
        idx = idx + 1;
    end
    gain(idx) = HL(i);
    idx = idx + 1;
    gain(idx) = LH(i);
    idx = idx + 1;
    gain(idx) = HH(i);
    idx = idx + 1;
end