function bit = importVLCBit(Dcup, Pcup, Lcup, state_VLC_dec)

x_8F = uint8(143);
x_7F = uint8(127);

if state_VLC_dec.VLC_bits == uint8(0)
    if state_VLC_dec.VLC_pos >= Pcup
        state_VLC_dec.VLC_tmp = modDcup(Dcup, state_VLC_dec.VLC_pos, Lcup);
    else
        error('impoertVLCBit line 10');
    end
    state_VLC_dec.VLC_bits = uint8(8);
    if (state_VLC_dec.VLC_last > x_8F) && (bitand(state_VLC_dec.VLC_tmp, x_7F) == x_7F)
        state_VLC_dec.VLC_bits = uint8(7);
    end
    state_VLC_dec.VLC_last = state_VLC_dec.VLC_tmp;
    state_VLC_dec.VLC_pos = state_VLC_dec.VLC_pos - 1;
end
bit = int32(bitand(state_VLC_dec.VLC_tmp, uint8(1)));
state_VLC_dec.VLC_tmp = bitshift(state_VLC_dec.VLC_tmp , -1);
state_VLC_dec.VLC_bits = state_VLC_dec.VLC_bits - uint8(1);