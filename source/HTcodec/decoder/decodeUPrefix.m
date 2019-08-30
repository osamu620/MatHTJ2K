function u_pfx = decodeUPrefix(Dcup, Pcup, Lcup, state_VLC_dec)

bit = importVLCBit(Dcup, Pcup, Lcup, state_VLC_dec);
if bit == 1
    u_pfx = uint8(1);
    return;
end
bit = importVLCBit(Dcup, Pcup, Lcup, state_VLC_dec);
if bit == 1
    u_pfx = uint8(2);
    return;
end
bit = importVLCBit(Dcup, Pcup, Lcup, state_VLC_dec);
if bit == 1
    u_pfx = uint8(3);
    return;
else
    u_pfx = uint8(5);
    return;
end