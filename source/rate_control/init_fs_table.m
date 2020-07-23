function [fs_lossless, fs_lossy] = init_fs_table

M_OFFSET = 1;

DISTORTION_LSBS = 5;
SIGNIFICANCE_DISTORTIONS = 2^DISTORTION_LSBS;
DISTORTION_LUT_SCALE = 2^16;

fs_lossless = zeros(1, SIGNIFICANCE_DISTORTIONS);
fs_lossy = zeros(1, SIGNIFICANCE_DISTORTIONS);

for n = 0:SIGNIFICANCE_DISTORTIONS - 1
    val = 0.5 + bitor(n, 2^DISTORTION_LSBS);
    v_tilde = val / 2^DISTORTION_LSBS;
    assert(v_tilde >= 1.0 && v_tilde < 2.0);
    sqerr_before = v_tilde^2;
    sqerr_after1 = (v_tilde - 1.5)^2;
    sqerr_after2 = (v_tilde - 1.375)^2;
    sqerr_after = 0.75 * sqerr_after1 + 0.25 * sqerr_after2;

    fs_lossy(n + M_OFFSET) = DISTORTION_LUT_SCALE * (sqerr_before - sqerr_after);
    fs_lossless(n + M_OFFSET) = DISTORTION_LUT_SCALE * sqerr_before;
end