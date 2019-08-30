function termSPPacker(state_SP_enc)

M_OFFSET = 1;
x_FF = uint8(255);

if state_SP_enc.SP_tmp ~= 0
    state_SP_enc.SP_buf(state_SP_enc.SP_pos + M_OFFSET) = state_SP_enc.SP_tmp;
    state_SP_enc.SP_pos = state_SP_enc.SP_pos + 1;
    if state_SP_enc.SP_tmp == x_FF
        state_SP_enc.SP_max = 7;
    else
        state_SP_enc.SP_max = 8;
    end
    if state_SP_enc.SP_max == 7
        state_SP_enc.SP_buf(state_SP_enc.SP_pos + M_OFFSET) = 0;
        state_SP_enc.SP_pos = state_SP_enc.SP_pos + 1;
    end
end