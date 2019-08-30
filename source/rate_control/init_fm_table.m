function [fm_lossless, fm_lossy] = init_fm_table

M_OFFSET = 1;

DISTORTION_LSBS = 5;
REFINEMENT_DISTORTIONS = 2^(DISTORTION_LSBS+1);
DISTORTION_LUT_SCALE = 2^16;

fm_lossless = zeros(1, REFINEMENT_DISTORTIONS);
fm_lossy    = zeros(1, REFINEMENT_DISTORTIONS);

for n = 0:REFINEMENT_DISTORTIONS - 1
    v_tilde = (0.5 + n)/2^DISTORTION_LSBS;
    assert(v_tilde < 2.0);
    sqerr_before1 = (v_tilde - 1.0)^2;
    sqerr_before2 = (v_tilde - 0.75)^2;
    sqerr_before = 0.75*sqerr_before1 + 0.25*sqerr_before2;
    
    if bitshift(n, -DISTORTION_LSBS) > 0
        v_tilde = v_tilde - 1.0;
    end
    assert(v_tilde >= 0.0 && v_tilde < 1.0);
    sqerr_after1 = (v_tilde - 0.5)^2;
    sqerr_after2 = (v_tilde - 0.375)^2;
    sqerr_after = 0.75*sqerr_after1 + 0.25*sqerr_after2;
    
    fm_lossy(n + M_OFFSET) = DISTORTION_LUT_SCALE * (sqerr_before - sqerr_after);
    fm_lossless(n + M_OFFSET) = DISTORTION_LUT_SCALE * sqerr_before;
end