% FDWT_2D_SD_SCRIPT   Generate MEX-function fdwt_2d_sd_mex from fdwt_2d_sd.
%
% Script generated from project 'fdwt_2d_sd.prj' on 23-Jul-2020.
%
% See also CODER, CODER.CONFIG, CODER.TYPEOF, CODEGEN.

%% Create configuration object of class 'coder.MexCodeConfig'.
cfg = coder.config('mex');
cfg.RowMajor = true;
cfg.GenerateReport = true;
cfg.ReportPotentialDifferences = false;
cfg.IntegrityChecks = false;
cfg.ResponsivenessChecks = false;
cfg.ExtrinsicCalls = false;
cfg.GlobalDataSyncMethod = 'NoSync';

%% Define argument types for entry-point 'fdwt_2d_sd'.
ARGS = cell(1, 1);
ARGS{1} = cell(6, 1);
ARGS{1}{1} = coder.typeof(0, [Inf, Inf], [1, 1]);
ARGS{1}{2} = coder.typeof(int32(0));
ARGS{1}{3} = coder.typeof(int32(0));
ARGS{1}{4} = coder.typeof(int32(0));
ARGS{1}{5} = coder.typeof(int32(0));
ARGS{1}{6} = coder.typeof(uint8(0));

%% Invoke MATLAB Coder.
cd('/Users/osamu/Documents/MatHTJ2K/source/dwt');
codegen -config cfg fdwt_2d_sd -args ARGS{1} -nargout 4
