function emitMRBit(bit, state_MR_enc)

x_8F = uint8(143);
x_7F = uint8(127);
M_OFFSET = 1;

state_MR_enc.MR_tmp = bitor(state_MR_enc.MR_tmp, bitshift(uint8(bit), state_MR_enc.MR_bits));
state_MR_enc.MR_bits = state_MR_enc.MR_bits + 1;
if state_MR_enc.MR_last > x_8F && state_MR_enc.MR_tmp == x_7F
    state_MR_enc.MR_bits = state_MR_enc.MR_bits + 1;
end
if state_MR_enc.MR_bits == 8
    state_MR_enc.MR_buf(state_MR_enc.MR_pos + M_OFFSET) = state_MR_enc.MR_tmp;
    state_MR_enc.MR_pos = state_MR_enc.MR_pos + 1;
    state_MR_enc.MR_last = state_MR_enc.MR_tmp;
    state_MR_enc.MR_tmp = 0;
    state_MR_enc.MR_bits = 0;
end
