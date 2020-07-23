function [z_n, r_n] = decodeSigPropMag(state_SP_dec, sigma_n, z_n, r_n, N, N_tilda)

N = N(:);
N_tilda = N_tilda(:);

mbr = int32(0);
if sigma_n == 0
    for i = 1:length(N)
        mbr = bitor(mbr, N(i));
    end
    for i = 1:length(N_tilda)
        mbr = bitor(mbr, N_tilda(i));
    end
end
if mbr ~= 0
    z_n = int32(1);
    r_n = int32(importSigPropBit(state_SP_dec));
end
