function [compressed_data, num_passes, pass_length] = HT_block_encode(quantized_coeffs, p, CB_CAUSAL) %#codegen

pass_length = zeros(1, 3, 'int32');

%% HT Cleanup encoding
[Dcup, sigma_quad, QW, QH] = HT_Cleanup_encode(quantized_coeffs, p);
compressed_data = Dcup;
num_passes = 1;
pass_length(1) = length(Dcup);

if p > 0 % if p == 0, no Magref segment is generated.
    %% HT SigProp and MagRef encoding
    bitplane = bitshift(bitand(abs(quantized_coeffs), 2^(p-1)), -(p-1));
    sigma_stripe = makeInverseQuadScanorder(sigma_quad, uint16(QW), uint16(QH), false);
    sigma_stripe = sigma_stripe(1:size(bitplane,1), 1:size(bitplane,2));% remove padded coeffs for building quads for HT cleanup pass
    sign_stripe = sign(quantized_coeffs);
    sign_stripe(sign_stripe > 0) = 0;
    sign_stripe(sign_stripe < 0) = 1;
    
    state_SP = state_SP_enc;
    HT_SigProp_encode(bitplane, sigma_stripe, sign_stripe, CB_CAUSAL, state_SP);
    num_passes = num_passes + 1;
    
    Det = int32(sigma_stripe) .* bitplane;% Can skip MagRef? TODO
    %termSPPacker(state_SP);
    
    state_MR = state_MR_enc;
    HT_MagRef_encode(bitplane, sigma_stripe, state_MR);
    num_passes = num_passes + 1;
    
    termSPandMRPackers(state_SP, state_MR);
    pass_length(2) = state_SP.SP_pos;
    pass_length(3) = state_MR.MR_pos;
    
    Dref = [state_SP.SP_buf(1:state_SP.SP_pos) fliplr(state_MR.MR_buf(1:state_MR.MR_pos))];
    compressed_data = [compressed_data Dref];
end
assert(num_passes >= 1);
pass_length = pass_length(1:num_passes);