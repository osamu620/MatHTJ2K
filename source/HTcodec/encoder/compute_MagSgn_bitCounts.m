function m = compute_MagSgn_bitCounts(rho, U, iemb_k, q)

M_OFFSET = 1;

k0 = bitshift(bitand(iemb_k(q + M_OFFSET), 2^0), 0);
k1 = bitshift(bitand(iemb_k(q + M_OFFSET), 2^1), -1);
k2 = bitshift(bitand(iemb_k(q + M_OFFSET), 2^2), -2);
k3 = bitshift(bitand(iemb_k(q + M_OFFSET), 2^3), -3);

s0 = bitshift(bitand(rho(q + M_OFFSET), 2^0), 0);
s1 = bitshift(bitand(rho(q + M_OFFSET), 2^1), -1);
s2 = bitshift(bitand(rho(q + M_OFFSET), 2^2), -2);
s3 = bitshift(bitand(rho(q + M_OFFSET), 2^3), -3);

m = zeros(1, 4, class(U));
m(1) = s0 * U(q + M_OFFSET) - k0;
m(2) = s1 * U(q + M_OFFSET) - k1;
m(3) = s2 * U(q + M_OFFSET) - k2;
m(4) = s3 * U(q + M_OFFSET) - k3;