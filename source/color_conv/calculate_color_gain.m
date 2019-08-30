function out = calculate_color_gain
alpha_R = 0.299; alpha_G = 0.587;alpha_B = 0.114;
rgb_gains_Y = zeros(1,3);
rgb_gains_Cb = zeros(1,3);
rgb_gains_Cr = zeros(1,3);
out = zeros(1,3);

rgb_gains_Y(1:3) = 1.0;

f1 = 2.0*(1-alpha_B); % 1.7720
f2 = 2.0*alpha_B*(1-alpha_B)/alpha_G; % 0.3441
rgb_gains_Cb(1) = 0.0;
rgb_gains_Cb(2) = f2^2;
rgb_gains_Cb(3) = f1^2;

f1 = 2.0*(1-alpha_R);% 1.4020
f2 = 2.0*alpha_R*(1-alpha_R)/alpha_G; % 0.7141
rgb_gains_Cr(1) = f1^2;
rgb_gains_Cr(2) = f2^2;
rgb_gains_Cr(3) = 0;

out(1) = sum(rgb_gains_Y);
out(2) = sum(rgb_gains_Cb);
out(3) = sum(rgb_gains_Cr);