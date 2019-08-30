function [z_n, r_n] = decodeMagRefValue(state_MR_dec, sigma_n, z_n, r_n)

if sigma_n ~= 0
    z_n = int32(1);
    r_n = int32(importMagRefBit(state_MR_dec));
end
