function [s, refine_indicator, refine_val] = HT_SigProp_decode(s_sigma, s, CB_CAUSAL, state_SP_dec)

% input sigma is re-ordered with raster-based scan, we have to consider it.
[H_blk, W_blk] = size(s_sigma);
refine_val = zeros(H_blk, W_blk, 'int32');
refine_indicator = zeros(H_blk, W_blk, 'int32');

dummy_sigma = zeros(H_blk+2, W_blk+2, 'int32');
dummy_sigma(2:end-1, 2:end-1) = s_sigma; % make dummy for getting neighbours easily

dummy_r = zeros(H_blk+2, W_blk+2, 'int32');
dummy_r(2:end-1, 2:end-1) = refine_val; % make dummy for getting neighbours easily

state_scan = zeros(H_blk, W_blk, 'int32');
dummy_scan = zeros(H_blk+2, W_blk+2, 'int32');
dummy_scan(2:end-1, 2:end-1) = state_scan; % make dummy for getting neighbours easily

num_v_stripe = floor(H_blk/4);
num_h_stripe = floor(W_blk/4);

i_start = 1;
width = 4;
height = 4;
for n1 = 1:num_v_stripe
    j_start = 1;
    for n2 = 1:num_h_stripe
        for j = j_start:j_start + width - 1
            for i = i_start:i_start + height - 1
                N = dummy_sigma(i:i+2, j:j+2);
                if CB_CAUSAL == true
                    N(3, :) = 0;
                end
                N_tilda = getScanCausalNeighbours(dummy_r, i, j , dummy_scan);
                [refine_indicator(i,j), refine_val(i,j)] = decodeSigPropMag(state_SP_dec, s_sigma(i,j), ...
                    refine_indicator(i,j), refine_val(i,j), N, N_tilda);
                dummy_r(2:end-1, 2:end-1) = refine_val;
                state_scan(i,j) = 1;
                dummy_scan(2:end-1, 2:end-1) = state_scan;
            end
        end
        for j = j_start:j_start + width - 1
            for i = i_start:i_start + height - 1
                s_n = decodeSigPropSign(state_SP_dec, refine_val(i,j), s(i,j));
                s(i,j) = s_n;
            end
        end
        j_start = j_start + 4;
    end
    %
    width_last = mod(W_blk, 4);
    if width_last ~= 0
        for j = j_start:j_start + width_last - 1
            for i = i_start:i_start + height - 1
                N = dummy_sigma(i:i+2, j:j+2);
                if CB_CAUSAL == true
                    N(3, :) = 0;
                end
                N_tilda = getScanCausalNeighbours(dummy_r, i, j , dummy_scan);
                [refine_indicator(i,j), refine_val(i,j)] = decodeSigPropMag(state_SP_dec, s_sigma(i,j), ...
                    refine_indicator(i,j), refine_val(i,j), N, N_tilda);
                dummy_r(2:end-1, 2:end-1) = refine_val;
                state_scan(i,j) = 1;
                dummy_scan(2:end-1, 2:end-1) = state_scan;
            end
        end
        for j = j_start:j_start + width_last - 1
            for i = i_start:i_start + height - 1
                s_n = decodeSigPropSign(state_SP_dec, refine_val(i,j), s(i,j));
                s(i,j) = s_n;
            end
        end
    end
    i_start = i_start + 4;
end

height = mod(H_blk, 4);
j_start = 1;
for n2 = 1:num_h_stripe
    for j = j_start:j_start + width - 1
        for i = i_start:i_start + height - 1
            N = dummy_sigma(i:i+2, j:j+2);
            if CB_CAUSAL == true
                N(3, :) = 0;
            end
            N_tilda = getScanCausalNeighbours(dummy_r, i, j , dummy_scan);
            [refine_indicator(i,j), refine_val(i,j)] = decodeSigPropMag(state_SP_dec, s_sigma(i,j), ...
                refine_indicator(i,j), refine_val(i,j), N, N_tilda);
            dummy_r(2:end-1, 2:end-1) = refine_val;
            state_scan(i,j) = 1;
            dummy_scan(2:end-1, 2:end-1) = state_scan;
        end
    end
    for j = j_start:j_start + width - 1
        for i = i_start:i_start + height - 1
            s_n = decodeSigPropSign(state_SP_dec, refine_val(i,j), s(i,j));
            s(i,j) = s_n;
        end
    end
    j_start = j_start + 4;
end
%
width_last = mod(W_blk, 4);
if width_last ~= 0
    for j = j_start:j_start + width_last - 1
        for i = i_start:i_start + height - 1
            N = dummy_sigma(i:i+2, j:j+2);
            if CB_CAUSAL == true
                N(3, :) = 0;
            end
            N_tilda = getScanCausalNeighbours(dummy_r, i, j , dummy_scan);
            [refine_indicator(i,j), refine_val(i,j)] = decodeSigPropMag(state_SP_dec, s_sigma(i,j), ...
                refine_indicator(i,j), refine_val(i,j), N, N_tilda);
            dummy_r(2:end-1, 2:end-1) = refine_val;
            state_scan(i,j) = 1;
            dummy_scan(2:end-1, 2:end-1) = state_scan;
        end
    end
    for j = j_start:j_start + width_last - 1
        for i = i_start:i_start + height - 1
            s_n = decodeSigPropSign(state_SP_dec, refine_val(i,j), s(i,j));
            s(i,j) = s_n;
        end
    end
end