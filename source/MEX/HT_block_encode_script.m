% HT_BLOCK_ENCODE_SCRIPT   Generate MEX-function HT_block_encode_mex from
%  HT_block_encode.
%
% Script generated from project 'HT_block_encode.prj' on 23-Jul-2020.
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

%% Define argument types for entry-point 'HT_block_encode'.
ARGS = cell(1, 1);
ARGS{1} = cell(3, 1);
ARGS{1}{1} = coder.typeof(int32(0), [1024, 1024], [1, 1]);
ARGS{1}{2} = coder.typeof(int32(0));
ARGS{1}{3} = coder.typeof(uint16(0));

%% Invoke MATLAB Coder.
cd('/Users/osamu/Documents/MatHTJ2K/source/HTcodec/encoder');
codegen -config cfg HT_block_encode -args ARGS{1} -nargout 3
