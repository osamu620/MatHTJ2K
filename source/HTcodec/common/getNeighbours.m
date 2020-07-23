function out = getNeighbours(dummy_in, i, j)
% below 2 lines are very time consuming when using mex
%    [m,n] = size(dummy_in);
%    assert(m <= 130 && n <= 130 && m*n <= 4356);

out = dummy_in(i:i + 2, j:j + 2);
out(2, 2) = 0;
