function u_ext = decodeUExtension(u_sfx, Dcup, Pcup, Lcup, state_VLC_dec)

if u_sfx < 28
    u_ext = uint8(0);
    return;
end

val = importVLCBit(Dcup, Pcup, Lcup, state_VLC_dec);
for i=1:4-1
    bit = importVLCBit(Dcup, Pcup, Lcup, state_VLC_dec);
    val = val + bitshift(bit, i);
end
u_ext = uint8(val);
return;