function kappa = form_exponent_predictors(E, gamma, q, QW)

M_OFFSET = 1;

E_n = E(4 * (q - QW) + 1 + M_OFFSET);
E_ne = E(4 * (q - QW) + 3 + M_OFFSET);
if mod(q, QW)
    E_nw = E(4 * (q - QW) - 1 + M_OFFSET);
else
    E_nw = uint8(0);
end
if mod(q + 1, QW)
    E_nf = E(4 * (q - QW) + 5 + M_OFFSET);
else
    E_nf = uint8(0);
end

kappa = max(int32(1), int32(gamma) * max(int32([E_nw, E_n, E_ne, E_nf])) - 1);
