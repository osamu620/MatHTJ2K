function [refine_indicator, refine_val] = HT_MagRef_decode(sigma, refine_indicator, refine_val, state_MR_dec)

[H_blk, W_blk] = size(sigma);
num_v_stripe = floor(H_blk/4);

i_start = 1;

height = 4;

for n1 = 1:num_v_stripe
    for j = 1:W_blk
        for i = i_start:i_start + height - 1
            [refine_indicator(i,j), refine_val(i,j)] = ...
                decodeMagRefValue(state_MR_dec, sigma(i,j), refine_indicator(i,j), refine_val(i,j));
        end
    end
    i_start = i_start + height;
end

height = mod(H_blk, 4);

for j = 1:W_blk
    for i = i_start:i_start + height - 1
        [refine_indicator(i,j), refine_val(i,j)] = ...
            decodeMagRefValue(state_MR_dec, sigma(i,j), refine_indicator(i,j), refine_val(i,j));
    end
end
