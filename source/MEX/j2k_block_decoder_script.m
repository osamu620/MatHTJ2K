% J2K_BLOCK_DECODER_SCRIPT   Generate MEX-function j2k_block_decoder_mex from
%  j2k_block_decoder.
%
% Script generated from project 'j2k_block_decoder.prj' on 23-Jul-2020.
%
% See also CODER, CODER.CONFIG, CODER.TYPEOF, CODEGEN.

%% Create configuration object of class 'coder.MexCodeConfig'.
cfg = coder.config('mex');
cfg.RowMajor = true;
cfg.FilePartitionMethod = 'SingleFile';
cfg.GenerateReport = true;
cfg.ReportPotentialDifferences = false;
cfg.IntegrityChecks = false;
cfg.ResponsivenessChecks = false;
cfg.ExtrinsicCalls = false;
cfg.GlobalDataSyncMethod = 'NoSync';

%% Define argument types for entry-point 'j2k_block_decoder'.
ARGS = cell(1, 1);
ARGS{1} = cell(2, 1);
ARGS{1}{1} = coder.newtype('v_codeblock_body');
ARGS{1}{1}.Properties.length = coder.typeof(uint32(0));
ARGS{1}{1}.Properties.idx_x = coder.typeof(uint32(0));
ARGS{1}{1}.Properties.idx_y = coder.typeof(uint32(0));
ARGS{1}{1}.Properties.pos_x = coder.typeof(int32(0));
ARGS{1}{1}.Properties.pos_y = coder.typeof(int32(0));
ARGS{1}{1}.Properties.size_x = coder.typeof(uint16(0));
ARGS{1}{1}.Properties.size_y = coder.typeof(uint16(0));
ARGS{1}{1}.Properties.idx_c = coder.typeof(uint16(0));
ARGS{1}{1}.Properties.num_passes = coder.typeof(uint8(0));
ARGS{1}{1}.Properties.LBlock = coder.typeof(int32(0));
ARGS{1}{1}.Properties.num_ZBP = coder.typeof(uint8(0));
ARGS{1}{1}.Properties.already_included = coder.typeof(false);
ARGS{1}{1}.Properties.band_idx = coder.typeof(uint8(0));
ARGS{1}{1}.Properties.precinct_idx = coder.typeof(uint32(0));
ARGS{1}{1}.Properties.resolution_idx = coder.typeof(uint8(0));
ARGS{1}{1}.Properties.component_idx = coder.typeof(uint8(0));
ARGS{1}{1}.Properties.Cmodes = coder.typeof(uint16(0));
ARGS{1}{1}.Properties.fast_skip_passes = coder.typeof(uint8(0));
ARGS{1}{1}.Properties.layer_start = coder.typeof(uint32(0), [1, 65535], [0, 1]);
ARGS{1}{1}.Properties.layer_passes = coder.typeof(uint32(0), [1, 65535], [0, 1]);
ARGS{1}{1}.Properties.compressed_data = coder.typeof(uint8(0), [1, 16384], [0, 1]);
ARGS{1}{1}.Properties.quantized_coeffs = coder.typeof(int32(0), [1024, 1024], [1, 1]);
ARGS{1}{1}.Properties.N_b = coder.typeof(int32(0), [1024, 1024], [1, 1]);
ARGS{1}{1}.Properties.dwt_coeffs = coder.typeof(0, [1024, 1024], [1, 1]);
ARGS{1}{1}.Properties.M_b = coder.typeof(uint8(0));
ARGS{1}{1}.Properties.W_b = coder.typeof(0);
ARGS{1}{1}.Properties.Delta_b = coder.typeof(0);
ARGS{1}{1}.Properties.normalized_delta = coder.typeof(0);
ARGS{1}{1}.Properties.pass_length = coder.typeof(int32(0), [1, 165], [0, 1]);
ARGS{1}{1}.Properties.pass_idx = coder.typeof(int32(0), [1, 165], [0, 1]);
ARGS{1}{1}.Properties.distortion_changes = coder.typeof(0, [1, 165], [0, 1]);
ARGS{1}{1}.Properties.truncation_points = coder.typeof(uint8(0), [1, 165], [0, 1]);
ARGS{1}{1}.Properties.RD_slope = coder.typeof(uint16(0), [1, 165], [0, 1]);
ARGS{1}{1}.Properties.is_reversible = coder.typeof(false);
ARGS{1}{1}.Properties.mq_C = coder.typeof(uint32(0), [1, 165], [0, 1]);
ARGS{1}{1}.Properties.mq_A = coder.typeof(uint16(0), [1, 165], [0, 1]);
ARGS{1}{1}.Properties.mq_t = coder.typeof(int16(0), [1, 165], [0, 1]);
ARGS{1}{1}.Properties.mq_T = coder.typeof(uint8(0), [1, 165], [0, 1]);
ARGS{1}{1}.Properties.mq_L = coder.typeof(int32(0), [1, 165], [0, 1]);
ARGS{1}{2} = coder.typeof(int32(0));

%% Invoke MATLAB Coder.
cd('./Tier1');
codegen -config cfg j2k_block_decoder -args ARGS{1} -nargout 2
