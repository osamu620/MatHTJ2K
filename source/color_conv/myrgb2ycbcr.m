function out = myrgb2ycbcr(img, transformation)
%MYRGB2YCBCR - converts RGB to YCbCr as defined in BT.601
% "studio swing" (range adjustment) won't be perfomred.
% usage: out = myrgb2ycbcr(input, <reversible (true or false(default))> );

if nargin < 2
    transformation = false;
end

[~, ~, c] = size(img);
if c ~= 3
    error('input image shall have 3 components.');
end

R = img(:, :, 1);
G = img(:, :, 2);
B = img(:, :, 3);

ALPHA_R = 0.299;
ALPHA_B = 0.114;
ALPHA_RB = (ALPHA_R + ALPHA_B);
ALPHA_G = (1 - ALPHA_RB);
CB_FACT = (1 / (2 * (1 - ALPHA_B)));
CR_FACT = (1 / (2 * (1 - ALPHA_R)));


origClass = class(img);

if transformation == 1 % Reversible Color Transform
    switch origClass
        case {'uint8', 'int8'}
            R = int16(R);
            G = int16(G);
            B = int16(B);
            Y = bitshift((R + G + G + B), -2);
            Cb = B - G;
            Cr = R - G;
            outputClass = 'int16';
        case {'uint16', 'int16'}
            R = int32(R);
            G = int32(G);
            B = int32(B);
            Y = bitshift((R + G + G + B), -2);
            Cb = B - G;
            Cr = R - G;
            outputClass = 'int32';
        case {'single', 'double'}
            R = double(R);
            G = double(G);
            B = double(B);
            Y = floor((R + 2 * G + B) / 4);
            Cb = B - G;
            Cr = R - G;
            outputClass = 'double';
        otherwise
            error('Reversible color transform can be applied only for uint8, uint16, int8, int16, single and double inputs.');
    end
else % Irreversible Color Transform as defiend in BT.601
    switch origClass
        case {'uint8', 'uint16', 'int8', 'int16'}
            ALPHA_R14 = int32(0.5 + ALPHA_R * bitshift(1, 14));
            ALPHA_G14 = int32(0.5 + ALPHA_G * bitshift(1, 14));
            ALPHA_B14 = int32(0.5 + ALPHA_B * bitshift(1, 14));
            CB_FACT14 = int32(0.5 + CB_FACT * bitshift(1, 14));
            CR_FACT14 = int32(0.5 + CR_FACT * bitshift(1, 14));
            Y = bitshift(ALPHA_R14 * int32(R) + ALPHA_G14 * int32(G) + ALPHA_B14 * int32(B) + bitshift(1, 13), -14);
            Cb = bitshift(CB_FACT14 * (int32(B) - Y) + bitshift(1, 13), -14);
            Cr = bitshift(CR_FACT14 * (int32(R) - Y) + bitshift(1, 13), -14);
            Y = cast(Y, 'int16');
            Cb = cast(Cb, 'int16');
            Cr = cast(Cr, 'int16');
            outputClass = 'int16';
        case {'uint32', 'int32'}
            Y = ALPHA_R * double(R) + ALPHA_G * double(G) + ALPHA_B * double(B);
            Cb = CB_FACT * (double(B) - Y);
            Cr = CR_FACT * (double(R) - Y);
            outputClass = 'double';
        case 'single'
            Y = ALPHA_R * double(R) + ALPHA_G * double(G) + ALPHA_B * double(B);
            Cb = CB_FACT * (double(B) - Y);
            Cr = CR_FACT * (double(R) - Y);
            Y = cast(Y, origClass);
            Cb = cast(Cb, origClass);
            Cr = cast(Cr, origClass);
            outputClass = 'single';
        case 'double'
            Y = ALPHA_R * double(R) + ALPHA_G * double(G) + ALPHA_B * double(B);
            Cb = CB_FACT * (double(B) - Y);
            Cr = CR_FACT * (double(R) - Y);
            outputClass = 'double';
        otherwise
            error('Class %s is not supported as input image', origClass);
    end
end
out = zeros(size(img), outputClass);
out(:, :, 1) = Y;
out(:, :, 2) = Cb;
out(:, :, 3) = Cr;
