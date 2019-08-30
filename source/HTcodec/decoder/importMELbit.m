function bit = importMELbit(Dcup, Lcup, state_MEL_unPacker)

x_FF = uint8(255);

if state_MEL_unPacker.MEL_bits == int8(0)
    if state_MEL_unPacker.MEL_tmp == x_FF
        state_MEL_unPacker.MEL_bits = int8(7);
    else
        state_MEL_unPacker.MEL_bits = int8(8);
    end
    if state_MEL_unPacker.MEL_pos < Lcup
        state_MEL_unPacker.MEL_tmp = modDcup(Dcup, state_MEL_unPacker.MEL_pos, Lcup);
        state_MEL_unPacker.MEL_pos = state_MEL_unPacker.MEL_pos + 1;
    else
        state_MEL_unPacker.MEL_tmp = x_FF;
    end
end
state_MEL_unPacker.MEL_bits = state_MEL_unPacker.MEL_bits - int8(1);
bit = bitand(bitshift(state_MEL_unPacker.MEL_tmp, -state_MEL_unPacker.MEL_bits), uint8(1));% <- this "-state_MEL_unPacker.MEL_bits" is the reason MEL_bis should be int8

