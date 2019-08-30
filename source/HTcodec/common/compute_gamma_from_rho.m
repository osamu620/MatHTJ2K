function gamma = compute_gamma_from_rho(rho)

if rho == 0 || rho == 1 || rho == 2 || rho == 4 || rho == 8 %ismember(rho, [0 1 2 4 8])
    gamma = int32(0);
else
    gamma = int32(1);
end


