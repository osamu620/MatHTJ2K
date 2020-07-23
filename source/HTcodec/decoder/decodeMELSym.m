function s_mel = decodeMELSym(Dcup, Lcup, state_MEL, state_MEL_unPacker)

M_OFFSET = 1;

if state_MEL.MEL_run == 0 && state_MEL.MEL_one == 0
    eval = state_MEL.MEL_E(state_MEL.MEL_k + M_OFFSET);
    bit = importMELbit(Dcup, Lcup, state_MEL_unPacker);
    if bit == 1
        state_MEL.MEL_run = bitshift(1, eval);
        state_MEL.MEL_k = min(uint8(12), state_MEL.MEL_k + 1);
    else
        state_MEL.MEL_run = uint8(0);
        while eval > 0
            bit = importMELbit(Dcup, Lcup, state_MEL_unPacker);
            state_MEL.MEL_run = 2 * state_MEL.MEL_run + bit;
            eval = eval - uint8(1);
        end
        state_MEL.MEL_k = max(uint8(0), state_MEL.MEL_k - 1);
        state_MEL.MEL_one = uint8(1);
    end
end
if state_MEL.MEL_run > 0
    state_MEL.MEL_run = state_MEL.MEL_run - 1;
    s_mel = int32(0);
else
    state_MEL.MEL_one = uint8(0);
    s_mel = int32(1);
end