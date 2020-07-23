function out = getScanCausalNeighbours(dummy_in, i, j, dummy_scan)

state = dummy_scan(i:i + 2, j:j + 2);
tmp = dummy_in(i:i + 2, j:j + 2);
out = tmp .* state;

end
