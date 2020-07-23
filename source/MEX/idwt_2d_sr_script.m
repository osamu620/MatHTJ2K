% IDWT_2D_SR_SCRIPT   Generate MEX-function idwt_2d_sr_mex from idwt_2d_sr.
%
% Script generated from project 'idwt_2d_sr.prj' on 23-Jul-2020.
%
% See also CODER, CODER.CONFIG, CODER.TYPEOF, CODEGEN.

%% Create configuration object of class 'coder.MexCodeConfig'.
cfg = coder.config('mex');
cfg.GenerateReport = true;
cfg.ReportPotentialDifferences = false;
cfg.IntegrityChecks = false;
cfg.ResponsivenessChecks = false;
cfg.ExtrinsicCalls = false;
cfg.GlobalDataSyncMethod = 'NoSync';

%% Define argument types for entry-point 'idwt_2d_sr'.
ARGS = cell(1, 1);
ARGS{1} = cell(9, 1);
ARGS{1}{1} = coder.typeof(0, [Inf, Inf], [1, 1]);
ARGS{1}{2} = coder.typeof(0, [Inf, Inf], [1, 1]);
ARGS{1}{3} = coder.typeof(0, [Inf, Inf], [1, 1]);
ARGS{1}{4} = coder.typeof(0, [Inf, Inf], [1, 1]);
ARGS{1}{5} = coder.typeof(int32(0));
ARGS{1}{6} = coder.typeof(int32(0));
ARGS{1}{7} = coder.typeof(int32(0));
ARGS{1}{8} = coder.typeof(int32(0));
ARGS{1}{9} = coder.typeof(uint8(0));

%% Invoke MATLAB Coder.
cd('./dwt');
codegen -config cfg idwt_2d_sr -args ARGS{1} -nargout 1
