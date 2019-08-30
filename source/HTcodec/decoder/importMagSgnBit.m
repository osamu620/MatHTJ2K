function bit = importMagSgnBit(Dcup, Pcup, Lcup, state_MS_dec)

x_FF = uint8(255);

if state_MS_dec.MS_bits == uint8(0)
    if state_MS_dec.MS_last == x_FF
        state_MS_dec.MS_bits = uint8(7);
    else
        state_MS_dec.MS_bits = uint8(8);
    end
    if state_MS_dec.MS_pos < Pcup
        state_MS_dec.MS_tmp = modDcup(Dcup, state_MS_dec.MS_pos, Lcup);
        if bitand(uint16(state_MS_dec.MS_tmp), bitshift(uint16(1), state_MS_dec.MS_bits)) ~= 0
            error('importMagSgnBit line 15');
        end
    elseif state_MS_dec.MS_pos == Pcup
        state_MS_dec.MS_tmp = x_FF;
    else
        error('importMagSgnBit line 20, MS_pos = %d, Pcup = %d\n', state_MS_dec.MS_pos, Pcup);
    end
    state_MS_dec.MS_last = state_MS_dec.MS_tmp;
    state_MS_dec.MS_pos = state_MS_dec.MS_pos + 1;
end
bit = bitand(state_MS_dec.MS_tmp, uint8(1));
state_MS_dec.MS_tmp = bitshift(state_MS_dec.MS_tmp, -1);
state_MS_dec.MS_bits = state_MS_dec.MS_bits - uint8(1);
        