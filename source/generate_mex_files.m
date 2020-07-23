% A script to generate MEX files
nameoffuncinMATLABCoder = 'codegen';
patternforregexp = '(?<=^.+[\\/]toolbox[\\/])[^\\/]+';
if isempty(regexp(which(nameoffuncinMATLABCoder), patternforregexp, 'match', 'once'))
    error('MATLAB Coder is not installed on this system.');
end

fprintf('Generating fdwt_2d_sd_mex ...\n');
fdwt_2d_sd_script
cd ../
fprintf('Generating idwt_2d_sd_mex ...\n');
idwt_2d_sr_script
cd ../
fprintf('Generating j2k_block_decoder_mex ...\n');
j2k_block_decoder_script
cd ../
fprintf('Generating j2k_block_encoder_v_mex ...\n');
j2k_block_encoder_v_script
cd ../
fprintf('Generating HT_block_decode_mex ...\n');
HT_block_decode_script
cd ../../
fprintf('Generating HT_block_encode_mex ...\n');
HT_block_encode_script
cd ../../

clear nameoffuncinMATLABCoder patternforregexp;