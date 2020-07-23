function HT_MagRef_encode(bitplane, sigma_n, state_MR_enc)

[H_blk, W_blk] = size(sigma_n);
num_v_stripe = floor(H_blk / 4);

i_start = 1;

height = 4;

for n1 = 1:num_v_stripe
    for j = 1:W_blk
        for i = i_start:i_start + height - 1
            if sigma_n(i, j) ~= 0
                emitMRBit(bitplane(i, j), state_MR_enc);
            end
        end
    end
    i_start = i_start + height;
end

height = mod(H_blk, 4);

for j = 1:W_blk
    for i = i_start:i_start + height - 1
        if sigma_n(i, j) ~= 0
            emitMRBit(bitplane(i, j), state_MR_enc);
        end
    end
end
