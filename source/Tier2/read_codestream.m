function read_codestream(currentTile, main_header, PPM_header)
M_OFFSET = 1;

hDsrc = currentTile.src_data;

%% packet header location
if isempty(PPM_header) == false
    % packet headers are in the concatenated PPM marker segments
    hPHeader = PPM_header;
elseif isempty(currentTile.header.PPT) == false
    % packet headers are in the PPT marker segments
    hPHeader = packet_header_reader(currentTile.header.PPT.Ippt);
else
    % packet header will be inside a codestream.
    hPHeader = [];
end

resolution_info_Set = currentTile.resolution;

tx0 = currentTile.tile_pos_x;
tx1 = currentTile.tile_pos_x + int32(currentTile.tile_size_x);
ty0 = currentTile.tile_pos_y;
ty1 = currentTile.tile_pos_y + int32(currentTile.tile_size_y);

codingStyle = get_coding_Styles(main_header, currentTile.header);
c_NL = zeros(1, main_header.SIZ.Csiz);
for c = 0:main_header.SIZ.Csiz - 1
    [codingStyle, codingStyleComponent] = get_coding_Styles(main_header, currentTile.header, c);
    c_NL(c + M_OFFSET) = codingStyleComponent.get_number_of_decomposition_levels();
end

% The value of RE, LYE and CE are exclusive
main_RS = 0;
% RE should be NL + 1 because NL is not exclusive value.
main_RE = codingStyle.get_number_of_decomposition_levels() + 1;
main_LYE = codingStyle.get_number_of_layers();
main_CS = 0;
main_CE = main_header.SIZ.Csiz;
main_Progression_order = codingStyle.get_progression_order();
assert(main_Progression_order >= 0 && main_Progression_order <= 4);

nPOC = 1;
g_RS = main_RS;
g_RE = max(c_NL) + 1;
g_LYE = main_LYE;
g_CS = main_CS;
g_CE = main_CE;
g_PO = main_Progression_order;


if isempty(currentTile.header.POC) == false
    hPOC = currentTile.header.POC;
else
    hPOC = main_header.POC;
end

if isempty(hPOC) == false
    nPOC = nPOC + hPOC.number_progression_order_change;
    hPOC.REpoc(hPOC.REpoc > max(c_NL) + 1) = max(c_NL) + 1;
    hPOC.CEpoc(hPOC.CEpoc > main_CE) = main_CE;
    hPOC.LYEpoc(hPOC.LYEpoc > main_LYE) = main_LYE;
    g_RS = [hPOC.RSpoc, g_RS];
    g_RE = [hPOC.REpoc, g_RE];
    g_LYE = [hPOC.LYEpoc - 1, g_LYE];
    g_CS = [hPOC.CSpoc, g_CS];
    g_CE = [hPOC.CEpoc, g_CE];
    g_PO = [hPOC.Ppoc, g_PO];
end

for n = 1:nPOC
    switch g_PO(n)
        case 0

            %% LRCP
            for l = 0:g_LYE(n) - 1
                for r = g_RS(n):g_RE(n) - 1
                    for c = g_CS(n):g_CE(n) - 1
                        [codingStyle, codingStyleComponent] = get_coding_Styles(main_header, currentTile.header, c);
                        c_NL = codingStyleComponent.get_number_of_decomposition_levels();
                        if r <= c_NL
                            currentResolution = findobj(resolution_info_Set, 'idx_c', c, '-and', 'idx', r);
                            if currentResolution.is_empty == false
                                for iPrecinctY = 0:currentResolution.numprecincthigh - 1
                                    for jPrecinctX = 0:currentResolution.numprecinctwide - 1
                                        currentPrecinct = currentResolution.precinct_resolution(jPrecinctX + iPrecinctY * currentResolution.numprecinctwide + M_OFFSET);
                                        currentPacket = currentTile.packetPointer{c+M_OFFSET, r+M_OFFSET, l+M_OFFSET, jPrecinctX+M_OFFSET, iPrecinctY+M_OFFSET};
                                        read_packet(currentPacket, main_header, hDsrc, hPHeader, codingStyle, currentResolution, l, currentPrecinct, r); % last r is just for DEBUG info
                                    end % end of precinct x loop
                                end % end of precinct y loop
                            end
                        end
                    end % end of component loop
                end % end of resolution loop
            end % end of layer loop
        case 1

            %% RLCP
            for r = g_RS(n):g_RE(n) - 1
                for l = 0:g_LYE(n) - 1
                    for c = g_CS(n):g_CE(n) - 1
                        [codingStyle, codingStyleComponent] = get_coding_Styles(main_header, currentTile.header, c);
                        c_NL = codingStyleComponent.get_number_of_decomposition_levels();
                        if r <= c_NL
                            currentResolution = findobj(resolution_info_Set, 'idx_c', c, '-and', 'idx', r);
                            if currentResolution.is_empty == false
                                for iPrecinctY = 0:currentResolution.numprecincthigh - 1
                                    for jPrecinctX = 0:currentResolution.numprecinctwide - 1
                                        currentPrecinct = currentResolution.precinct_resolution(jPrecinctX + iPrecinctY * currentResolution.numprecinctwide + M_OFFSET);
                                        currentPacket = currentTile.packetPointer{c+M_OFFSET, r+M_OFFSET, l+M_OFFSET, jPrecinctX+M_OFFSET, iPrecinctY+M_OFFSET};
                                        read_packet(currentPacket, main_header, hDsrc, hPHeader, codingStyle, currentResolution, l, currentPrecinct, r); % last r is just for DEBUG info
                                    end % end of precinct x loop
                                end % end of precinct y loop
                            end
                        end
                    end % end of component loop
                end % end of layer loop
            end % end of resolution loop
        case 2

            %% RPCL
            PP = [];
            for c = 0:main_header.SIZ.Csiz - 1
                [codingStyle, codingStyleComponent] = get_coding_Styles(main_header, currentTile.header, c);
                PP = [PP; codingStyleComponent.get_precinct_size_in_exponent()];
            end
            if size(PP, 1) == 1
                minPPx = PP(1);
                minPPy = PP(2);
            else
                minPP = min(PP);
                minPPx = min(minPP(:, 1, :));
                minPPy = min(minPP(:, 2, :));
            end
            % prevent precinct size for search becomes less than 1.
            if minPPx == 0
                minPPx = 1;
            end
            if minPPy == 0
                minPPy = 1;
            end

            % precinct counter
            ptcr_y = zeros(g_CE(n), codingStyle.get_number_of_decomposition_levels() + 1);
            ptcr_x = zeros(size(ptcr_y));

            % prepare corrdinates to be examined
            tmp_y = 0:2^minPPy:ty1 - 1;
            tmp_y = tmp_y(tmp_y > ty0);
            y_examined = [ty0, tmp_y];
            tmp_x = 0:2^minPPx:tx1 - 1;
            tmp_x = tmp_x(tmp_x > tx0);
            x_examined = [tx0, tmp_x];

            for r = g_RS(n):g_RE(n) - 1
                for y = y_examined
                    for x = x_examined
                        for c = g_CS(n):g_CE(n) - 1
                            [codingStyle, codingStyleComponent] = get_coding_Styles(main_header, currentTile.header, c);
                            c_NL = codingStyleComponent.get_number_of_decomposition_levels();
                            PP = codingStyleComponent.get_precinct_size_in_exponent();
                            PPx = PP(:, 1);
                            PPy = PP(:, 2);
                            if r <= c_NL
                                currentResolution = findobj(resolution_info_Set, 'idx_c', c, '-and', 'idx', r);
                                if currentResolution.is_empty == false
                                    x_cond = mod(double(x), double(main_header.SIZ.XRsiz(c + M_OFFSET)) * 2^(PPx(r + M_OFFSET) + double(c_NL - r))) == 0 || ...
                                        ((x == tx0) && mod(double(currentResolution.trx0) * 2^double(c_NL - r), 2^(PPx(r + M_OFFSET) + double(c_NL - r))) ~= 0);
                                    y_cond = mod(double(y), double(main_header.SIZ.YRsiz(c + M_OFFSET)) * 2^(PPy(r + M_OFFSET) + double(c_NL - r))) == 0 || ...
                                        ((y == ty0) && mod(double(currentResolution.try0) * 2^double(c_NL - r), 2^(PPy(r + M_OFFSET) + double(c_NL - r))) ~= 0);
                                    if x_cond == true && y_cond == true && currentResolution.numprecincthigh * currentResolution.numprecinctwide ~= 0
                                        currentPrecinct = currentResolution.precinct_resolution(ptcr_x(c + M_OFFSET, r + M_OFFSET) + ptcr_y(c + M_OFFSET, r + M_OFFSET) * currentResolution.numprecinctwide + M_OFFSET);
                                        for l = 0:g_LYE(n) - 1
                                            currentPacket = currentTile.packetPointer{c+M_OFFSET, r+M_OFFSET, l+M_OFFSET, ptcr_x(c + M_OFFSET, r + M_OFFSET)+M_OFFSET, ptcr_y(c + M_OFFSET, r + M_OFFSET)+M_OFFSET};
                                            read_packet(currentPacket, main_header, hDsrc, hPHeader, codingStyle, currentResolution, l, currentPrecinct, r); % last r is just for DEBUG info
                                        end % end of layer loop
                                        % advance precinct counter
                                        ptcr_x(c + M_OFFSET, r + M_OFFSET) = ptcr_x(c + M_OFFSET, r + M_OFFSET) + 1;
                                        if ptcr_x(c + M_OFFSET, r + M_OFFSET) == currentResolution.numprecinctwide
                                            ptcr_x(c + M_OFFSET, r + M_OFFSET) = 0;
                                            ptcr_y(c + M_OFFSET, r + M_OFFSET) = ptcr_y(c + M_OFFSET, r + M_OFFSET) + 1;
                                        end
                                    end % end of precinct sequence
                                end
                            end
                        end % end of component loop
                    end % end of x loop
                end % end of y loop
            end % end of resolution loop
        case 3

            %% PCRL
            PP = [];
            for c = 0:main_header.SIZ.Csiz - 1
                [codingStyle, codingStyleComponent] = get_coding_Styles(main_header, currentTile.header, c);
                PP = [PP; codingStyleComponent.get_precinct_size_in_exponent()];
            end
            if size(PP, 1) == 1
                minPPx = PP(1);
                minPPy = PP(2);
            else
                minPP = min(PP);
                minPPx = min(minPP(:, 1, :));
                minPPy = min(minPP(:, 2, :));
            end
            % prevent precinct size for search becomes less than 1.
            if minPPx == 0
                minPPx = 1;
            end
            if minPPy == 0
                minPPy = 1;
            end

            % precinct counter
            ptcr_y = zeros(g_CE(n), codingStyle.get_number_of_decomposition_levels() + 1);
            ptcr_x = zeros(size(ptcr_y));

            % prepare corrdinates to be examined
            tmp_y = 0:2^minPPy:ty1 - 1;
            tmp_y = tmp_y(tmp_y > ty0);
            y_examined = [ty0, tmp_y];
            tmp_x = 0:2^minPPx:tx1 - 1;
            tmp_x = tmp_x(tmp_x > tx0);
            x_examined = [tx0, tmp_x];

            for y = y_examined
                for x = x_examined
                    res_idx = 0;
                    for c = g_CS(n):g_CE(n) - 1
                        [codingStyle, codingStyleComponent] = get_coding_Styles(main_header, currentTile.header, c);
                        c_NL = codingStyleComponent.get_number_of_decomposition_levels();
                        PP = codingStyleComponent.get_precinct_size_in_exponent();
                        PPx = PP(:, 1);
                        PPy = PP(:, 2);

                        local_RE = min(c_NL, g_RE(n) - 1);
                        for r = g_RS(n):local_RE
                            currentResolution = resolution_info_Set(res_idx + r + M_OFFSET);
                            if currentResolution.is_empty == false
                                x_cond = mod(double(x), double(main_header.SIZ.XRsiz(c + M_OFFSET)) * 2^(PPx(r + M_OFFSET) + double(c_NL - r))) == 0 || ...
                                    ((x == tx0) && mod(double(currentResolution.trx0) * 2^double(c_NL - r), 2^(PPx(r + M_OFFSET) + double(c_NL - r))) ~= 0);
                                y_cond = mod(double(y), double(main_header.SIZ.YRsiz(c + M_OFFSET)) * 2^(PPy(r + M_OFFSET) + double(c_NL - r))) == 0 || ...
                                    ((y == ty0) && mod(double(currentResolution.try0) * 2^double(c_NL - r), 2^(PPy(r + M_OFFSET) + double(c_NL - r))) ~= 0);
                                if x_cond == true && y_cond == true && currentResolution.numprecincthigh * currentResolution.numprecinctwide ~= 0
                                    currentPrecinct = currentResolution.precinct_resolution(ptcr_x(c + M_OFFSET, r + M_OFFSET) + ptcr_y(c + M_OFFSET, r + M_OFFSET) * currentResolution.numprecinctwide + M_OFFSET);
                                    for l = 0:g_LYE(n) - 1
                                        currentPacket = currentTile.packetPointer{c+M_OFFSET, r+M_OFFSET, l+M_OFFSET, ptcr_x(c + M_OFFSET, r + M_OFFSET)+M_OFFSET, ptcr_y(c + M_OFFSET, r + M_OFFSET)+M_OFFSET};
                                        read_packet(currentPacket, main_header, hDsrc, hPHeader, codingStyle, currentResolution, l, currentPrecinct, r); % last r is just for DEBUG info
                                    end % end of layer loop
                                    % advance precinct counter
                                    ptcr_x(c + M_OFFSET, r + M_OFFSET) = ptcr_x(c + M_OFFSET, r + M_OFFSET) + 1;
                                    if ptcr_x(c + M_OFFSET, r + M_OFFSET) == currentResolution.numprecinctwide
                                        ptcr_x(c + M_OFFSET, r + M_OFFSET) = 0;
                                        ptcr_y(c + M_OFFSET, r + M_OFFSET) = ptcr_y(c + M_OFFSET, r + M_OFFSET) + 1;
                                    end
                                end % end of precinct sequence
                            end
                        end % end of resolution loop
                        res_idx = res_idx + c_NL + 1;
                    end % end of component loop
                end % end of x loop
            end % end of y loop
        case 4

            %% CPRL
            PP = [];
            max_c_NL = 0;
            for c = 0:main_header.SIZ.Csiz - 1
                [codingStyle, codingStyleComponent] = get_coding_Styles(main_header, currentTile.header, c);
                PP = [PP; codingStyleComponent.get_precinct_size_in_exponent()];
                if max_c_NL < codingStyleComponent.get_number_of_decomposition_levels()
                    max_c_NL = codingStyleComponent.get_number_of_decomposition_levels();
                end
            end
            if size(PP, 1) == 1
                minPPx = PP(1);
                minPPy = PP(2);
            else
                minPP = min(PP);
                minPPx = min(minPP(:, 1, :));
                minPPy = min(minPP(:, 2, :));
            end
            % prevent precinct size for search becomes less than 1.
            if minPPx == 0
                minPPx = 1;
            end
            if minPPy == 0
                minPPy = 1;
            end

            % precinct counter
            ptcr_y = zeros(g_CE(n), max_c_NL + 1);
            ptcr_x = zeros(size(ptcr_y));

            % prepare corrdinates to be examined
            tmp_y = 0:2^minPPy:ty1 - 1;
            tmp_y = tmp_y(tmp_y > ty0);
            y_examined = [ty0, tmp_y];
            tmp_x = 0:2^minPPx:tx1 - 1;
            tmp_x = tmp_x(tmp_x > tx0);
            x_examined = [tx0, tmp_x];

            for c = g_CS(n):g_CE(n) - 1
                [codingStyle, codingStyleComponent] = get_coding_Styles(main_header, currentTile.header, c);
                c_NL = codingStyleComponent.get_number_of_decomposition_levels();
                local_RE = min(c_NL, g_RE(n) - 1);
                PP = codingStyleComponent.get_precinct_size_in_exponent();
                PPx = PP(:, 1);
                PPy = PP(:, 2);
                for y = y_examined
                    for x = x_examined
                        for r = g_RS(n):local_RE
                            currentResolution = findobj(resolution_info_Set, 'idx_c', c, '-and', 'idx', r);
                            if currentResolution.is_empty == false
                                x_cond = mod(double(x), double(main_header.SIZ.XRsiz(c + M_OFFSET)) * 2^(PPx(r + M_OFFSET) + double(c_NL - r))) == 0 || ...
                                    ((x == tx0) && mod(double(currentResolution.trx0) * 2^double(c_NL - r), 2^(PPx(r + M_OFFSET) + double(c_NL - r))) ~= 0);
                                y_cond = mod(double(y), double(main_header.SIZ.YRsiz(c + M_OFFSET)) * 2^(PPy(r + M_OFFSET) + double(c_NL - r))) == 0 || ...
                                    ((y == ty0) && mod(double(currentResolution.try0) * 2^double(c_NL - r), 2^(PPy(r + M_OFFSET) + double(c_NL - r))) ~= 0);
                                if x_cond == true && y_cond == true && currentResolution.numprecincthigh * currentResolution.numprecinctwide ~= 0
                                    currentPrecinct = currentResolution.precinct_resolution(ptcr_x(c + M_OFFSET, r + M_OFFSET) + ptcr_y(c + M_OFFSET, r + M_OFFSET) * currentResolution.numprecinctwide + M_OFFSET);

                                    for l = 0:g_LYE(n) - 1
                                        currentPacket = currentTile.packetPointer{c+M_OFFSET, r+M_OFFSET, l+M_OFFSET, ptcr_x(c + M_OFFSET, r + M_OFFSET)+M_OFFSET, ptcr_y(c + M_OFFSET, r + M_OFFSET)+M_OFFSET};
                                        read_packet(currentPacket, main_header, hDsrc, hPHeader, codingStyle, currentResolution, l, currentPrecinct, r); % last r is just for DEBUG info
                                    end % end of layer loop
                                    % advance precinct counter
                                    ptcr_x(c + M_OFFSET, r + M_OFFSET) = ptcr_x(c + M_OFFSET, r + M_OFFSET) + 1;
                                    if ptcr_x(c + M_OFFSET, r + M_OFFSET) == currentResolution.numprecinctwide
                                        ptcr_x(c + M_OFFSET, r + M_OFFSET) = 0;
                                        ptcr_y(c + M_OFFSET, r + M_OFFSET) = ptcr_y(c + M_OFFSET, r + M_OFFSET) + 1;
                                    end
                                end % end of precinct sequence
                            end
                        end % end of resolution loop
                    end % end of x loop
                end % end of y loop
            end % end of component loop
    end
end