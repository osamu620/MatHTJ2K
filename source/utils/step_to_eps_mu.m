function [exponent, mu] = step_to_eps_mu(w, base_step_size, w_b)

if nargin < 3
    w_b = 1;
end

exponent = 0;
mu = 0;

fval = base_step_size / (sqrt(w) * w_b);

assert(fval > 0.0);

while fval < 1.0
    exponent = exponent + 1;
    fval = fval * 2.0;
end

mu = floor((fval - 1.0) * 2^11 + 0.5);

if mu >= 2^11
    mu = 0;
    exponent = exponent - 1;
end
if exponent > 31
    exponent = 31;
    mu = 0;
end
if exponent < 0
    exponent = 0;
    mu = 2^11 - 1;
end

fval = (1.0 + mu * (1.0 / 2^11)) * (1 / 2^(exponent));

exponent = int32(exponent);
mu = int32(mu);