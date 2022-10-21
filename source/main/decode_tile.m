function time_for_blockcoding = decode_tile(currentTile, main_header, PPM_header, use_MEX, reduce_NL, time_for_blockcoding)
M_OFFSET = 1;

HT = uint16(64);

%% read packets
read_codestream(currentTile, main_header, PPM_header);

%% decoding
g_resolution_idx = uint16(0);
for c = 0:main_header.SIZ.Csiz - 1
    [~, codingStyleComponent] = get_coding_Styles(main_header, currentTile.header, c);
    % determine ROI shift value
    if isempty(currentTile.header.RGN) == false
        currentRGN = currentTile.header.RGN;
        if currentRGN.Crgn == c
            ROIshift = int32(currentRGN.SPrgn);
        else
            ROIshift = int32(0);
        end
    elseif isempty(main_header.RGN) == false
        currentRGN = main_header.RGN;
        if currentRGN.Crgn == c
            ROIshift = int32(currentRGN.SPrgn);
        else
            ROIshift = int32(0);
        end
    else
        ROIshift = int32(0);
    end

    NL = codingStyleComponent.get_number_of_decomposition_levels();
    for r = 0:NL
        currentResolution = currentTile.resolution(uint16(r) + g_resolution_idx + M_OFFSET);
        %if currentResolution.is_empty == false
        for b = 1:currentResolution.num_band
            currentSubband = currentResolution.subbandInfo(b);
            currentSubband.dwt_coeffs = zeros(currentSubband.size_y, currentSubband.size_x);
            for iPrecinctY = 0:currentResolution.numprecincthigh - 1
                for jPrecinctX = 0:currentResolution.numprecinctwide - 1
                    if isempty(currentResolution.precinct_resolution) == false
                        currentPrecinct = currentResolution.precinct_resolution(jPrecinctX + iPrecinctY * currentResolution.numprecinctwide + M_OFFSET);
                    else
                        currentPrecinct = [];
                    end
                    if isempty(currentPrecinct) == false %currentPband.size_x * currentPband.size_y ~= 0
                        currentPband = currentPrecinct.precinct_subbands(b);
                        if currentPband.numCblksX * currentPband.numCblksY ~= 0
                            for idx_y = 1:currentPband.numCblksY
                                for idx_x = 1:currentPband.numCblksX
                                    currentCodeblock = currentPband.Cblks((idx_y - 1) * currentPband.numCblksX + idx_x);
                                    time_start_blockcoding = tic;
                                    if bitand(currentCodeblock.Cmodes, HT) ~= 0

                                        %% HTJ2K decoding
                                        vCodeblock = v_codeblock_body(currentCodeblock);
                                        if use_MEX == true
                                            [q_b_bar, N_b] = HT_block_decode_mex(vCodeblock, ROIshift);
                                        else
                                            [q_b_bar, N_b] = HT_block_decode(vCodeblock, ROIshift); % non MEX
                                        end
                                        elapsed_time_blockcoding = toc(time_start_blockcoding);
                                    else

                                        %% J2K decoding
                                        vCodeblock = v_codeblock_body(currentCodeblock);
                                        if use_MEX == true
                                            [q_b_bar, N_b] = j2k_block_decoder_mex(vCodeblock, ROIshift);
                                        else
                                            [q_b_bar, N_b] = j2k_block_decoder(vCodeblock, ROIshift); % non MEX
                                        end
                                        elapsed_time_blockcoding = toc(time_start_blockcoding);
                                    end
                                    time_for_blockcoding = time_for_blockcoding + elapsed_time_blockcoding;

                                    %% Dequantization
                                    q_b_bar = double(q_b_bar);
                                    step_size = currentCodeblock.Delta_b;
                                    reconstruction_param = 0.5; %0.375;
                                    reconstruction_value = (reconstruction_param) * 2.^(double(currentCodeblock.M_b) - double(N_b)); %ones(size(q_b_bar));%

                                    % IF LOSSLESS, DO NOT DEQUANTIZE !!!
                                    % Eq. E-6 or E-8 in 15444-1
                                    if codingStyleComponent.get_transformation() == 1
                                        partially_decoded = q_b_bar(N_b < currentCodeblock.M_b);
                                        if isempty(partially_decoded) == false
                                            q_b_bar(partially_decoded > 0) = ...
                                                (q_b_bar(partially_decoded > 0) + reconstruction_value(partially_decoded > 0)) * step_size;
                                            q_b_bar(partially_decoded < 0) = ...
                                                (q_b_bar(partially_decoded < 0) - reconstruction_value(partially_decoded < 0)) * step_size;
                                        end
                                    else
                                        q_b_bar(q_b_bar > 0) = ...
                                            (q_b_bar(q_b_bar > 0) + reconstruction_value(q_b_bar > 0)) * step_size;
                                        q_b_bar(q_b_bar < 0) = ...
                                            (q_b_bar(q_b_bar < 0) - reconstruction_value(q_b_bar < 0)) * step_size;
                                    end
                                    pband_pos_y = currentCodeblock.pos_y;
                                    pband_pos_x = currentCodeblock.pos_x;
                                    currentPband.dwt_coeffs( ...
                                        pband_pos_y + M_OFFSET:pband_pos_y + int32(currentCodeblock.size_y), ...
                                        pband_pos_x + M_OFFSET:pband_pos_x + int32(currentCodeblock.size_x) ...
                                        ) = q_b_bar;
                                end % end of codeblock x loop
                            end % end of codeblock y loop
                        end % if currentPband.numCblksX * currentPband.numCblksY ~= 0 end
                        band_pos_y = currentPband.pos_y - currentSubband.pos_y;
                        band_pos_x = currentPband.pos_x - currentSubband.pos_x;
                        currentSubband.dwt_coeffs( ...
                            band_pos_y + M_OFFSET:band_pos_y + int32(currentPband.size_y), ...
                            band_pos_x + M_OFFSET:band_pos_x + int32(currentPband.size_x)) = currentPband.dwt_coeffs;
                    end % if isempty(currentPrecinct) == false end
                end % end of precinct x loop
            end % end of precinct y loop
        end % end of subband loop
        %end % end of is_empty resolution?
    end % end of resolution loop

    %% IDWT
    decoded_tile = idwt(currentTile, main_header, c, reduce_NL, use_MEX);
    currentTile.output{c+M_OFFSET} = decoded_tile;
    g_resolution_idx = g_resolution_idx + uint16(NL) + 1; % move to next component
end % end of component loop

% Prepare composite output
tmp_c_ysize = zeros(1, main_header.SIZ.Csiz);
tmp_c_xsize = zeros(1, main_header.SIZ.Csiz);
for c = 0:main_header.SIZ.Csiz - 1
    [tmp_c_ysize(c + M_OFFSET), tmp_c_xsize(c + M_OFFSET)] = size(currentTile.output{c + M_OFFSET});
end
c_ysize = max(tmp_c_ysize);
c_xsize = max(tmp_c_xsize);
for c = 0:main_header.SIZ.Csiz - 1
    if tmp_c_ysize(c + M_OFFSET) ~= c_ysize || tmp_c_xsize(c + M_OFFSET) ~= c_xsize
        tmp_c_img = imresize(currentTile.output{c + M_OFFSET}, [c_ysize, c_xsize]);
    else
        tmp_c_img = currentTile.output{c+M_OFFSET};
    end
    currentTile.composite_output(:, :, c + M_OFFSET) = tmp_c_img;
end

%% Inverse color transform to composite_outputs
header_COD = main_header.COD;
if isempty(currentTile.header.COD) == false
    header_COD = currentTile.header.COD;
end
if header_COD.get_multiple_component_transform() == 1
    if main_header.SIZ.Csiz < 3
        error('ERROR: Inverse color transform is required but number of components is not sufficent.');
    elseif main_header.SIZ.Csiz > 3
        currentTile.composite_output(:, :, 0 + M_OFFSET:2 + M_OFFSET) = ...
            myycbcr2rgb(currentTile.composite_output(:, :, 0 + M_OFFSET:2 + M_OFFSET), header_COD.get_transformation); %% mainCOD could be tilepart_COD
        currentTile.composite_output(:, :, 3 + M_OFFSET:main_header.SIZ.Csiz) = currentTile.composite_output(:, :, 3 + M_OFFSET:main_header.SIZ.Csiz);
    else
        currentTile.composite_output = myycbcr2rgb(currentTile.composite_output, header_COD.get_transformation); %% mainCOD could be tilepart_COD
    end
    currentTile.output{1} = currentTile.composite_output(:,:,1);
    currentTile.output{2} = currentTile.composite_output(:,:,2);
    currentTile.output{3} = currentTile.composite_output(:,:,3);
end
