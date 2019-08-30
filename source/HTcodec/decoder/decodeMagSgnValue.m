function v_n = decodeMagSgnValue(m_n, i_n, Dcup, Pcup, Lcup, state_MS_dec)

val = uint32(0);
if m_n > 0
    for i=0:m_n-1
        bit = importMagSgnBit(Dcup, Pcup, Lcup, state_MS_dec);
        val = val + bitshift(uint32(bit), i);
    end
    val = val + uint32(bitshift(int32(i_n), m_n));
else
    val = uint32(0);
end
v_n = val;
