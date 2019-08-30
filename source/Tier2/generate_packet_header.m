function generate_packet_header(packetHeader, hPband, l, is_simulation)%%%%%% NEED TO BE CORRECTED
DEBUG = 0;
M_OFFSET = 1;
if hPband.numCblksX*hPband.numCblksY == 0
    return;
end

if is_simulation == true
    inclusionTree = copy(hPband.inclusionInfo);
    ZBPTree = copy(hPband.ZBPInfo);
else
    inclusionTree = hPband.inclusionInfo;
    ZBPTree = hPband.ZBPInfo;
end

for i = 1:hPband.numCblksX*hPband.numCblksY
    assert(inclusionTree.node(i).is_set == true);
    assert(ZBPTree.node(i).is_set == true);
end
inclusionTree.set_value_for_tagTreeNodes;
ZBPTree.set_value_for_tagTreeNodes;


for rasterCblkIdx=1:hPband.numCblksY*hPband.numCblksX
    hCodeblock = hPband.Cblks(rasterCblkIdx);
    CB_BYPASS  = bitand(hCodeblock.Cmodes , 1);
    %CB_RESET   = bitshift(bitand(hCodeblock.Cmodes , 2), -1);
    CB_RESTART = bitshift(bitand(hCodeblock.Cmodes , 4), -2);
    %CB_CAUSAL  = bitshift(bitand(hCodeblock.Cmodes , 8), -3);
    %CB_ERTERM  = bitshift(bitand(hCodeblock.Cmodes ,16), -4);
    %CB_SEGMARK = bitshift(bitand(hCodeblock.Cmodes ,32), -5);
    CB_HT      = bitshift(bitand(hCodeblock.Cmodes ,64), -6);
    
    previous_layer_num_pass = sum(hCodeblock.layer_passes(1:l+M_OFFSET)) - hCodeblock.layer_passes(l+M_OFFSET);% z_{l-1} = z_l - \delta z_l % see p.516
    %% inclusion tagtree coding
    if previous_layer_num_pass == 0 %hCodeblock.already_included == false && hCodeblock.layer_start(l+M_OFFSET) == 0
        if DEBUG == 1
            fprintf('-----------------------\n');
            fprintf('\t\tinclusion start\n');
        end
        current_node = inclusionTree.node(rasterCblkIdx);
        tree_path = current_node.idx;
        while current_node.parent_idx ~= 0
            current_node = inclusionTree.node(current_node.parent_idx);
            tree_path = [tree_path current_node.idx];
        end
        threshold = l; % = layer idx
        for i=length(tree_path):-1:1
            current_node =  inclusionTree.node(tree_path(i));
            if current_node.state == 0
                if current_node.level > 0 % note root node
                    if current_node.current_value < inclusionTree.node(current_node.parent_idx).current_value
                        current_node.current_value = inclusionTree.node(current_node.parent_idx).current_value;
                    end
                end
                if current_node.current_value <= threshold
                    if current_node.value <= threshold
                        packetHeader.put_bit(1);
                        current_node.state = 1;
                    else
                        packetHeader.put_bit(0);
                        current_node.current_value = current_node.current_value + 1;
                    end
                end
            end
        end
        if DEBUG == 1
            fprintf('\t\tinclusion end\n');
        end
        
        %% Number of zero bit plane tagtree coding
        if  hCodeblock.layer_passes(l+M_OFFSET) > 0
            % if we get to here, this codeblock is included in a packet.
            hCodeblock.already_included = true;
            hCodeblock.LBlock = 3;
            if DEBUG == 1
                fprintf('\t\tZBP start\n');
            end
            
            current_node = ZBPTree.node(rasterCblkIdx);
            tree_path = current_node.idx;
            while current_node.parent_idx ~= 0
                current_node = ZBPTree.node(current_node.parent_idx);
                tree_path = [tree_path current_node.idx];
            end
            
            for i=length(tree_path):-1:1
                current_node = ZBPTree.node(tree_path(i));
                if current_node.parent_idx == 0
                    threshold = 0;
                else
                    threshold = ZBPTree.node(current_node.parent_idx).value;
                end
                while current_node.state == 0
                    while threshold < current_node.value
                        packetHeader.put_bit(0);
                        threshold = threshold + 1;
                    end
                    current_node.state = 1;
                    packetHeader.put_bit(1);
                end
            end
            if DEBUG == 1
                fprintf('\t\tZBP end\n');
            end
        end
    else
        % if we get here, this codeblock has been included in at least one of preceding layers
        if DEBUG == 1
            fprintf('-----------------------\n');
            fprintf('\t\tinclusion sub start\n');
        end
        packetHeader.put_bit(uint8(min(1, hCodeblock.layer_passes(l+M_OFFSET))));
        if DEBUG == 1
            fprintf('\t\tinclusion sub end\n');
        end
    end
    if  hCodeblock.layer_passes(l+M_OFFSET) > 0
        %% number of coding passes
        if DEBUG == 1
            fprintf('\t\tnumpass start\n');
        end
        num_passes = uint8(hCodeblock.layer_passes(l+M_OFFSET));
        assert(num_passes < 165);
        if num_passes == 1
            packetHeader.put_bit(0);
        elseif num_passes == 2
            packetHeader.put_bits(2, 2);
        elseif num_passes < 6
            packetHeader.put_bits(bin2dec('11'), 2);
            packetHeader.put_bits(num_passes - 3, 2);
        elseif num_passes < 37
            packetHeader.put_bits(bin2dec('1111'), 4);
            packetHeader.put_bits(num_passes - 6, 5);
        else % num_passes >= 37
            packetHeader.put_bits(bin2dec('111111111'), 9);
            packetHeader.put_bits(num_passes - 37, 7);
        end
        
        if DEBUG == 1
            fprintf('\t\tnumpass end\n');
        end
        
        % compute number of coded bytes in this layer
        l0 = hCodeblock.layer_start(l+M_OFFSET);
        l1 = hCodeblock.layer_passes(l+M_OFFSET);
        
        if l0 ~= 0
            buf_start = sum(hCodeblock.pass_length(1:l0));
        else
            buf_start = 0;
        end
        buf_end = sum(hCodeblock.pass_length(1:l0+l1));
        number_of_bytes = buf_end - buf_start;
        
        
        %% Length encoding
        bypass_term_threshold = 0;
        if CB_BYPASS == true
            bypass_term_threshold = 10;
        end
        bits_to_write = 0;
        pass_idx = l0;
        segment_bytes = 0;
        segment_passes = 0;
        new_passes = num_passes;
        total_bytes = 0;
        %next_segment_passes = 0;
        
        while new_passes > 0
            if CB_RESTART == true
                segment_passes = 1;
            elseif bypass_term_threshold > 0
                if pass_idx < bypass_term_threshold
                    segment_passes = bypass_term_threshold - pass_idx;
                elseif mod(pass_idx - bypass_term_threshold, 3) == 0
                    segment_passes = 2;
                else
                    segment_passes = 1;
                end
                if segment_passes > new_passes
                    segment_passes = new_passes;
                end
            elseif CB_HT == true
                if pass_idx == 0 % This is the first HT Cleanup pass
                    segment_passes = 1;
                else
                    segment_passes = new_passes; % HT Sigprop and Magref(if exist)
                end
            else
                segment_passes = new_passes;
            end
            
            length_bits = 0;
            while bitshift(2, length_bits) <= segment_passes
                length_bits = length_bits + 1;
            end
            length_bits = length_bits + hCodeblock.LBlock;
            
            segment_bytes = 0;
            val = uint32(segment_passes);
            while val > 0
                segment_bytes = segment_bytes + hCodeblock.pass_length(pass_idx+val);
                val = val - 1;
            end
            
            while segment_bytes >= bitshift(1, length_bits)
                packetHeader.put_bit(1);
                length_bits = length_bits + 1;
                hCodeblock.LBlock = hCodeblock.LBlock + 1;
            end
            
            new_passes = new_passes - uint8(segment_passes);
            
            pass_idx = pass_idx + uint32(segment_passes);
            total_bytes = total_bytes + segment_bytes;
        end
        packetHeader.put_bit(0);
        
        
        bits_to_write = 0;
        pass_idx = l0;
        segment_bytes = 0;
        segment_passes = 0;
        new_passes = num_passes;
        total_bytes = 0;
        
        while new_passes > 0
            if CB_RESTART == true
                segment_passes = 1;
            elseif bypass_term_threshold > 0
                if pass_idx < bypass_term_threshold
                    segment_passes = bypass_term_threshold - pass_idx;
                elseif mod(pass_idx - bypass_term_threshold, 3) == 0
                    segment_passes = 2;
                else
                    segment_passes = 1;
                end
                if segment_passes > new_passes
                    segment_passes = new_passes;
                end
            elseif CB_HT == true
                if pass_idx == 0 % This is the first HT Cleanup pass
                    segment_passes = 1;
                else
                    segment_passes = new_passes; % HT Sigprop and Magref(if exist)
                end
            else
                segment_passes = new_passes;
            end
            
            length_bits = 0;
            while bitshift(2, length_bits) <= segment_passes
                length_bits = length_bits + 1;
            end
            length_bits = length_bits + hCodeblock.LBlock;
            
            segment_bytes = 0;
            val = uint32(segment_passes);
            while val > 0
                segment_bytes = segment_bytes + hCodeblock.pass_length(pass_idx+val);
                val = val - 1;
            end
            
            for n = length_bits - 1:-1:0
                bit = uint8(bitshift(bitand(segment_bytes, 2^n), -n));
                packetHeader.put_bit(bit);
            end
            
            if DEBUG == 1
                fprintf('\t\tBits to write is %d.\n',  length_bits);
                fprintf('\t\tlength is %d.\n',  segment_bytes);
            end
            new_passes = new_passes - uint8(segment_passes);
            
            pass_idx = pass_idx + uint32(segment_passes);
            total_bytes = total_bytes + segment_bytes;
        end
    end
end