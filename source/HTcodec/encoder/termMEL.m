function [MEL_buf] = termMEL(MEL_buf, state_MEL, state_MELPacker)
% This function is one of the suggested corrections to DIS text.

if state_MEL.MEL_run > uint8(0)
    MEL_buf = emitMELBit(1, MEL_buf, state_MELPacker);
end