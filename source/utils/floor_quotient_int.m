function out = floor_quotient_int(in0, in1, className)

d_in0 = cast(in0, 'double');
d_in1 = cast(in1, 'double');
out = cast(floor(d_in0 / d_in1), className);
%out = cast(floor(double(in0)/double(in1)), className);