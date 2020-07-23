function find_feasible_truncation_points(hCodeblock)

M_OFFSET = 1;

assert(length(hCodeblock.pass_length) == length(hCodeblock.distortion_changes));

pass_slopes = zeros(1, hCodeblock.num_passes);
pass_log_slopes = zeros(1, hCodeblock.num_passes);

ALGORITHM = 0; % you can add your own algorithm for RD optimization
switch ALGORITHM
    case 0
        for z = 0:int8(hCodeblock.num_passes) - 1
            delta_L = 0.0;
            delta_D = 0.0;
            z_prime = z;
            while true
                delta_L = delta_L + double(hCodeblock.pass_length(z_prime + M_OFFSET));
                delta_D = delta_D + hCodeblock.distortion_changes(z_prime + M_OFFSET);
                z_prime = z_prime - 1;
                if delta_D <= 0.0
                    % this pass cannot contribute to convex hull
                    pass_log_slopes(z + M_OFFSET) = 0;
                    break;
                end
                if z_prime < 0
                    assert(delta_L > 0.0);
                    pass_slopes(z + M_OFFSET) = delta_D / delta_L;
                    pass_log_slopes(z + M_OFFSET) = slope_to_log(pass_slopes(z + M_OFFSET));
                    break;
                end
                if pass_log_slopes(z_prime + M_OFFSET) == 0
                    continue;
                end
                if delta_L == 0.0 || pass_slopes(z_prime + M_OFFSET) * delta_L <= delta_D
                    pass_log_slopes(z_prime + M_OFFSET) = 0;
                else
                    pass_slopes(z + M_OFFSET) = delta_D / delta_L;
                    pass_log_slopes(z + M_OFFSET) = slope_to_log(pass_slopes(z + M_OFFSET));
                    if pass_log_slopes(z + M_OFFSET) >= pass_log_slopes(z_prime + M_OFFSET)
                        pass_log_slopes(z_prime + M_OFFSET) = 0;
                    end
                    break;
                end
            end
        end
        hCodeblock.RD_slope = pass_log_slopes;
        if hCodeblock.is_reversible == true && hCodeblock.num_passes > 0 && hCodeblock.pass_idx == hCodeblock.num_passes
            if hCodeblock.RD_slope(hCodeblock.num_passes) == 0
                hCodeblock.RD_slope(hCodeblock.num_passes) = 1;
            end
        end
        hCodeblock.truncation_points = find(pass_log_slopes ~= 0);
end