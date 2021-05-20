function truncate_codestream(hTile, main_header, g_target_rate)
DEBUG = 0;
M_OFFSET = 1;

estimated_size = zeros(1, 2048);
quant_slope_rates = zeros(2048, 1);
g_min_quant_slope = 2047;
g_max_quant_slope = 0;
total_bytes = 0;

%% find truncation points
for c = 0:main_header.SIZ.Csiz - 1
    [codingStyle, codingStyleComponent] = get_coding_Styles(main_header, hTile.header, c);
    NL = codingStyleComponent.get_number_of_decomposition_levels();
    for r = 0:NL
        cr = findobj(hTile.resolution, 'idx', r, '-and', 'idx_c', c);
        if cr.is_empty == false
            for iPrecinctY = 0:cr.numprecincthigh - 1
                for jPrecinctX = 0:cr.numprecinctwide - 1
                    currentPrecinct = cr.precinct_resolution(jPrecinctX + iPrecinctY * cr.numprecinctwide + M_OFFSET);
                    for b = 1:cr.num_band
                        cpb = currentPrecinct.precinct_subbands(b);
                        for idx_y = 1:cpb.numCblksY
                            for idx_x = 1:cpb.numCblksX
                                hCodeblock = cpb.Cblks(idx_x + (idx_y - 1) * cpb.numCblksX);
                                if hCodeblock.Cmodes < 64
                                    if hCodeblock.num_passes > 0
                                        len = 0;

                                        min_quant_slope = 2047;
                                        max_quant_slope = 0;
                                        for n = 1:hCodeblock.num_passes
                                            len = len + hCodeblock.pass_length(n);
                                            if hCodeblock.RD_slope(n) == 0
                                                continue;
                                            end
                                            quant_slope = floor_quotient_int(hCodeblock.RD_slope(n), 16, 'double') - 2048;
                                            if quant_slope < min_quant_slope
                                                if quant_slope < 0
                                                    quant_slope = 0;
                                                end
                                                min_quant_slope = quant_slope;
                                            end
                                            if quant_slope > max_quant_slope
                                                max_quant_slope = quant_slope;
                                            end
                                            assert((quant_slope >= 0) && (quant_slope < 2048));
                                            quant_slope_rates(quant_slope + M_OFFSET) = quant_slope_rates(quant_slope + M_OFFSET) + len;
                                            len = 0;
                                        end
                                        if min_quant_slope < g_min_quant_slope && min_quant_slope ~= 0
                                            g_min_quant_slope = min_quant_slope;
                                        end
                                        if max_quant_slope > g_max_quant_slope
                                            g_max_quant_slope = max_quant_slope;
                                        end
                                        if DEBUG == 1
                                            fprintf('min_q_slope = %4d, max_q_slope = %4d\n', min_quant_slope, max_quant_slope);
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

%% calculate estimated threshold of slope
qslope_idx = 2048:-1:1;
qslope_sum = cumsum(quant_slope_rates(end:-1:1));
for i = 1:2048
    estimated_size(qslope_idx(i)) = qslope_sum(i);
end

total_bytes = 0;
target_rate = g_target_rate;
bit_depth = double(main_header.SIZ.get_RI());
for c = 0:main_header.SIZ.Csiz - 1
    total_bytes = total_bytes + hTile.tile_size_x * hTile.tile_size_y * bit_depth(c + M_OFFSET) / 8;
end

% determine number of tiles
numTiles_x = ceil_quotient_int((main_header.SIZ.Xsiz - main_header.SIZ.XTOsiz), main_header.SIZ.XTsiz, 'double');
numTiles_y = ceil_quotient_int((main_header.SIZ.Ysiz - main_header.SIZ.YTOsiz), main_header.SIZ.YTsiz, 'double');

total_bytes_of_packet_header = double(main_header.get_length()) / (numTiles_x * numTiles_y);
is_finish = false;

num_layers = codingStyle.get_number_of_layers();

while is_finish == false
    if total_bytes_of_packet_header > main_header.get_length() / (numTiles_x * numTiles_y)
        is_finish = true;
    end
    target_bytes = total_bytes * (target_rate / sum(bit_depth)) - total_bytes_of_packet_header;

    q_l1 = find(estimated_size >= target_bytes, 1, 'last') - M_OFFSET;
    q_l2 = find(estimated_size <= target_bytes, 1, 'first') - M_OFFSET;
    if q_l1 == q_l2
        q_l2 = q_l2 + 1;
    end

    estimated_threshold = ((q_l1 + q_l2) / 2 + 2048) * 16 - M_OFFSET;

    %% truncation
    for c = 0:main_header.SIZ.Csiz - 1
        [codingStyle, codingStyleComponent] = get_coding_Styles(main_header, hTile.header, c);
        NL = codingStyleComponent.get_number_of_decomposition_levels();
        for r = 0:NL
            cr = findobj(hTile.resolution, 'idx', r, '-and', 'idx_c', c);
            if cr.is_empty == false
                for iPrecinctY = 0:cr.numprecincthigh - 1
                    for jPrecinctX = 0:cr.numprecinctwide - 1
                        currentPrecinct = cr.precinct_resolution(jPrecinctX + iPrecinctY * cr.numprecinctwide + M_OFFSET);
                        for b = 1:cr.num_band
                            cpb = currentPrecinct.precinct_subbands(b);
                            for idx_y = 1:cpb.numCblksY
                                for idx_x = 1:cpb.numCblksX

                                    %% raster index is for tagtree decoding
                                    rasterCblkIdx = idx_x + (idx_y - 1) * cpb.numCblksX;
                                    hCodeblock = cpb.Cblks(idx_x + (idx_y - 1) * cpb.numCblksX);
                                    CB_BYPASS = bitand(hCodeblock.Cmodes, 1);
                                    CB_RESTART = bitshift(bitand(hCodeblock.Cmodes, 4), -2);
                                    vCodeblock = v_codeblock_body(hCodeblock);
                                    if hCodeblock.num_passes > 0 && hCodeblock.Cmodes < 64 && codingStyleComponent.get_transformation() == 0
                                        if estimated_threshold ~= 0
                                            % find final truncation point
                                            if length(hCodeblock.truncation_points) > 1
                                                tp = find(hCodeblock.RD_slope >= estimated_threshold, 1, 'last');
                                            else
                                                tp = [];
                                            end
                                        else
                                            tp = hCodeblock.num_passes;
                                        end
                                        if isempty(tp) == false
                                            if tp ~= hCodeblock.num_passes

                                                %% termination of codeword segments, if necessary
                                                mq_reg_enc = mq_enc;
                                                mq_reg_enc.go_reg_snap_shot(hCodeblock, tp);
                                                mq_reg_enc.byte_stream = hCodeblock.compressed_data(1:sum(hCodeblock.pass_length(1:tp)));

                                                % Cmode detection
                                                if CB_RESTART == false
                                                    if CB_BYPASS == false % normal mode
                                                        mq_reg_enc.L = length(mq_reg_enc.byte_stream);
                                                        Lstart = mq_reg_enc.L;
                                                        mq_reg_enc.mq_encoder_end();
                                                        Lstop = mq_reg_enc.L;
                                                        hCodeblock.pass_length(tp) = hCodeblock.pass_length(tp) + Lstop - Lstart;
                                                    elseif mod(tp - 10, 3) == 1 % BYPASS mode without RESTART; only sigprop pass shall be terminated
                                                        mq_reg_enc.L = length(mq_reg_enc.byte_stream);
                                                        Lstart = mq_reg_enc.L;
                                                        mq_reg_enc.raw_termination();
                                                        Lstop = mq_reg_enc.L;
                                                        hCodeblock.pass_length(tp) = hCodeblock.pass_length(tp) + Lstop - Lstart;
                                                    end
                                                end

                                                hCodeblock.num_passes = tp;
                                                hCodeblock.pass_length = hCodeblock.pass_length(1:tp);

                                                %% make output
                                                hCodeblock.compressed_data = mq_reg_enc.byte_stream;
                                                hCodeblock.length = length(hCodeblock.compressed_data);
                                            end
                                        else
                                            hCodeblock.num_passes = 0;
                                            hCodeblock.length = 0;
                                            hCodeblock.compressed_data = [];
                                        end
                                    end

                                    if hCodeblock.num_passes > 0
                                        if hCodeblock.Cmodes < 64
                                            % J2K Part 1
                                            target_bytes = total_bytes * (target_rate / sum(bit_depth)) - total_bytes_of_packet_header;
                                            layer_bytes_delta = double(target_bytes) / double(num_layers);
                                            layer_bytes = 0;

                                            for l = 0:num_layers - 1
                                                layer_bytes = layer_bytes + layer_bytes_delta;
                                                l_q_l1 = find(estimated_size >= layer_bytes, 1, 'last') - M_OFFSET;
                                                l_q_l2 = find(estimated_size <= layer_bytes, 1, 'first') - M_OFFSET;

                                                if l_q_l1 == l_q_l2
                                                    l_q_l2 = l_q_l2 + 1;
                                                end

                                                if isempty(l_q_l1) == true
                                                    l_q_l1 = l_q_l2;
                                                end
                                                estimated_layer_threshold = ((l_q_l1 + l_q_l2) / 2 + 2048) * 16 - M_OFFSET; % - 1;

                                                if l == num_layers - 1 % the last layer shall include the rest of compressed data.
                                                    tlp = hCodeblock.num_passes;
                                                else
                                                    tlp = find(hCodeblock.RD_slope >= estimated_layer_threshold, 1, 'last');
                                                end

                                                if isempty(tlp) == true
                                                    tlp = 0;
                                                end

                                                assert(tlp <= hCodeblock.num_passes);

                                                if l == 0
                                                    hCodeblock.layer_passes(l + M_OFFSET) = tlp;
                                                    hCodeblock.layer_start(l + M_OFFSET) = 0;
                                                else
                                                    hCodeblock.layer_passes(l + M_OFFSET) = tlp - sum(hCodeblock.layer_passes(1:l));
                                                    hCodeblock.layer_start(l + M_OFFSET) = sum(hCodeblock.layer_passes(1:l));
                                                end

                                            end
                                        else
                                            % HTJ2K
                                            hCodeblock.layer_passes(1) = hCodeblock.num_passes;
                                            hCodeblock.layer_start(1) = 0;
                                        end
                                    else
                                        hCodeblock.layer_passes(hCodeblock.layer_passes ~= 0) = 0;
                                        hCodeblock.layer_start(hCodeblock.layer_start ~= 0) = 0;
                                    end

                                    %% for inclusion tagtree
                                    current_node = findobj(cpb.inclusionInfo.node, 'idx', rasterCblkIdx);
                                    l_num_first_contribution = find(hCodeblock.layer_passes ~= 0, 1, 'first') - 1;
                                    if isempty(l_num_first_contribution) == true
                                        % if no passes contribute to any layers, then the codeblock won't be included.
                                        % to signal this, a value for inclusion tagtree node is set to num_layers(=l);
                                        % because layer index is from 0 to l-1.
                                        current_node.value = num_layers;
                                    else
                                        current_node.value = l_num_first_contribution;
                                    end

                                    current_node.is_set = true;

                                    %% for ZBP tagtree
                                    current_node = findobj(cpb.ZBPInfo.node, 'idx', rasterCblkIdx);
                                    current_node.value = hCodeblock.num_ZBP;

                                    current_node.is_set = true;

                                    %% when no contribution
                                    if hCodeblock.num_passes > 0
                                        cpb.is_zero_length = false;
                                    end
                                    if is_finish == false && hCodeblock.Cmodes < 64
                                        hCodeblock.copy_from_vCodeblock(vCodeblock);
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    total_bytes_of_packet_header = total_bytes_of_packet_header + simulate_packet(hTile, main_header);
end
