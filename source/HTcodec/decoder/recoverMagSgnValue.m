function [E_n, mu_n, s_n, v_n] = recoverMagSgnValue(m, known_1, Dcup, Pcup, Lcup, state_MS_dec)

v_n = decodeMagSgnValue(m, known_1, Dcup, Pcup, Lcup, state_MS_dec);
if m ~= 0
    mu_n = floor_quotient_int(v_n, 2, 'uint32') + uint32(1);
    s_n = uint8(mod(v_n, 2));
else
    mu_n = uint32(0);
    s_n = uint8(0);
end

% compute magnitude exponents
if mu_n ~= 0
    E_n = uint32(ceil(log2(double(mu_n))+1));
else
    E_n = uint32(0);
end