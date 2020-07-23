function serializedPackets = finalize_packet(hTile, main_header)
M_OFFSET = 1;

packet_idx = 0;
total_bytes_of_packet_header = 0;

codingStyle = get_coding_Styles(main_header, hTile.header);
for c = 0:main_header.SIZ.Csiz - 1
    [codingStyle, codingStyleComponent] = get_coding_Styles(main_header, hTile.header, c);
    c_NL(c + M_OFFSET) = codingStyleComponent.get_number_of_decomposition_levels();
end

num_layers = codingStyle.get_number_of_layers();
NL = codingStyle.get_number_of_decomposition_levels();
tx0 = hTile.tile_pos_x;
tx1 = hTile.tile_pos_x + int32(hTile.tile_size_x);
ty0 = hTile.tile_pos_y;
ty1 = hTile.tile_pos_y + int32(hTile.tile_size_y);

% The value of RE, LYE and CE are exclusive.
main_RS = 0;
% RE should be NL + 1 because NL is not exclusive value.
main_RE = codingStyle.get_number_of_decomposition_levels() + 1;
main_LYE = codingStyle.get_number_of_layers();
main_CS = 0;
main_CE = main_header.SIZ.Csiz;
main_Progression_order = codingStyle.get_progression_order();
assert(main_Progression_order >= 0 && main_Progression_order <= 4);

if isempty(hTile.header.POC) == false
    hPOC = hTile.header.POC;
else
    hPOC = main_header.POC;
end

if isempty(hPOC) == false
    nPOC = hPOC.number_progression_order_change;
    g_RS = hPOC.RSpoc;
    g_RE = hPOC.REpoc;
    g_LYE = hPOC.LYEpoc;
    g_CS = hPOC.CSpoc;
    g_CE = hPOC.CEpoc;
    g_PO = hPOC.Ppoc;

    g_RE(g_RE > max(c_NL) + 1) = max(c_NL) + 1;
    g_LYE(g_LYE > main_LYE) = main_LYE;
    g_CE(g_CE > main_CE) = main_CE;
else
    nPOC = 1;
    g_RS = main_RS;
    g_RE = max(c_NL) + 1;
    g_LYE = main_LYE;
    g_CS = main_CS;
    g_CE = main_CE;
    g_PO = main_Progression_order;
end
serializedPackets = [];
for n = 1:nPOC
    switch g_PO(n)
        case 0 % LRCP
            for l = 0:g_LYE(n) - 1
                for r = g_RS(n):g_RE(n) - 1
                    for c = g_CS(n):g_CE(n) - 1
                        [codingStyle, codingStyleComponent] = get_coding_Styles(main_header, hTile.header, c);
                        c_NL = codingStyleComponent.get_number_of_decomposition_levels();
                        if r <= c_NL
                            currentResolution = findobj(hTile.resolution, 'idx', r, '-and', 'idx_c', c);
                            if currentResolution.is_empty == false
                                for iPrecinctY = 0:currentResolution.numprecincthigh - 1
                                    for jPrecinctX = 0:currentResolution.numprecinctwide - 1
                                        currentPacket = hTile.packetPointer{c+M_OFFSET, r+M_OFFSET, l+M_OFFSET, jPrecinctX+M_OFFSET, iPrecinctY+M_OFFSET};
                                        if currentPacket.is_emitted == false
                                            currentPacket.is_emitted = true;
                                            currentPacket.idx = packet_idx;
                                            serializedPackets = [serializedPackets, currentPacket];
                                            % prepare packet header writer
                                            pHeader = packet_header_writer;
                                            currentPrecinct = currentResolution.precinct_resolution(jPrecinctX + iPrecinctY * currentResolution.numprecinctwide + M_OFFSET);
                                            % we don't use an empty packet header
                                            pHeader.put_bit(1);
                                            for b = 1:currentResolution.num_band
                                                cpb = currentPrecinct.precinct_subbands(b);
                                                generate_packet_header(pHeader, cpb, l, false);
                                            end
                                            pHeader.flush(codingStyle.is_use_EPH());
                                            currentPacket.header = pHeader.buf;
                                            total_bytes_of_packet_header = total_bytes_of_packet_header + pHeader.num_bytes;

                                            % prepare packet body
                                            if isempty(currentPrecinct) == false
                                                for b = 1:currentResolution.num_band
                                                    cpb = currentPrecinct.precinct_subbands(b);
                                                    for i = 1:cpb.numCblksX * cpb.numCblksY
                                                        cblk = cpb.Cblks(i);
                                                        create_packet_body(cblk, l, currentPacket);
                                                    end
                                                end
                                            end

                                            % move to next packet
                                            packet_idx = packet_idx + 1;
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        case 1 % RLCP
            for r = g_RS(n):g_RE(n) - 1
                for l = 0:g_LYE(n) - 1
                    for c = g_CS(n):g_CE(n) - 1
                        [codingStyle, codingStyleComponent] = get_coding_Styles(main_header, hTile.header, c);
                        c_NL = codingStyleComponent.get_number_of_decomposition_levels();
                        if r <= c_NL
                            currentResolution = findobj(hTile.resolution, 'idx', r, '-and', 'idx_c', c);
                            if currentResolution.is_empty == false
                                for iPrecinctY = 0:currentResolution.numprecincthigh - 1
                                    for jPrecinctX = 0:currentResolution.numprecinctwide - 1
                                        currentPacket = hTile.packetPointer{c+M_OFFSET, r+M_OFFSET, l+M_OFFSET, jPrecinctX+M_OFFSET, iPrecinctY+M_OFFSET};
                                        if currentPacket.is_emitted == false
                                            currentPacket.is_emitted = true;
                                            currentPacket.idx = packet_idx;
                                            serializedPackets = [serializedPackets, currentPacket];
                                            % prepare packet header writer
                                            pHeader = packet_header_writer;
                                            currentPrecinct = currentResolution.precinct_resolution(jPrecinctX + iPrecinctY * currentResolution.numprecinctwide + M_OFFSET);
                                            % we don't use an empty packet header
                                            pHeader.put_bit(1);
                                            for b = 1:currentResolution.num_band
                                                cpb = currentPrecinct.precinct_subbands(b);
                                                generate_packet_header(pHeader, cpb, l, false);
                                            end
                                            pHeader.flush(codingStyle.is_use_EPH());
                                            currentPacket.header = pHeader.buf;
                                            total_bytes_of_packet_header = total_bytes_of_packet_header + pHeader.num_bytes;

                                            % prepare packet body
                                            if isempty(currentPrecinct) == false
                                                for b = 1:currentResolution.num_band
                                                    cpb = currentPrecinct.precinct_subbands(b);
                                                    for i = 1:cpb.numCblksX * cpb.numCblksY
                                                        cblk = cpb.Cblks(i);
                                                        create_packet_body(cblk, l, currentPacket);
                                                    end
                                                end
                                            end

                                            % move to next packet
                                            packet_idx = packet_idx + 1;
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        case 2 % RPCL
            PP = [];
            for c = 0:main_header.SIZ.Csiz - 1
                [codingStyle, codingStyleComponent] = get_coding_Styles(main_header, hTile.header, c);
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
            ptcr_y = zeros(main_header.SIZ.Csiz, codingStyle.get_number_of_decomposition_levels() + 1);
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
                            [codingStyle, codingStyleComponent] = get_coding_Styles(main_header, hTile.header, c);
                            c_NL = codingStyleComponent.get_number_of_decomposition_levels();
                            PP = codingStyleComponent.get_precinct_size_in_exponent();
                            PPx = PP(:, 1);
                            PPy = PP(:, 2);
                            if r <= c_NL
                                cr = findobj(hTile.resolution, 'idx', r, '-and', 'idx_c', c);
                                if cr.is_empty == false
                                    x_cond = mod(double(x), double(main_header.SIZ.XRsiz(c + M_OFFSET)) * 2^(PPx(r + M_OFFSET) + double(c_NL - r))) == 0 || ...
                                        ((x == tx0) && mod(double(cr.trx0) * 2^double(c_NL - r), 2^(PPx(r + M_OFFSET) + double(c_NL - r))) ~= 0);
                                    y_cond = mod(double(y), double(main_header.SIZ.YRsiz(c + M_OFFSET)) * 2^(PPy(r + M_OFFSET) + double(c_NL - r))) == 0 || ...
                                        ((y == ty0) && mod(double(cr.try0) * 2^double(c_NL - r), 2^(PPy(r + M_OFFSET) + double(c_NL - r))) ~= 0);
                                    if x_cond == true && y_cond == true && cr.numprecincthigh * cr.numprecinctwide ~= 0
                                        currentPrecinct = findobj(cr.precinct_resolution, 'idx_x', ptcr_x(c + M_OFFSET, r + M_OFFSET), '-and', 'idx_y', ptcr_y(c + M_OFFSET, r + M_OFFSET));
                                        for l = 0:g_LYE(n) - 1
                                            currentPacket = hTile.packetPointer{c+M_OFFSET, r+M_OFFSET, l+M_OFFSET, ptcr_x(c + M_OFFSET, r + M_OFFSET)+M_OFFSET, ptcr_y(c + M_OFFSET, r + M_OFFSET)+M_OFFSET};
                                            if currentPacket.is_emitted == false
                                                currentPacket.is_emitted = true;
                                                currentPacket.idx = packet_idx;
                                                serializedPackets = [serializedPackets, currentPacket];
                                                % prepare packet header writer
                                                pHeader = packet_header_writer;
                                                pHeader.put_bit(1);
                                                for b = 1:cr.num_band
                                                    cpb = currentPrecinct.precinct_subbands(b);
                                                    generate_packet_header(pHeader, cpb, l, false);
                                                end
                                                pHeader.flush(codingStyle.is_use_EPH());
                                                currentPacket.header = pHeader.buf;
                                                total_bytes_of_packet_header = total_bytes_of_packet_header + pHeader.num_bytes;
                                                % prepare packet body

                                                if isempty(currentPrecinct) == false
                                                    for b = 1:cr.num_band
                                                        cpb = currentPrecinct.precinct_subbands(b);
                                                        for i = 1:cpb.numCblksX * cpb.numCblksY
                                                            cblk = cpb.Cblks(i);
                                                            create_packet_body(cblk, l, currentPacket);
                                                        end
                                                    end
                                                end
                                                % move to next packet
                                                packet_idx = packet_idx + 1;
                                            end
                                        end
                                        ptcr_x(c + M_OFFSET, r + M_OFFSET) = ptcr_x(c + M_OFFSET, r + M_OFFSET) + 1;
                                        if ptcr_x(c + M_OFFSET, r + M_OFFSET) == cr.numprecinctwide
                                            ptcr_x(c + M_OFFSET, r + M_OFFSET) = 0;
                                            ptcr_y(c + M_OFFSET, r + M_OFFSET) = ptcr_y(c + M_OFFSET, r + M_OFFSET) + 1;
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        case 3 % PCRL
            PP = [];
            for c = 0:main_header.SIZ.Csiz - 1
                [codingStyle, codingStyleComponent] = get_coding_Styles(main_header, hTile.header, c);
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
            ptcr_y = zeros(main_header.SIZ.Csiz, codingStyle.get_number_of_decomposition_levels() + 1);
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
                    for c = g_CS(n):g_CE(n) - 1
                        [codingStyle, codingStyleComponent] = get_coding_Styles(main_header, hTile.header, c);
                        c_NL = codingStyleComponent.get_number_of_decomposition_levels();
                        PP = codingStyleComponent.get_precinct_size_in_exponent();
                        PPx = PP(:, 1);
                        PPy = PP(:, 2);

                        local_RE = min(c_NL, g_RE(n) - 1);
                        for r = g_RS(n):local_RE
                            cr = findobj(hTile.resolution, 'idx', r, '-and', 'idx_c', c);
                            if cr.is_empty == false
                                x_cond = mod(double(x), double(main_header.SIZ.XRsiz(c + M_OFFSET)) * 2^(PPx(r + M_OFFSET) + double(c_NL - r))) == 0 || ...
                                    ((x == tx0) && mod(double(cr.trx0) * 2^double(c_NL - r), 2^(PPx(r + M_OFFSET) + double(c_NL - r))) ~= 0);
                                y_cond = mod(double(y), double(main_header.SIZ.YRsiz(c + M_OFFSET)) * 2^(PPy(r + M_OFFSET) + double(c_NL - r))) == 0 || ...
                                    ((y == ty0) && mod(double(cr.try0) * 2^double(c_NL - r), 2^(PPy(r + M_OFFSET) + double(c_NL - r))) ~= 0);
                                if x_cond == true && y_cond == true && cr.numprecincthigh * cr.numprecinctwide ~= 0
                                    currentPrecinct = findobj(cr.precinct_resolution, 'idx_x', ptcr_x(c + M_OFFSET, r + M_OFFSET), '-and', 'idx_y', ptcr_y(c + M_OFFSET, r + M_OFFSET));
                                    for l = 0:g_LYE(n) - 1
                                        currentPacket = hTile.packetPointer{c+M_OFFSET, r+M_OFFSET, l+M_OFFSET, ptcr_x(c + M_OFFSET, r + M_OFFSET)+M_OFFSET, ptcr_y(c + M_OFFSET, r + M_OFFSET)+M_OFFSET};
                                        if currentPacket.is_emitted == false
                                            currentPacket.is_emitted = true;
                                            currentPacket.idx = packet_idx;
                                            serializedPackets = [serializedPackets, currentPacket];
                                            % prepare packet header writer
                                            pHeader = packet_header_writer;
                                            pHeader.put_bit(1);
                                            for b = 1:cr.num_band
                                                cpb = currentPrecinct.precinct_subbands(b);
                                                generate_packet_header(pHeader, cpb, l, false);
                                            end
                                            pHeader.flush(codingStyle.is_use_EPH());
                                            currentPacket.header = pHeader.buf;
                                            total_bytes_of_packet_header = total_bytes_of_packet_header + pHeader.num_bytes;
                                            % prepare packet body

                                            if isempty(currentPrecinct) == false
                                                for b = 1:cr.num_band
                                                    cpb = currentPrecinct.precinct_subbands(b);
                                                    for i = 1:cpb.numCblksX * cpb.numCblksY
                                                        cblk = cpb.Cblks(i);
                                                        create_packet_body(cblk, l, currentPacket);
                                                    end
                                                end
                                            end
                                            % move to next packet
                                            packet_idx = packet_idx + 1;
                                        end
                                    end
                                    ptcr_x(c + M_OFFSET, r + M_OFFSET) = ptcr_x(c + M_OFFSET, r + M_OFFSET) + 1;
                                    if ptcr_x(c + M_OFFSET, r + M_OFFSET) == cr.numprecinctwide
                                        ptcr_x(c + M_OFFSET, r + M_OFFSET) = 0;
                                        ptcr_y(c + M_OFFSET, r + M_OFFSET) = ptcr_y(c + M_OFFSET, r + M_OFFSET) + 1;
                                    end
                                end
                            end
                        end
                    end
                end
            end
        case 4 % CPRL
            PP = [];
            max_c_NL = 0;
            for c = 0:main_header.SIZ.Csiz - 1
                [codingStyle, codingStyleComponent] = get_coding_Styles(main_header, hTile.header, c);
                PP = [PP; codingStyleComponent.get_precinct_size_in_exponent()];
                if max_c_NL < codingStyleComponent.get_number_of_decomposition_levels()
                    max_c_NL = codingStyleComponent.get_number_of_decomposition_levels();
                end
                assert((isinteger(log2(double(main_header.SIZ.XRsiz(c + M_OFFSET)))) || main_header.SIZ.XRsiz(c + M_OFFSET) == 1) && ...
                    (isinteger(log2(double(main_header.SIZ.YRsiz(c + M_OFFSET)))) || main_header.SIZ.YRsiz(c + M_OFFSET) == 1), ...
                    'Although Component subsampling factor is not required to be power of two in CPRL progression, for FAST processing, being power of two is important...');
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
            ptcr_y = zeros(main_header.SIZ.Csiz, max_c_NL + 1);
            ptcr_x = zeros(size(ptcr_y));

            % prepare corrdinates to be examined
            tmp_y = 0:2^minPPy:ty1 - 1;
            tmp_y = tmp_y(tmp_y > ty0);
            y_examined = [ty0, tmp_y];
            tmp_x = 0:2^minPPx:tx1 - 1;
            tmp_x = tmp_x(tmp_x > tx0);
            x_examined = [tx0, tmp_x];

            for c = g_CS(n):g_CE(n) - 1
                [codingStyle, codingStyleComponent] = get_coding_Styles(main_header, hTile.header, c);
                c_NL = codingStyleComponent.get_number_of_decomposition_levels();
                local_RE = min(c_NL, g_RE(n) - 1);
                PP = codingStyleComponent.get_precinct_size_in_exponent();
                PPx = PP(:, 1);
                PPy = PP(:, 2);
                for y = y_examined
                    for x = x_examined
                        for r = g_RS(n):local_RE
                            cr = findobj(hTile.resolution, 'idx', r, '-and', 'idx_c', c);
                            if cr.is_empty == false
                                x_cond = mod(double(x), double(main_header.SIZ.XRsiz(c + M_OFFSET)) * 2^(PPx(r + M_OFFSET) + double(c_NL - r))) == 0 || ...
                                    ((x == tx0) && mod(double(cr.trx0) * 2^double(c_NL - r), 2^(PPx(r + M_OFFSET) + double(c_NL - r))) ~= 0);
                                y_cond = mod(double(y), double(main_header.SIZ.YRsiz(c + M_OFFSET)) * 2^(PPy(r + M_OFFSET) + double(c_NL - r))) == 0 || ...
                                    ((y == ty0) && mod(double(cr.try0) * 2^double(c_NL - r), 2^(PPy(r + M_OFFSET) + double(c_NL - r))) ~= 0);
                                if x_cond == true && y_cond == true && cr.numprecincthigh * cr.numprecinctwide ~= 0
                                    currentPrecinct = findobj(cr.precinct_resolution, 'idx_x', ptcr_x(c + M_OFFSET, r + M_OFFSET), '-and', 'idx_y', ptcr_y(c + M_OFFSET, r + M_OFFSET));
                                    for l = 0:g_LYE(n) - 1
                                        currentPacket = hTile.packetPointer{c+M_OFFSET, r+M_OFFSET, l+M_OFFSET, ptcr_x(c + M_OFFSET, r + M_OFFSET)+M_OFFSET, ptcr_y(c + M_OFFSET, r + M_OFFSET)+M_OFFSET};
                                        if currentPacket.is_emitted == false
                                            currentPacket.is_emitted = true;
                                            currentPacket.idx = packet_idx;
                                            serializedPackets = [serializedPackets, currentPacket];
                                            % prepare packet header writer
                                            pHeader = packet_header_writer;
                                            pHeader.put_bit(1);
                                            for b = 1:cr.num_band
                                                cpb = currentPrecinct.precinct_subbands(b);
                                                generate_packet_header(pHeader, cpb, l, false);
                                            end
                                            pHeader.flush(codingStyle.is_use_EPH());
                                            currentPacket.header = pHeader.buf;
                                            total_bytes_of_packet_header = total_bytes_of_packet_header + pHeader.num_bytes;
                                            % prepare packet body

                                            if isempty(currentPrecinct) == false
                                                for b = 1:cr.num_band
                                                    cpb = currentPrecinct.precinct_subbands(b);
                                                    for i = 1:cpb.numCblksX * cpb.numCblksY
                                                        cblk = cpb.Cblks(i);
                                                        create_packet_body(cblk, l, currentPacket);
                                                    end
                                                end
                                            end
                                            % move to next packet
                                            packet_idx = packet_idx + 1;
                                        end
                                    end
                                    ptcr_x(c + M_OFFSET, r + M_OFFSET) = ptcr_x(c + M_OFFSET, r + M_OFFSET) + 1;
                                    if ptcr_x(c + M_OFFSET, r + M_OFFSET) == cr.numprecinctwide
                                        ptcr_x(c + M_OFFSET, r + M_OFFSET) = 0;
                                        ptcr_y(c + M_OFFSET, r + M_OFFSET) = ptcr_y(c + M_OFFSET, r + M_OFFSET) + 1;
                                    end
                                end
                            end
                        end
                    end
                end
            end
    end
end