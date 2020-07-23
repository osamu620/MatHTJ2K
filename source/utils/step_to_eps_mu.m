function [eps, mu] = step_to_eps_mu(w, base_step_size)
eps = 0;
mu = 0;

fval = base_step_size / sqrt(w);

assert(fval > 0.0);

while fval < 1.0
    eps = eps + 1;
    fval = fval * 2.0;
end

mu = floor((fval - 1.0) * 2^11 + 0.5);

if mu >= 2^11
    mu = 0;
    eps = eps - 1;
end
if eps > 31
    eps = 31;
    mu = 0;
end
if eps < 0
    eps = 0;
    mu = 2^11 - 1;
end

fval = (1.0 + mu * (1.0 / 2^11)) * (1 / 2^(eps));

eps = int32(eps);
mu = int32(mu);