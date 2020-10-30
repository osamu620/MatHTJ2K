function is_empty_packet = read_packet(currentPacket, main_header, hDsrc, hPHeader, codingStyle, currentResolution, l, currentPrecinct, r)
M_OFFSET = 1;

DEBUG = 0;

if isempty(currentPrecinct) || currentPacket.is_emitted == true
    return;
end

x_FF91 = uint16(65425);
x_FF92 = uint16(65426);
Nsop = -1;
% if SOP present
if codingStyle.is_use_SOP() == true
    WORD = hDsrc.get_word();
    if WORD == x_FF91
        Lsop = hDsrc.get_word();
        assert(Lsop == 4);
        Nsop = hDsrc.get_word();
    else
        % SOP may not be present even SPcod says SOP was used
        hDsrc.pos = hDsrc.pos - 2; % rewind 2 bytes
        % Nsop shall be incremented no matter SOP is present or not
    end
end

%% read packet header
is_PPT_PPM = false;
if isempty(hPHeader) == true
    packetHeader = packet_header_reader(hDsrc);
else
    is_PPT_PPM = true;
    packetHeader = hPHeader;
end
bit = packetHeader.get_bit();
if bit == 0 % this bit '0' means empty packet, which has zero length.
    fprintf('INFO: empty packet is found at: c# %3d, l: %2d, r: %2d, (px, py) = (%2d, %2d)\n', currentResolution.idx_c, l, currentResolution.idx, currentPrecinct.idx_x, currentPrecinct.idx_y);
    is_empty_packet = true;
    packetHeader.bits = 0;
    % if EPH present
    if codingStyle.is_use_EPH() == true
        WORD = packetHeader.hDsrc.get_word();
        assert(WORD == x_FF92);
    end
    assert(currentPacket.is_emitted == false);
    currentPacket.is_emitted = true;
    return;
else
    is_empty_packet = false;
end

count = 1;
for b = 1:currentResolution.num_band
    currentPband = currentPrecinct.precinct_subbands(b);
    if currentPband.size_x * currentPband.size_y ~= 0
        for idx = 0:currentPband.numCblksX * currentPband.numCblksY - 1
            number_of_bytes(count) = parse_packet_header(packetHeader, l, currentPband, currentPband.Cblks(idx + M_OFFSET), main_header.Cap15_b14_15);
            if DEBUG == 1
                fprintf('Nsop = %2d, L = %2d,c = %2d,r = %2d,b = %2d,x = %2d, y = %2d, size = (%2d, %2d), ZBP = %2d, num_passes = %2d, bytes= %5d\n', ...
                    Nsop, l, currentResolution.idx_c - 1, r, ...
                    currentPband.band_idx, ...
                    mod(idx, currentPband.numCblksX), floor(idx / currentPband.numCblksX), currentPband.Cblks(idx + M_OFFSET).size_x, currentPband.Cblks(idx + M_OFFSET).size_y, ...
                    currentPband.Cblks(idx + M_OFFSET).num_ZBP, currentPband.Cblks(idx + M_OFFSET).num_passes, number_of_bytes(count));
            end
            count = count + 1;
        end
    end
end
% if the last byte of a packet header is 0xFF, one bit shall be read.
if packetHeader.byte == 255
    packetHeader.get_bit();
end
% if PPM or PPT present, flush bit counter
if is_PPT_PPM == true
    packetHeader.bits = 0;
end
% if EPH present
if codingStyle.is_use_EPH() == true
    WORD = packetHeader.hDsrc.get_word();
    assert(WORD == x_FF92);
end
count = 1;

%% read packet body
for b = 1:currentResolution.num_band
    currentPband = currentPrecinct.precinct_subbands(b);
    if currentPband.size_x * currentPband.size_y ~= 0
        for idx = 0:currentPband.numCblksX * currentPband.numCblksY - 1
            currentCodeblock = currentPband.Cblks(idx + M_OFFSET);
            if currentCodeblock.layer_passes(l + M_OFFSET) > 0
                l0 = currentCodeblock.layer_start(l + M_OFFSET);
                l1 = l0 + currentCodeblock.layer_passes(l + M_OFFSET);
                layer_length = sum(currentCodeblock.pass_length(l0 + M_OFFSET:l1));
                assert(number_of_bytes(count) == layer_length); % assetion for packet header parsing
                currentCodeblock.compressed_data(currentCodeblock.length + M_OFFSET:currentCodeblock.length + layer_length) = hDsrc.get_N_byte(layer_length);
                currentCodeblock.length = currentCodeblock.length + layer_length;
            end
            count = count + 1;
        end
    end
end
% change "already read" status for POC
assert(currentPacket.is_emitted == false);
currentPacket.is_emitted = true;