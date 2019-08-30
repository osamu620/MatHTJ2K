function u_sfx = decodeUSuffix(u_pfx, Dcup, Pcup, Lcup, state_VLC_dec)

if u_pfx < 3
    u_sfx = uint8(0);
    return;
end
val = importVLCBit(Dcup, Pcup, Lcup, state_VLC_dec);
if u_pfx == 3
    u_sfx = uint8(val);
    return;
end
for i=1:5-1
    bit = importVLCBit(Dcup, Pcup, Lcup, state_VLC_dec);
    val = val + bitshift(bit, i);
end
u_sfx = uint8(val);
return;