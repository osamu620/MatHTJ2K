function [sw, w, sf, f, n, ne, nw, nf] = retrieve_neighbouring_significance_pattern(sigma, q, QW)
% Retrieve neighbouring significance patterns from a significance pattern
% for an entire codeblock.
%
% outputs are:
%              [sw, w, sf, f, ~, ~, ~, ~] for initial line-pairs,
%              [sw, w, ~, ~, n, ne, nw, nf] for non-initial line-pairs.

%sigma = uint8(sigma);
M_OFFSET = 1;

if q < QW % initial line-pair
    if q > 0
        sw = sigma(4*q-1+M_OFFSET);
        w = sigma(4*q-2+M_OFFSET);
        sf = sigma(4*q-3+M_OFFSET);
        f = sigma(4*q-4+M_OFFSET);
    else
        sw = uint8(0);
        w = uint8(0);
        sf = uint8(0);
        f = uint8(0);
    end
    n = uint8(0);  % no need for initial line-pair
    ne = uint8(0); % no need for initial line-pair
    nw = uint8(0); % no need for initial line-pair
    nf = uint8(0); % no need for initial line-pair
else % non-initial line-pair
    n = sigma(4*(q-QW)+1+M_OFFSET);
    ne = sigma(4*(q-QW)+3+M_OFFSET);
    if mod(q, QW)
        nw = sigma(4*(q-QW)-1+M_OFFSET);
        sw = sigma(4*q-1+M_OFFSET);
        w = sigma(4*q-2+M_OFFSET);
    else
        nw = uint8(0);
        sw = uint8(0);
        w = uint8(0);
    end
    if mod(q+1, QW)
        nf = sigma(4*(q-QW)+5+M_OFFSET);
    else
        nf = uint8(0);
    end
    sf = uint8(0); % no need for non-initial line-pair
    f = uint8(0);  % no need for non-initial line-pair
end