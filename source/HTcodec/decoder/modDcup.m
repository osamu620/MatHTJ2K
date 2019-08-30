function value = modDcup(Dcup, pos, Lcup)

M_OFFSET = 1;
x_0F = uint8(15);
x_FF = uint8(255);


if pos == Lcup - 1 % if pos is at the end of Dcup
    value = x_FF;
elseif pos == Lcup - 2 % if pos is at the second end of Dcup
    value = bitor(Dcup(pos+M_OFFSET), x_0F);
else % otherwise
    value = Dcup(pos+M_OFFSET);
end