function [MEL_buf, VLC_buf] = termMELandVLCPackers(MEL_buf, VLC_buf, state_MELPacker, state_VLC)

M_OFFSET = 1;
x_FF = uint8(255);

state_MELPacker.MEL_tmp = bitshift(state_MELPacker.MEL_tmp, state_MELPacker.MEL_rem);

MEL_mask = bitand(bitshift(x_FF, state_MELPacker.MEL_rem), x_FF); % if MEL_rem is 8, MEL_mask = 0
VLC_mask = bitshift(x_FF, -(8 - state_VLC.VLC_bits)); % if VLC_bits is 0, VLC_mask = 0

if bitor(MEL_mask, VLC_mask) == 0
    return; % last MEL byte cannot be FF, since then MEL rem would be < 8
end

fuse = bitor(state_MELPacker.MEL_tmp, state_VLC.VLC_tmp);

if (bitor( ...
        bitand(bitxor(fuse, state_MELPacker.MEL_tmp), MEL_mask), ...
        bitand(bitxor(fuse, state_VLC.VLC_tmp), VLC_mask) ...
        ) == 0) && (fuse ~= x_FF)
    MEL_buf(state_MELPacker.MEL_pos + M_OFFSET) = fuse;
else
    MEL_buf(state_MELPacker.MEL_pos + M_OFFSET) = state_MELPacker.MEL_tmp;
    VLC_buf(state_VLC.VLC_pos + M_OFFSET) = state_VLC.VLC_tmp;
    state_VLC.VLC_pos = state_VLC.VLC_pos + 1;
end
state_MELPacker.MEL_pos = state_MELPacker.MEL_pos + 1;
