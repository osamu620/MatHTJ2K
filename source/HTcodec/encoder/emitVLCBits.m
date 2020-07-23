function [VLC_buf] = emitVLCBits(cwd, len, VLC_buf, state_VLC)

M_OFFSET = 1;
x_8F = uint8(143);
x_7F = uint8(127);

while len > 0
    bit = bitand(cwd, int32(1));
    cwd = bitshift(cwd, -1);
    len = len - 1;
    state_VLC.VLC_tmp = bitor(state_VLC.VLC_tmp, uint8(bitshift(bit, state_VLC.VLC_bits)));
    state_VLC.VLC_bits = state_VLC.VLC_bits + 1;
    if (state_VLC.VLC_last > x_8F) && (state_VLC.VLC_tmp == x_7F)
        state_VLC.VLC_bits = state_VLC.VLC_bits + 1;
    end
    if state_VLC.VLC_bits == uint8(8)
        VLC_buf(state_VLC.VLC_pos + M_OFFSET) = state_VLC.VLC_tmp;
        state_VLC.VLC_pos = state_VLC.VLC_pos + 1;
        state_VLC.VLC_last = state_VLC.VLC_tmp;
        state_VLC.VLC_tmp = uint8(0);
        state_VLC.VLC_bits = uint8(0);
    end
end