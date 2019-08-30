function indices = makeQuadScanorder(QW, QH)

% make indices for scan order
idx = [1 3; 2 4]; % scan order inside a quad
nq = 4;% number of coeffs in a quad
count = 0;
indices = zeros(2*QH, 2*QW, 'int32');
for i=1:QH
    top = (i-1)*2+1;
    bottom = i*2;
    for j=1:QW
        left = (j-1)*2+1;
        right = j*2;
        indices(top:bottom,left:right) = idx + count;
        count = count + nq;
    end
end