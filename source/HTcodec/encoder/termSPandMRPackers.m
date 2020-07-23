function termSPandMRPackers(state_SP, state_MR)

M_OFFSET = 1;

x_FF = int32(255);
x_80 = int32(128);

SP_mask = bitshift(x_FF, -(8 - int32(state_SP.SP_bits)));
SP_mask = bitor(SP_mask, bitand(bitshift(1, int32(state_SP.SP_max)), x_80));
MR_mask = bitshift(x_FF, -(8 - int32(state_MR.MR_bits)));

if bitor(SP_mask, MR_mask) == 0
    return;
end

fuse = int32(bitor(state_SP.SP_tmp, state_MR.MR_tmp));

if bitor(bitand((bitxor(fuse, int32(state_SP.SP_tmp))), SP_mask), ...
        bitand((bitxor(fuse, int32(state_MR.MR_tmp))), MR_mask)) == 0
    state_SP.SP_buf(state_SP.SP_pos + M_OFFSET) = fuse;
else
    state_SP.SP_buf(state_SP.SP_pos + M_OFFSET) = state_SP.SP_tmp;
    state_MR.MR_buf(state_MR.MR_pos + M_OFFSET) = state_MR.MR_tmp;
    state_MR.MR_pos = state_MR.MR_pos + 1;
end
state_SP.SP_pos = state_SP.SP_pos + 1;