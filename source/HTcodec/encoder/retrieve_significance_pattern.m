function rho = retrieve_significance_pattern(sigma, q)

M_OFFSET = 1;

% significances inside a quad
sigma_quad = sigma(4*q+M_OFFSET:4*(q+1));

% retrieve significance pattern
rho = sum(sigma_quad .* uint8([1 2 4 8]));