function [U, u, u_off, eps_bar] = compute_magnitudeExponent_residual_EMBpattern(E, q, kappa)

M_OFFSET = 1;

E_quad = E(4*q+M_OFFSET:4*(q+1));
epsilon = zeros(1, 4, 'int32');
E_max = max([E_quad(1) E_quad(2) E_quad(3) E_quad(4)]);

% magnitude exponent
U = max(int32(E_max), int32(kappa));% cast kappa to int32

% residual
u = U - int32(kappa);% cast kappa to int32
if u == 0
    u_off = 0;
else
    u_off = 1;
end
epsilon(E_quad==E_max) = u_off;

% EMB pattern
eps_bar = sum(epsilon .* int32([1 2 4 8]));
