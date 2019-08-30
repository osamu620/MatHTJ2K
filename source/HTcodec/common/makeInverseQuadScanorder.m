function out = makeInverseQuadScanorder(in, QW, QH, isquad)

if isquad == true
    A = uint16(1);
    B = uint16(2);
else
    A = uint16(2);
    B = uint16(1);
end

% convert scanning order
forward = reshape(makeQuadScanorder(QW/B,QH/B),1,A*QW*A*QH);

tmp = zeros(1, length(in), class(in));
for i = 1:length(in)
    tmp(i) = in(forward(i));
end
out = reshape(tmp,A*QH,A*QW);