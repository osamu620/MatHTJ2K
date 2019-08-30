function create_packet_body(hCodeblock, l, hPacket)
    M_OFFSET = 1;
    l0 = hCodeblock.layer_start(l+M_OFFSET);
    l1 = hCodeblock.layer_passes(l+M_OFFSET);
    if l1 > 0
        number_of_bytes = sum(hCodeblock.pass_length(l0+M_OFFSET:l0+l1));
        if l0 ~= 0
            buf_start = sum(hCodeblock.pass_length(1:l0));
        else
            buf_start = 0;
        end
        buf_end = sum(hCodeblock.pass_length(1:l0+l1));
        assert(buf_end-buf_start == number_of_bytes);
        buf = hCodeblock.compressed_data(buf_start+M_OFFSET:buf_end);
        hPacket.body = [hPacket.body buf];
    end
end