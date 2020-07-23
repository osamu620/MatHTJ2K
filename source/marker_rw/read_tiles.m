function read_tiles(tile_Set, numXtiles, hDsrc, JP2markers, main_header, reduce_NL)
M_OFFSET = 1;
DEBUG = 1;

RI = main_header.SIZ.get_RI();
color_gain = calculate_color_gain;

WORD = hDsrc.get_word();
tmp_SOT = SOT_marker;
while WORD == JP2markers.SOT
    tmp_SOT.read_SOT(hDsrc);
    tile_index = tmp_SOT.get_tile_index();
    tile_part_length = tmp_SOT.get_length();
    tile_part_index = tmp_SOT.get_tile_part_index();
    num_tile_parts = tmp_SOT.get_number_of_tile_parts();

    currentTile = tile_Set(tile_index + M_OFFSET);
    currentTile.idx = tile_index;

    if tile_part_index == 0
        if DEBUG == 1

        end
        % only for the first tile-part of a tile
        currentTile.idx_x = uint32(mod(double(tile_index), double(numXtiles)));
        currentTile.idx_y = floor_quotient_int(tile_index, numXtiles, 'uint32');
        %             % NOTE: (p,q) is transposed expression because of MATLAB
        tx0 = max(main_header.SIZ.XTOsiz + currentTile.idx_x * main_header.SIZ.XTsiz, main_header.SIZ.XOsiz);
        ty0 = max(main_header.SIZ.YTOsiz + currentTile.idx_y * main_header.SIZ.YTsiz, main_header.SIZ.YOsiz);
        tx1 = min(main_header.SIZ.XTOsiz + (currentTile.idx_x + 1) * main_header.SIZ.XTsiz, main_header.SIZ.Xsiz);
        ty1 = min(main_header.SIZ.YTOsiz + (currentTile.idx_y + 1) * main_header.SIZ.YTsiz, main_header.SIZ.Ysiz);
        currentTile.tile_pos_x = tx0;
        currentTile.tile_pos_y = ty0;
        currentTile.tile_size_x = tx1 - tx0;
        currentTile.tile_size_y = ty1 - ty0;

        if DEBUG == 1
            fprintf('Tile_index = %3d, tile size (x,y) = (%3d,%3d)\n', tile_index, currentTile.tile_size_x, currentTile.tile_size_y);
            fprintf('\ttile_part index = %d, tile_part length = %5d, num_tile_parts = %d\n', ...
                tile_part_index, tile_part_length, num_tile_parts);
        end

        for c = 0:main_header.SIZ.Csiz - 1
            tcx0 = ceil_quotient_int(tx0, main_header.SIZ.XRsiz(c + M_OFFSET), 'uint32');
            tcx1 = ceil_quotient_int(tx1, main_header.SIZ.XRsiz(c + M_OFFSET), 'uint32');
            tcy0 = ceil_quotient_int(ty0, main_header.SIZ.YRsiz(c + M_OFFSET), 'uint32');
            tcy1 = ceil_quotient_int(ty1, main_header.SIZ.YRsiz(c + M_OFFSET), 'uint32');
            currentTile.components(c + M_OFFSET) = jp2_tile_component(c, tcx0, tcy0, tcx1, tcy1);
        end
        % buffer for decoded components
        currentTile.output = cell(main_header.SIZ.Csiz, 1);

        %% read a tile-part header for the first tile-part header
        [WORD, numbytes_of_tilepart_headers] = readTilePartHeader(main_header, hDsrc, currentTile, true);
        assert(WORD == JP2markers.SOD);

        %% prepare coding units
        % prepare resolution
        for c = 0:main_header.SIZ.Csiz - 1
            [~, codingStyleComponent] = get_coding_Styles(main_header, currentTile.header, c);
            NL = codingStyleComponent.get_number_of_decomposition_levels();
            assert(NL >= reduce_NL, ...
                'ERROR: Value of resolution reduction is greater than the minimum number of decomposition levels = %d at Tile #%d Component #%d.', NL, currentTile.idx, c);
            for r = 0:NL
                if isempty(currentTile.resolution)
                    currentTile.resolution = resolution_info;
                else
                    currentTile.resolution = add_to_resolution_info(currentTile.resolution);
                end
                currentTile.resolution(end).idx = r;
                currentTile.resolution(end).idx_c = c;
            end
        end
        % prepare subbands, precincts and codeblocks
        g_resolution_idx = uint16(0);
        for c = 0:main_header.SIZ.Csiz - 1
            % get coding and quantization parameters
            [codingStyle, codingStyleComponent] = get_coding_Styles(main_header, currentTile.header, c);
            num_layers = codingStyle.get_number_of_layers();
            NL = codingStyleComponent.get_number_of_decomposition_levels();
            transformation = codingStyleComponent.get_transformation();
            band_weights = weight_mse(double(NL), double(transformation));
            codeblock_size = codingStyleComponent.get_codeblock_size_in_exponent();
            Cmodes = uint16(codingStyleComponent.get_codeblock_style());
            [~, quantStyleComponent] = get_quant_Styles(main_header, currentTile.header, c);
            is_derived = quantStyleComponent.is_derived();
            if isa(quantStyleComponent, 'QCD_marker')
                epsilons = quantStyleComponent.get_exponent();
            else
                epsilons = quantStyleComponent.get_exponent(codingStyleComponent.get_number_of_decomposition_levels(), main_header.SIZ.Csiz);
            end
            if transformation == 1
                mantissas = [];
            else
                mantissas = quantStyleComponent.get_mantissa();
            end
            nG = quantStyleComponent.get_number_of_guard_bits();
            for r = 0:NL
                currentResolution = currentTile.resolution(uint16(r) + g_resolution_idx + M_OFFSET);
                t2_make_resolution(currentResolution, currentTile, NL, r, c, main_header);
                if currentResolution.is_empty == false
                    for iPrecinctY = 0:currentResolution.numprecincthigh - 1
                        for jPrecinctX = 0:currentResolution.numprecinctwide - 1
                            for l = 0:codingStyle.get_number_of_layers() - 1
                                currentTile.packetPointer{c+M_OFFSET, r+M_OFFSET, l+M_OFFSET, jPrecinctX+M_OFFSET, iPrecinctY+M_OFFSET} = jp2_packet(c, r, l, jPrecinctX, iPrecinctY);
                            end
                            currentPrecinct = currentResolution.precinct_resolution(jPrecinctX + iPrecinctY * currentResolution.numprecinctwide + M_OFFSET);
                            for b = 1:currentResolution.num_band
                                currentPband = currentPrecinct.precinct_subbands(b);
                                t2_make_subband(c, currentResolution, b, currentPband, main_header, ...
                                    RI, num_layers, color_gain, NL, transformation, band_weights, codeblock_size, Cmodes, is_derived, epsilons, mantissas, nG);
                            end
                        end
                    end
                end
            end
            g_resolution_idx = g_resolution_idx + uint16(NL) + 1;
        end % processing for the first tile-part is ended here.
    else
        if DEBUG == 1
            fprintf('\ttile_part index = %3d, tile_part length = %5d, num_tile_parts = %d\n', ...
                tile_part_index, tile_part_length, num_tile_parts);
        end

        %% read a tile-part header for non-first tile-part header
        [WORD, numbytes_of_tilepart_headers] = readTilePartHeader(main_header, hDsrc, currentTile, false);
        assert(WORD == JP2markers.SOD);
    end

    %% read bitstream data in a tile
    currentTile.src_data.buf(currentTile.src_data.pos + M_OFFSET:currentTile.src_data.pos + tile_part_length - numbytes_of_tilepart_headers) = ...
        hDsrc.buf(hDsrc.pos + M_OFFSET:hDsrc.pos + tile_part_length - numbytes_of_tilepart_headers);
    currentTile.src_data.pos = currentTile.src_data.pos + tile_part_length - numbytes_of_tilepart_headers;
    if num_tile_parts ~= 0 && tile_part_index == num_tile_parts - 1
        currentTile.is_read = true;
    end
    hDsrc.pos = hDsrc.pos + tile_part_length - numbytes_of_tilepart_headers;
    WORD = hDsrc.get_word();
end
assert(WORD == JP2markers.EOC);
currentTile.is_read = true;
