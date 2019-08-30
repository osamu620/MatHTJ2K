function s_n = decodeSigPropSign(state_SP_dec, r_n, s_n)

if r_n ~= 0
    s_n = int32(importSigPropBit(state_SP_dec));
end
