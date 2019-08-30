function log_slope = slope_to_log(lambda)

max_slope = 2^64;
log_scale = 256.0 / log(2.0);
log_slope = lambda / max_slope;
if log_slope > 1.0
    log_slope = 1.0;
end

log_slope = (log(log_slope) * log_scale) + 2^16;

if log_slope > 2^16 - 1
    log_slope = 2^16 - 1;
elseif log_slope < 2.0
    log_slope = 2;
end

log_slope = uint16(log_slope);
