function [rho, u_off, emb_k, emb_1] = decodeSigEMB(context, Dcup, Pcup, Lcup, state_MEL, state_MEL_unPacker, state_VLC_dec, dec_CxtVLC_table)

if context == 0
    sym = decodeMELSym(Dcup, Lcup, state_MEL, state_MEL_unPacker);
    if sym == 0
        rho = int32(0); u_off = int32(0); emb_k = int32(0); emb_1 = int32(0);
        return;
    end
end
[rho, u_off, emb_k, emb_1] = decodeCxtVLC(context, Dcup, Pcup, Lcup, state_VLC_dec, dec_CxtVLC_table);
return;