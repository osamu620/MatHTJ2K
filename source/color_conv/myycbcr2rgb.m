function out = myycbcr2rgb(input, transformation)
%MYRGB2YCBCR - converts YCbCr to RGB as defined in BT.601
% "studio swing" (range adjustment) won't be perfomred.
% usage: out = myycbcr2rgb(input, <reversible (true or false(default))> );

if nargin < 2
    transformation = 0;
end

[~, ~, c] = size(input);
if c ~= 3
    error('input YCbCr shall have 3 components.');
end

Y = input(:, :, 1);
Cb = input(:, :, 2);
Cr = input(:, :, 3);

ALPHA_R = 0.299;
ALPHA_B = 0.114;
ALPHA_RB = (ALPHA_R + ALPHA_B);
ALPHA_G = (1 - ALPHA_RB);
CR_FACT_R = (2 * (1 - ALPHA_R));
CB_FACT_B = (2 * (1 - ALPHA_B));
CR_FACT_G = (2 * ALPHA_R * (1 - ALPHA_R) / ALPHA_G);
CB_FACT_G = (2 * ALPHA_B * (1 - ALPHA_B) / ALPHA_G);


origClass = class(input);

if transformation == 1 % Reversible Color Transform
    switch origClass
        case {'int16', 'int32'}
            Y = int32(Y);
            Cb = int32(Cb);
            Cr = int32(Cr);
            G = Y - bitshift((Cb + Cr), -2);
            R = G + Cr;
            B = G + Cb;
            outputClass = 'int32';
        case {'single', 'double'}
            G = Y - floor((Cb + Cr) / 4);
            R = G + Cr;
            B = G + Cb;
            outputClass = origClass;
        otherwise
            error('Reversible color inverse transform can be applied only for uint8, uint16, int32, single and double inputs.');
    end
else % Irreversible Color Transform as defiend in BT.601
    switch origClass
        case {'int16'}
            CR_FACT_R14 = int32(0.5 + CR_FACT_R * bitshift(1, 14));
            CB_FACT_B14 = int32(0.5 + CB_FACT_B * bitshift(1, 14));
            CR_FACT_G14 = int32(0.5 + CR_FACT_G * bitshift(1, 14));
            CB_FACT_G14 = int32(0.5 + CB_FACT_G * bitshift(1, 14));
            Y = int32(Y);
            Cb = int32(Cb);
            Cr = int32(Cr);
            Y = bitshift(Y, 14);
            R = Y + CR_FACT_R14 * Cr;
            B = Y + CB_FACT_B14 * Cb;
            G = Y - CR_FACT_G14 * Cr - CB_FACT_G14 * Cb;

            R = int16(bitshift(R + bitshift(1, 13), -14));
            G = int16(bitshift(G + bitshift(1, 13), -14));
            B = int16(bitshift(B + bitshift(1, 13), -14));
            outputClass = 'int16';
        case {'uint32', 'int32'}
            Y = double(Y);
            Cb = double(Cb);
            Cr = double(Cr);
            R = Y + CR_FACT_R * Cr;
            B = Y + CB_FACT_B * Cb;
            G = Y - CR_FACT_G * Cr - CB_FACT_G * Cb;
            outputClass = 'double';
        case 'single'
            Y = double(Y);
            Cb = double(Cb);
            Cr = double(Cr);
            R = Y + CR_FACT_R * Cr;
            B = Y + CB_FACT_B * Cb;
            G = Y - CR_FACT_G * Cr - CB_FACT_G * Cb;
            R = cast(R, origClass);
            G = cast(G, origClass);
            B = cast(B, origClass);
            outputClass = 'single';
        case 'double'
            R = Y + CR_FACT_R * Cr;
            B = Y + CB_FACT_B * Cb;
            G = Y - CR_FACT_G * Cr - CB_FACT_G * Cb;
            outputClass = 'double';
        otherwise
            error('Class %s is not supported as an input', origClass);
    end
end
out = zeros(size(input), outputClass);
out(:, :, 1) = R;
out(:, :, 2) = G;
out(:, :, 3) = B;
