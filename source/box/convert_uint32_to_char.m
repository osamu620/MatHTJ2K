function out = convert_uint32_to_char(in)

assert(isa(in, 'uint32'));

tmp(4) = bitand(in, 255);
in = bitshift(in, -8);
tmp(3) = bitand(in, 255);
in = bitshift(in, -8);
tmp(2) = bitand(in, 255);
in = bitshift(in, -8);
tmp(1) = bitand(in, 255);

out = char(tmp);