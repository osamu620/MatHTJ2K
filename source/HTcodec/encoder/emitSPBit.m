function emitSPBit(bit, state_SP_enc)

x_FF = uint8(255);
M_OFFSET = 1;

state_SP_enc.SP_tmp = bitor(state_SP_enc.SP_tmp, bitshift(uint8(bit), state_SP_enc.SP_bits));
state_SP_enc.SP_bits = state_SP_enc.SP_bits + 1;
if state_SP_enc.SP_bits == state_SP_enc.SP_max
    state_SP_enc.SP_buf(state_SP_enc.SP_pos + M_OFFSET) = state_SP_enc.SP_tmp;
    state_SP_enc.SP_pos = state_SP_enc.SP_pos + 1;

    if state_SP_enc.SP_tmp == x_FF
        state_SP_enc.SP_max = 7;
    else
        state_SP_enc.SP_max = 8;
    end
    state_SP_enc.SP_tmp = 0;
    state_SP_enc.SP_bits = 0;
end
