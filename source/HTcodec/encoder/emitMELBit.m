function [MEL_buf] = emitMELBit(bit, MEL_buf, state_MELPacker)

M_OFFSET = 1;
x_FF = uint8(255);

state_MELPacker.MEL_tmp = 2 * state_MELPacker.MEL_tmp + bit;
state_MELPacker.MEL_rem = state_MELPacker.MEL_rem - 1;
if state_MELPacker.MEL_rem == uint8(0)
    MEL_buf(state_MELPacker.MEL_pos + M_OFFSET) = state_MELPacker.MEL_tmp;
    state_MELPacker.MEL_pos = state_MELPacker.MEL_pos + 1;
    if state_MELPacker.MEL_tmp == x_FF
        state_MELPacker.MEL_rem = uint8(7);
    else
        state_MELPacker.MEL_rem = uint8(8);
    end
    state_MELPacker.MEL_tmp = uint8(0);
end