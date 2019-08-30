classdef PLT_marker < handle
    properties
        Lplt uint16
        Zplt uint8
        Iplt (1,:) uint8
        is_read logical
    end
    methods
        function outObj = PLT_marker
            assert(nargin == 0);
            outObj.is_read = false;
        end
        function make_PLT(inObj, hTile)
            inObj.Zplt = 0; % currently, only one PLT marker segment per tile is supported.
            num_packet = length(hTile.packetInfo);
            Iplt_length = 0;
            for i = 1:num_packet
                len = length([hTile.packetInfo(i).header hTile.packetInfo(i).body]);
                bitlength = ceil(log2(len));
                count = 1;
                plen = [];
                for n = bitlength:-7:0
                    mask = bitshift(127, n - 7);
                    if n - 7 <= 0
                        shift = 0;
                    else
                        shift = n - 7;
                    end
                    plen(count) = bitshift(bitand(len, mask), -shift);
                    count = count + 1;
                end
                if length(plen) > 1
                    plen(1:end-1) = plen(1:end-1) + 128;
                end
                inObj.Iplt = [inObj.Iplt plen];
                Iplt_length = Iplt_length + length(plen);
            end
            inObj.Lplt = 2 + 1 + Iplt_length;
        end
        function read_PLT(inObj, hDsrc)
            assert(isa(hDsrc,'jp2_data_source'));
            assert(isa(inObj,'PLT_marker'), 'input for read_PLT() shall be PLT_marker class.');
            inObj.Lplt = get_word(hDsrc);
            assert(inObj.Lplt >= 4 && inObj.Lplt <= 65535);
            inObj.Zplt = get_byte(hDsrc);
            assert(inObj.Zplt >= 0 && inObj.Zplt <= 255);
            
            packet_length = zeros(1, inObj.Lplt);
            packet_idx = 1;
            for i = 1:inObj.Lplt - 3
                inObj.Iplt = get_byte(hDsrc);
                length = bitand(inObj.Iplt, 127);
                packet_length(packet_idx) = 128*packet_length(packet_idx) + length;
                if bitand(inObj.Iplt, 128) == 0
                    packet_idx = packet_idx + 1;
                    packet_length(packet_idx) = 0;
                end
            end
            packet_length = packet_length(1:packet_idx);
            assert(i == inObj.Lplt - 3);
        end
        function write_PLT(inObj, m, hDdst)
            assert(isa(hDdst,'jp2_data_destination'));
            assert(isa(inObj,'PLT_marker'), 'input for write_PLT() shall be PLT_marker class.');
            hDdst.put_word(m.PLT);
            hDdst.put_word(inObj.Lplt);
            hDdst.put_byte(inObj.Zplt);
            hDdst.put_N_byte(inObj.Iplt);
        end
    end
end