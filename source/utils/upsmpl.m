function out=upsmpl(in,N)

[ty, tx]=size(in);
out = zeros(1, max(ty, tx)*N);

out(1:N:end)=in;
