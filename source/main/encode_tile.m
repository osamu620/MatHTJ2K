function time_for_blockcoding = encode_tile(use_MEX, hTile, main_header, target_rate) %#codegen

M_OFFSET = 1;
DEBUG = 0; % If this is set to 1, some information will be shown.

RI = double(main_header.SIZ.get_RI());
color_gain = calculate_color_gain;

buf = hTile.buf;
[tile_size_y, tile_size_x, numComponents] = size(buf);
origClass = class(buf);
switch origClass
    case {'uint8'}
        inputRGB = zeros(tile_size_y, tile_size_x, numComponents, 'int8');
    case {'uint16'}
        inputRGB = zeros(tile_size_y, tile_size_x, numComponents, 'int16');
    case {'uint32', 'single'}
        inputRGB = zeros(tile_size_y, tile_size_x, numComponents, 'int32');
end

for c = 0:main_header.SIZ.Csiz - 1
    % DC level shifting (for unsigned inputs only)
    switch origClass
        case {'uint8'}
            DC_offset = 2^(RI(c + M_OFFSET) - 1);
            dc_offseted_component = int8(double(buf(:, :, c + M_OFFSET)) - double(DC_offset));
        case {'uint16'}
            DC_offset = 2^(RI(c + M_OFFSET) - 1);
            dc_offseted_component = int16(double(buf(:, :, c + M_OFFSET)) - double(DC_offset));
        case {'uint32'}
            DC_offset = 2^(RI(c + M_OFFSET) - 1);
            dc_offseted_component = int32(double(buf(:, :, c + M_OFFSET)) - double(DC_offset));
        case {'single'}
            dc_offseted_component = zeros(size(buf, 1), size(buf, 2), 'int32');
            for iRows = 1:tile_size_y
                dc_offseted_component(iRows, :) = typecast(buf(iRows, :, c + M_OFFSET), 'int32');
            end
    end
    inputRGB(:, :, c + M_OFFSET) = dc_offseted_component;
    inputRGB = double(inputRGB);
end

codingStyle = get_coding_Styles(main_header, hTile.header);

%% Color transform
if main_header.SIZ.Csiz >= 3 && codingStyle.get_multiple_component_transform() == 1
    inputYCbCr = myrgb2ycbcr(inputRGB(:, :, 1:3), codingStyle.get_transformation());
else
    inputYCbCr = inputRGB; % only Luminance input
end

%% prepare resolution and precinct
for c = 0:main_header.SIZ.Csiz - 1
    [codingStyle, codingStyleComponent] = get_coding_Styles(main_header, hTile.header, c);
    hTile.components(c + M_OFFSET).samples = inputYCbCr(:, :, c + M_OFFSET);
    NL = codingStyleComponent.get_number_of_decomposition_levels();
    for r = 0:NL
        if isempty(hTile.resolution)
            hTile.resolution = resolution_info;
        else
            hTile.resolution = add_to_resolution_info(hTile.resolution);
        end
        currentResolution = hTile.resolution(end);
        currentResolution.idx = r;
        currentResolution.idx_c = c;
        t2_make_resolution(currentResolution, hTile, NL, r, c, main_header);
    end
end

%% forward DWT
for c = 0:numComponents - 1
    fdwt(hTile, main_header, c, use_MEX);
end

time_for_blockcoding = 0;

%% Tier-1 coding
for c = 0:numComponents - 1
    % get coding and quantization parameters
    [codingStyle, codingStyleComponent] = get_coding_Styles(main_header, hTile.header, c);
    num_layers = codingStyle.get_number_of_layers();
    NL = codingStyleComponent.get_number_of_decomposition_levels();
    transformation = codingStyleComponent.get_transformation();
    band_weights = weight_mse(double(NL), double(transformation));
    codeblock_size = codingStyleComponent.get_codeblock_size_in_exponent();
    Cmodes = uint16(codingStyleComponent.get_codeblock_style());
    [quantStyle, quantStyleComponent] = get_quant_Styles(main_header, hTile.header, c);
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
        cr = findobj(hTile.resolution, 'idx', r, '-and', 'idx_c', c);
        if cr.is_empty == false
            for iPrecinctY = 0:cr.numprecincthigh - 1
                for jPrecinctX = 0:cr.numprecinctwide - 1
                    % create instance for packet header and body
                    for l = 0:codingStyle.get_number_of_layers() - 1
                        hTile.packetPointer{c+M_OFFSET, r+M_OFFSET, l+M_OFFSET, jPrecinctX+M_OFFSET, iPrecinctY+M_OFFSET} = jp2_packet(c, r, l, jPrecinctX, iPrecinctY);
                    end
                    currentPrecinct = cr.precinct_resolution(jPrecinctX + iPrecinctY * cr.numprecinctwide + M_OFFSET);
                    % enter each subband
                    for b = 1:cr.num_band
                        cb = cr.subbandInfo(b);
                        cpb = currentPrecinct.precinct_subbands(b);
                        t2_make_subband(c, cr, b, cpb, main_header, ...
                            RI, num_layers, color_gain, NL, transformation, band_weights, codeblock_size, Cmodes, is_derived, epsilons, mantissas, nG);

                        %% scalar quantization
                        step_size = cpb.Delta_b;
                        q_buf = cb.dwt_coeffs(cpb.pos_y - cb.pos_y + M_OFFSET:cpb.pos_y - cb.pos_y + int32(cpb.size_y), ...
                            cpb.pos_x - cb.pos_x + M_OFFSET:cpb.pos_x - cb.pos_x + int32(cpb.size_x));
                        s_q_buf = sign(q_buf);
                        cpb.quantized_coeffs = int32(s_q_buf .* floor(abs(q_buf) ./ step_size));
                        % code block loop
                        for idx_y = 1:cpb.numCblksY
                            for idx_x = 1:cpb.numCblksX
                                cblk = cpb.Cblks((idx_x - 1) + (idx_y - 1) * cpb.numCblksX + M_OFFSET);

                                %% block coding
                                elapsedCblkTime = t1encode_codeblock(use_MEX, cpb, cblk, idx_x, idx_y);
                                time_for_blockcoding = time_for_blockcoding + elapsedCblkTime;
                                %cblk = cpb.Cblks((idx_x-1) + (idx_y-1)*cpb.numCblksX + M_OFFSET);
                                if DEBUG == 1
                                    fprintf('c = %d, r = %d, b = %d, (px,py) = (%d,%d), (x, y) = (%2d, %2d), ZBP = %2d, numbyes = %5d\n', c, r, cb.idx, ...
                                        jPrecinctX, iPrecinctY, idx_x - 1, idx_y - 1, cblk.num_ZBP, sum(cblk.pass_length));
                                end
                            end
                        end % end of code block loop
                    end % end of band loop
                end % end of jPrecinctX
            end % end of iPrecinctY
        end % is empty resolution ?
    end % end of resolution loop
end % end of component loop

%% Rate-distortion optimization
truncate_codestream(hTile, main_header, target_rate);

%% Finalize packet; writing packet headers
serializedPackets = finalize_packet(hTile, main_header);
hTile.packetInfo = serializedPackets;
