function state_VLC = initVLC(Dcup, Lcup)

last = modDcup(Dcup, Lcup-2, Lcup);
tmp  = bitshift(last, -4);
if bitand(tmp, 7) < 7
    bits = 4;
else
    bits = 3;
end
% create handle class
state_VLC = state_VLC_dec(Lcup - 3, last, tmp, bits); 