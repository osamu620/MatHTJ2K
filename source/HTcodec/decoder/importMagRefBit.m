function bit = importMagRefBit(state_MR_dec)
M_OFFSET = 1;
x8F = uint8(143);
x7F = uint8(127);
if state_MR_dec.MR_bits == uint8(0)
    if state_MR_dec.MR_pos >= 0
        state_MR_dec.MR_tmp = state_MR_dec.Dref(state_MR_dec.MR_pos + M_OFFSET);
        state_MR_dec.MR_pos = state_MR_dec.MR_pos -1;
    else
        state_MR_dec.MR_tmp = uint8(0);
    end
    state_MR_dec.MR_bits = uint8(8);
    if (state_MR_dec.MR_last > x8F) && (bitand(state_MR_dec.MR_tmp, x7F) == x7F)
        state_MR_dec.MR_bits = uint8(7);
    end
    state_MR_dec.MR_last = state_MR_dec.MR_tmp;
end
bit = bitand(state_MR_dec.MR_tmp, 1);
state_MR_dec.MR_tmp = bitshift(state_MR_dec.MR_tmp, -1);
state_MR_dec.MR_bits = state_MR_dec.MR_bits -1;
