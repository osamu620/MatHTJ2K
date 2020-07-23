function number_of_bytes = parse_packet_header(packetHeader, layer_idx, hPband, hCodeblock, CcapBits14_15)
DEBUG = 0; % 1 or 2 is porssible
M_OFFSET = 1;

RESTART = uint16(4);
BYPASS = uint16(1);
HT = uint16(64);
HT_MIXED = uint16(128);
HT_PHLD = uint16(256);

%% raster index is for tagtree decoding
rasterCblkIdx = hCodeblock.idx_x + (hCodeblock.idx_y) * hPband.numCblksX + M_OFFSET;

number_of_bytes = 0; % initialize to zero in case of `not included`.
hCodeblock.layer_start(layer_idx + M_OFFSET) = uint32(sum(hCodeblock.layer_passes));

if hCodeblock.already_included == false

    %% Flags for placeholder passes and mixed mode
    if hCodeblock.Cmodes >= 64 % HTJ2K was used for this codestream
        % adding HT_PHLD flag because an HT codeblock may include placeholder passes
        hCodeblock.Cmodes = bitor(hCodeblock.Cmodes, HT_PHLD);
        if CcapBits14_15 == 3
            hCodeblock.Cmodes = bitor(hCodeblock.Cmodes, HT_MIXED);
        end
    end

    %% Retrieve codeblock inclusion
    if DEBUG == 1
        fprintf('\t\tinclusion start\n');
    end
    assert(hCodeblock.fast_skip_passes == 0);

    %% Special case; A codeblock is not included in the first layer(layer 0).
    %  Inclusion information of layer 0 (i.e. before the first contribution) shall be decoded.
    if layer_idx > 0
        % decode tagtree information
        current_node = hPband.inclusionInfo.node(rasterCblkIdx);
        tree_path = current_node.idx;
        while current_node.parent_idx ~= 0
            current_node = hPband.inclusionInfo.node(current_node.parent_idx);
            tree_path = [tree_path, current_node.idx];
        end
        is_included = false; % Does this code-block contribute this layer?
        threshold = 0; % THIS MAY BE OTHER THAN 0
        for i = length(tree_path):-1:1
            current_node = hPband.inclusionInfo.node(tree_path(i));
            if current_node.state == 0
                if current_node.level > 0 % not root node
                    if current_node.current_value < hPband.inclusionInfo.node(current_node.parent_idx).current_value
                        current_node.current_value = hPband.inclusionInfo.node(current_node.parent_idx).current_value;
                    end
                end
                if current_node.current_value <= threshold
                    bit = packetHeader.get_bit();
                    if bit == 1
                        current_node.state = 1;
                        current_node.value = current_node.current_value;
                        is_included = true;
                    else
                        current_node.current_value = current_node.current_value + 1;
                        is_included = false; % important if include '1 0' ...
                    end
                end
            end
        end
    end

    %% Normal case of inclusion information
    % decode tagtree information
    current_node = hPband.inclusionInfo.node(rasterCblkIdx);
    tree_path = current_node.idx;
    while current_node.parent_idx ~= 0
        current_node = hPband.inclusionInfo.node(current_node.parent_idx);
        tree_path = [tree_path, current_node.idx];
    end
    is_included = false; % Does this code-block contribute this layer?

    threshold = layer_idx;
    for i = length(tree_path):-1:1
        current_node = hPband.inclusionInfo.node(tree_path(i));
        if current_node.state == 0
            if current_node.level > 0 % not root node
                if current_node.current_value < hPband.inclusionInfo.node(current_node.parent_idx).current_value
                    current_node.current_value = hPband.inclusionInfo.node(current_node.parent_idx).current_value;
                end
            end
            if current_node.current_value <= threshold
                bit = packetHeader.get_bit();
                if bit == 1
                    current_node.state = uint8(1);
                    current_node.value = current_node.current_value;
                    is_included = true;
                else
                    current_node.current_value = current_node.current_value + 1;
                    is_included = false; % important if include '1 0' ...
                end
            end
        end
    end
    if DEBUG == 1
        fprintf('\t\tinclusion end %d\n', is_included);
    end

    %% Retrieve number of zero bit planes
    if hCodeblock.already_included == false && is_included == true
        hCodeblock.already_included = true;
        if DEBUG == 1
            fprintf('\t\tZBP start\n');
        end
        % decode tagtree information
        current_node = hPband.ZBPInfo.node(rasterCblkIdx);
        tree_path = current_node.idx;
        while current_node.parent_idx ~= 0
            current_node = hPband.ZBPInfo.node(current_node.parent_idx);
            tree_path = [tree_path, current_node.idx];
        end
        for i = length(tree_path):-1:1
            current_node = hPband.ZBPInfo.node(tree_path(i));
            if current_node.level > 0 % not a root node
                if current_node.current_value < hPband.ZBPInfo.node(current_node.parent_idx).current_value
                    current_node.current_value = hPband.ZBPInfo.node(current_node.parent_idx).current_value;
                end
            end
            while current_node.state == 0
                bit = packetHeader.get_bit();
                if bit == 0
                    current_node.current_value = current_node.current_value + 1;
                else
                    current_node.value = current_node.current_value;
                    current_node.state = uint8(1);
                end
            end
        end
        hCodeblock.num_ZBP = uint8(current_node.value);
        if DEBUG == 1
            fprintf('\t\tZBP end, ZBP = %d\n', hCodeblock.num_ZBP);
        end
    end
else % this codeblock has been already included in previous packets
    bit = packetHeader.get_bit();
    if bit == 1
        is_included = true;
    else
        is_included = false;
    end
end

%% Retrieve number of coding passes in this layer
if is_included == true
    if DEBUG == 1
        fprintf('\t\tnewpass start\n');
    end
    new_passes = 1;
    bit = packetHeader.get_bit();
    new_passes = new_passes + bit;
    if new_passes >= 2
        bit = packetHeader.get_bit();
        new_passes = new_passes + bit;
        if new_passes >= 3
            codeword = uint8(get_bits(packetHeader, 2));
            new_passes = new_passes + codeword;
            if new_passes >= 6
                codeword = uint8(get_bits(packetHeader, 5));
                new_passes = new_passes + codeword;
                if new_passes >= 37
                    codeword = uint8(get_bits(packetHeader, 7));
                    new_passes = new_passes + codeword;
                end
            end
        end
    end
    new_passes = int32(new_passes);
    hCodeblock.layer_passes(layer_idx + M_OFFSET) = uint32(new_passes);
    if DEBUG == 1
        fprintf('\t\tnewpass end, new_passes = %d\n', new_passes);
    end
    if DEBUG == 2
        fprintf('* num_passes = %2d, ', hCodeblock.num_passes);
    end

    %% Retirieve LBlock
    bit = packetHeader.get_bit();
    while bit == 1
        hCodeblock.LBlock = hCodeblock.LBlock + 1;
        bit = packetHeader.get_bit();
    end

    bypass_term_threshold = 0;
    bits_to_read = 0;
    pass_idx = hCodeblock.num_passes;
    segment_bytes = uint32(0); % the same as 'codeword'
    segment_passes = 0;
    next_segment_passes = 0;
    if DEBUG == 2
        href_passes = []; %%%%%%%%%%
    end
    if bitand(hCodeblock.Cmodes, HT_PHLD)
        href_passes = mod(int32(pass_idx) + new_passes - 1, 3);
        segment_passes = int32(new_passes) - int32(href_passes);
        pass_bound = 2;
        bits_to_read = hCodeblock.LBlock;
        if DEBUG == 1
            fprintf('\t\tsegment_passes = %d\n', segment_passes);
        end
        if segment_passes < 1
            % No possible HT Cleanup pass here; may have placeholder passes
            % or an original J2K block bit-stream (in MIXED mode).
            segment_passes = new_passes;
            while pass_bound <= segment_passes % log2(segment_passes)
                bits_to_read = bits_to_read + 1;
                pass_bound = pass_bound + pass_bound;
            end
            segment_bytes = packetHeader.get_bits(bits_to_read);
            if segment_bytes ~= 0
                if bitand(hCodeblock.Cmodes, HT_MIXED)
                    hCodeblock.Cmodes = bitand(hCodeblock.Cmodes, bitcmp(HT_PHLD + HT));
                else
                    error('Length information for a HT-codeblock is invalid');
                end
            end
        else
            while pass_bound <= segment_passes
                bits_to_read = bits_to_read + 1;
                pass_bound = pass_bound + pass_bound;
            end
            segment_bytes = packetHeader.get_bits(bits_to_read);

            if segment_bytes ~= 0
                % No more placeholder passes
                if ~bitand(hCodeblock.Cmodes, HT_MIXED)
                    % Must be the first HT Cleanup pass
                    if segment_bytes < 2
                        error('Length information for a HT-codeblock is invalid');
                    end
                    next_segment_passes = 2;
                    hCodeblock.Cmodes = bitand(hCodeblock.Cmodes, bitcmp(HT_PHLD));
                elseif hCodeblock.LBlock > 3 && segment_bytes > 1 && bitshift(segment_bytes, -(bits_to_read - 1)) == 0
                    % Must be the first HT Cleanup pass, since length MSB is 0
                    next_segment_passes = 2;
                    hCodeblock.Cmodes = bitand(hCodeblock.Cmodes, bitcmp(HT_PHLD));
                else
                    % Must have an original (non-HT) block coding pass
                    hCodeblock.Cmodes = bitand(hCodeblock.Cmodes, bitcmp(HT_PHLD + HT));
                    segment_passes = new_passes;
                    while pass_bound <= segment_passes
                        bits_to_read = bits_to_read + 1;
                        pass_bound = pass_bound + pass_bound;
                        segment_bytes = 2 * segment_bytes + uint32(packetHeader.get_bit());
                    end
                end
            else
                % Probably parsing placeholder passes, but we need to read an
                % extra length bit to verify this, since prior to the first
                % HT Cleanup pass, the number of length bits read for a
                % contributing code-block is dependent on the number of passes
                % being included, as if it were a non-HT code-block.
                segment_passes = new_passes;
                if pass_bound <= segment_passes
                    while 1
                        bits_to_read = bits_to_read + 1;
                        pass_bound = pass_bound + pass_bound;
                        segment_bytes = 2 * segment_bytes + uint32(packetHeader.get_bit());
                        if pass_bound > segment_passes
                            break;
                        end
                    end
                    if segment_bytes ~= 0
                        if bitand(hCodeblock.Cmodes, HT_MIXED)
                            hCodeblock.Cmodes = bitand(hCodeblock.Cmodes, bitcmp(HT_PHLD + HT));
                        else
                            error('Length information for a HT-codeblock is invalid');
                        end
                    end
                end
            end
        end
    elseif bitand(hCodeblock.Cmodes, HT)
        % Quality layer commences with a non-initial HT coding pass
        assert(bits_to_read == 0);
        segment_passes = mod(int32(hCodeblock.num_passes), 3);
        if segment_passes == 0
            % num_passes is a HT Cleanup pass; next segment has refinement passes
            segment_passes = 1;
            next_segment_passes = 2;
            if segment_bytes == 1
                error('something wrong');
            end
        else
            % 1 means num_passes is HT SigProp; 2 means num_passes is HT MagRef pass
            if new_passes > 1
                segment_passes = 3 - segment_passes;
            else
                segment_passes = 1;
            end
            next_segment_passes = 1;
            bits_to_read = segment_passes - 1;
        end
        bits_to_read = bits_to_read + hCodeblock.LBlock;
        segment_bytes = packetHeader.get_bits(bits_to_read);
    elseif ~bitand(hCodeblock.Cmodes, RESTART + BYPASS)
        % Common case for non-HT code-blocks; we have only one segment
        bits_to_read = hCodeblock.LBlock + floor(log2(double(new_passes)));
        segment_bytes = packetHeader.get_bits(bits_to_read);
        segment_passes = new_passes;
    elseif bitand(hCodeblock.Cmodes, RESTART)
        bits_to_read = hCodeblock.LBlock;
        segment_bytes = packetHeader.get_bits(bits_to_read);
        segment_passes = 1;
        next_segment_passes = 1;
    else % BYPASS_MODE
        bypass_term_threshold = 10;
        assert(bits_to_read == 0);
        if hCodeblock.num_passes < bypass_term_threshold
            % May have from 1 to 10 uninterrupted passes before 1st RAW SigProp
            segment_passes = bypass_term_threshold - hCodeblock.num_passes;
            if segment_passes > new_passes
                segment_passes = new_passes;
            end
            while bitshift(2, bits_to_read) <= segment_passes
                bits_to_read = bits_to_read + 1;
            end
            next_segment_passes = 2;
        elseif mod(hCodeblock.num_passes - bypass_term_threshold, 3) < 2
            % 0 means `num_passes' is a RAW SigProp; 1 means `num_passes' is a RAW MagRef pass
            if new_passes > 1
                segment_passes = 2 - mod(hCodeblock.num_passes - bypass_term_threshold, 3);
            else
                segment_passes = 1;
            end
            bits_to_read = segment_passes - 1;
            next_segment_passes = 1;
        else
            % `num_passes' is an isolated Cleanup pass that precedes a RAW SigProp pass
            segment_passes = 1;
            next_segment_passes = 2;
        end
        bits_to_read = int32(bits_to_read) + hCodeblock.LBlock;
        segment_bytes = packetHeader.get_bits(bits_to_read);
    end
    hCodeblock.num_passes = hCodeblock.num_passes + uint8(segment_passes); %new_passes;
    hCodeblock.pass_length(hCodeblock.num_passes + 0) = int32(segment_bytes);
    number_of_bytes = number_of_bytes + segment_bytes;

    if DEBUG == 2
        if isempty(href_passes) == false
            fprintf('1st bits = %2d, LBlock = %2d, new_passes %2d, x =   %d, segment_passes = %2d, length = %4d ', bits_to_read, hCodeblock.LBlock, new_passes, href_passes, segment_passes, segment_bytes); %%%%%%
        else
            fprintf('1st bits = %2d, LBlock = %2d, new_passes %2d, x = NULL, segment_passes = %2d, length = %4d ', bits_to_read, hCodeblock.LBlock, new_passes, segment_passes, segment_bytes); %%%%%%
        end
    end

    if bitand(hCodeblock.Cmodes, HT + HT_PHLD) == HT
        new_passes = new_passes - segment_passes;
        primary_passes = segment_passes + int32(hCodeblock.fast_skip_passes);
        hCodeblock.fast_skip_passes = uint8(0);
        primary_bytes = segment_bytes;
        secondary_passes = 0;
        secondary_bytes = uint32(0);
        empty_set = false;
        if next_segment_passes == 2 && segment_bytes == 0
            empty_set = true;
        end
        while new_passes > 0
            if new_passes > 1
                segment_passes = next_segment_passes;
            else
                segment_passes = 1;
            end
            next_segment_passes = 3 - next_segment_passes;
            bits_to_read = hCodeblock.LBlock + segment_passes - 1;
            segment_bytes = packetHeader.get_bits(bits_to_read);
            new_passes = new_passes - segment_passes;
            if next_segment_passes == 2
                % This is a FAST Cleanup pass
                assert(segment_passes == 1);
                if segment_bytes ~= 0
                    % This will have to be the new primary
                    if segment_bytes < 2
                        error('something wrong');
                    end
                    fast_skip_bytes = fast_skip_bytes + primary_bytes + secondary_bytes;
                    primary_passes = primary_passes + 1 + secondary_passes;
                    primary_bytes = segment_bytes;
                    secondary_bytes = 0;
                    secondary_passes = 0;
                    primary_passes = primary_passes + hCodeblock.fast_skip_passes;
                    hCodeblock.fast_skip_passes = 0;
                    empty_set = false;
                else
                    % Starting a new empty set
                    hCodeblock.fast_skip_passes = hCodeblock.fast_skip_passes + 1;
                    empty_set = true;
                end
            else
                % This is a FAST Refinement pass
                if empty_set == true
                    if segment_bytes ~= 0
                        error('something wrong');
                    end
                    hCodeblock.fast_skip_passes = hCodeblock.fast_skip_passes + segment_passes;
                else
                    secondary_passes = segment_passes;
                    secondary_byte = segment_bytes;
                end
            end
            if DEBUG == 2
                fprintf('2nd bits = %2d, LBlock = %2d, new_passes = %2d, length = %4d', bits_to_read, hCodeblock.LBlock, new_passes, segment_bytes); %%%%%%
            end
            hCodeblock.num_passes = hCodeblock.num_passes + uint8(segment_passes);
            hCodeblock.pass_length(hCodeblock.num_passes + 0) = segment_bytes;
            number_of_bytes = number_of_bytes + segment_bytes;
        end
    else
        new_passes = new_passes - int32(segment_passes);
        hCodeblock.pass_length(hCodeblock.num_passes + 0) = segment_bytes;
        while new_passes > 0
            if bypass_term_threshold ~= 0
                if new_passes > 1
                    segment_passes = next_segment_passes;
                else
                    segment_passes = 1;
                end
                next_segment_passes = 3 - next_segment_passes;
                bits_to_read = hCodeblock.LBlock + segment_passes - 1;
            else
                assert(bitand(hCodeblock.Cmodes, RESTART) ~= 0);
                segment_passes = 1;
                bits_to_read = hCodeblock.LBlock;
            end
            segment_bytes = packetHeader.get_bits(bits_to_read);
            new_passes = new_passes - int32(segment_passes);
            hCodeblock.num_passes = hCodeblock.num_passes + uint8(segment_passes);
            hCodeblock.pass_length(hCodeblock.num_passes + 0) = segment_bytes;
            number_of_bytes = number_of_bytes + segment_bytes;
            if DEBUG == 2
                fprintf('2nd bits = %2d, LBlock = %2d, new_passes = %2d, length = %4d', bits_to_read, hCodeblock.LBlock, new_passes, segment_bytes); %%%%%%
            end
        end
    end
else
    % this layer has no contribution from this codeblock
    hCodeblock.layer_passes(layer_idx + M_OFFSET) = uint32(0);
end
% length information will be determined later.
