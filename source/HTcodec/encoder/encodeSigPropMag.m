function mbr = encodeSigPropMag(bit, sigma_n, N, N_tilda, state_SP_enc)

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
    emitSPBit(bit, state_SP_enc);
end
