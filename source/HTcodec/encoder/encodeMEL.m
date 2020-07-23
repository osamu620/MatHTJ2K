function [MEL_buf] = encodeMEL(s_mel_q, m_mel_q, MEL_buf, state_MEL, state_MELPacker)

M_OFFSET = 1;

MEL_E = get_MEL_exponent_table;

if m_mel_q == 1
    if s_mel_q == 0
        state_MEL.MEL_run = state_MEL.MEL_run + 1;
        if state_MEL.MEL_run >= state_MEL.MEL_t
            MEL_buf = emitMELBit(1, MEL_buf, state_MELPacker);
            state_MEL.MEL_run = uint8(0);
            state_MEL.MEL_k = min(uint8(12), state_MEL.MEL_k + 1);
            eval = MEL_E(state_MEL.MEL_k + M_OFFSET);
            state_MEL.MEL_t = bitshift(1, eval);
        end
    else
        MEL_buf = emitMELBit(0, MEL_buf, state_MELPacker);
        eval = MEL_E(state_MEL.MEL_k + M_OFFSET);
        while eval > uint8(0)
            eval = eval - 1;
            msb = bitand(bitshift(state_MEL.MEL_run, -eval), uint8(1));
            MEL_buf = emitMELBit(msb, MEL_buf, state_MELPacker);
        end
        state_MEL.MEL_run = uint8(0);
        state_MEL.MEL_k = max(0, state_MEL.MEL_k - 1);
        eval = MEL_E(state_MEL.MEL_k + M_OFFSET);
        state_MEL.MEL_t = bitshift(1, eval);
    end
end