function [MS_buf] = termMSPacker(MS_buf, state_MS)

M_OFFSET = 1;
x_FF = uint8(255);

if state_MS.MS_bits > 0
    while state_MS.MS_bits < state_MS.MS_max
        state_MS.MS_tmp = bitor(state_MS.MS_tmp, bitshift(uint8(1), state_MS.MS_bits));
        state_MS.MS_bits = state_MS.MS_bits + 1;
    end
    if state_MS.MS_tmp ~= x_FF
        MS_buf(state_MS.MS_pos+M_OFFSET) = state_MS.MS_tmp;
        state_MS.MS_pos = state_MS.MS_pos + 1;
    end
elseif state_MS.MS_max == uint8(7)
    state_MS.MS_pos = state_MS.MS_pos - 1; % this discards an already emitted trailing FF
end