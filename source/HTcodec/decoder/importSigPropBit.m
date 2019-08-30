function bit = importSigPropBit(state_SP_dec)

x_FF = uint8(255);
M_OFFSET = 1;

Lref = length(state_SP_dec.Dref);
if state_SP_dec.SP_bits == uint8(0)
    if state_SP_dec.SP_last == x_FF
        state_SP_dec.SP_bits = uint8(7);
    else
        state_SP_dec.SP_bits = uint8(8);
    end
    if state_SP_dec.SP_pos < Lref
        state_SP_dec.SP_tmp = state_SP_dec.Dref(state_SP_dec.SP_pos + M_OFFSET);
        state_SP_dec.SP_pos = state_SP_dec.SP_pos + 1;
        if bitand(uint16(state_SP_dec.SP_tmp), bitshift(uint16(1), state_SP_dec.SP_bits)) ~= 0
            error('importSigPropBit line 17');
        end
    else
        state_SP_dec.SP_tmp = uint8(0);
    end
    state_SP_dec.SP_last = state_SP_dec.SP_tmp;
end
bit = bitand(state_SP_dec.SP_tmp, 1);
state_SP_dec.SP_tmp = bitshift(state_SP_dec.SP_tmp, -1);
state_SP_dec.SP_bits = state_SP_dec.SP_bits - 1;
        