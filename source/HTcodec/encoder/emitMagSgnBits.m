function [MS_buf] = emitMagSgnBits(v_n, m_n, MS_buf, state_MS)

M_OFFSET = 1;
x_FF = uint8(255);

val = v_n;
len = m_n;

while len > 0
    bit = uint8(bitand(val, int32(1)));
    val = bitshift(val, -1);
    len = len - 1;
    state_MS.MS_tmp = bitor(state_MS.MS_tmp, uint8(bitshift(bit, state_MS.MS_bits)));
    state_MS.MS_bits = state_MS.MS_bits + 1;
    if state_MS.MS_bits == state_MS.MS_max
        MS_buf(state_MS.MS_pos + M_OFFSET) = state_MS.MS_tmp;
        state_MS.MS_pos = state_MS.MS_pos + 1;
        if state_MS.MS_tmp == x_FF
            state_MS.MS_max = uint8(7);
        else
            state_MS.MS_max = uint8(8);
        end
        state_MS.MS_tmp = uint8(0);
        state_MS.MS_bits = uint8(0);
    end
end
