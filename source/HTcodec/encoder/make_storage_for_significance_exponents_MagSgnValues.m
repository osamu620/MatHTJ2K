function [sigma, E, v, QW, QH] = make_storage_for_significance_exponents_MagSgnValues(codeblock_coeff, p)

X = codeblock_coeff;

[Hblk, Wblk] = size(X);

% compute magnitudes of sample X_n
mu = floor_quotient_int(abs(X), (2^p), 'int32');
% convert magnitudes into significance
significance = mu;
significance(significance > 0) = 1;
% retrieve signs: only for significant samples
s_n = sign(X) .* (-1);
s_n(s_n < 0) = 0;
s_n(mu == 0) = 0;

% compute magnitude exponents
original_E = int32(ceil(log2(double(mu)) + 1));
original_E(original_E == -Inf) = 0;

% compute MagSgn values (not aligned with quad scan pattern)
MagSgn = zeros(Hblk, Wblk, 'int32');
for i = 1:Hblk
    for j = 1:Wblk
        if mu(i, j) ~= 0
            MagSgn(i, j) = s_n(i, j) + 2 * (mu(i, j) - 1);
        end
    end
end

% padd an extra row or an extra row to codeblock
% if Hblk and/or Wblk are not divisible by 2
num_extra_row = 0;
num_extra_column = 0;
if mod(Hblk, 2)
    num_extra_row = 1;
end
if mod(Wblk, 2)
    num_extra_column = 1;
end
E_padded = zeros(Hblk + num_extra_row, Wblk + num_extra_column, 'uint8');
E_padded(1:Hblk, 1:Wblk) = original_E;
sigma_padded = zeros(Hblk + num_extra_row, Wblk + num_extra_column, 'uint8');
sigma_padded(1:Hblk, 1:Wblk) = significance;
v_padded = zeros(Hblk + num_extra_row, Wblk + num_extra_column, 'int32');
v_padded(1:Hblk, 1:Wblk) = MagSgn;

%
QH = ceil_quotient_int(Hblk, 2, 'int32');
QW = ceil_quotient_int(Wblk, 2, 'int32');

% make indices for scan order
idx = int32([1, 3; 2, 4]); % scan order inside a quad
nq = int32(4); % number of coeffs in a quad
count = int32(0);
indices = zeros(2 * QH, 2 * QW, 'int32');
for i = 1:QH
    top = (i - 1) * 2 + 1;
    bottom = i * 2;
    for j = 1:QW
        left = (j - 1) * 2 + 1;
        right = j * 2;
        indices(top:bottom, left:right) = idx + count;
        count = count + nq;
    end
end
% prepare final outputs
E = zeros(1, (Hblk + num_extra_row) * (Wblk + num_extra_column), 'uint8');
sigma = zeros(1, (Hblk + num_extra_row) * (Wblk + num_extra_column), 'uint8');
v = zeros(1, (Hblk + num_extra_row) * (Wblk + num_extra_column), 'int32');

% checking size
assert(size(E_padded, 1) == size(indices, 1) && size(E_padded, 2) == size(indices, 2))

% generate storage for exponents and significance
%debugOut = zeros(1, (Hblk+num_extra_row)*(Wblk+num_extra_column));
for i = 1:Hblk
    for j = 1:Wblk
        E(indices(i, j)) = E_padded(i, j);
        sigma(indices(i, j)) = sigma_padded(i, j);
        v(indices(i, j)) = v_padded(i, j);
        %debugOut(indices(i, j)) = X(i,j);
    end
end
