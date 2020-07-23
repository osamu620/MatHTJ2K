classdef PPM_marker < handle
    properties
        Lppm uint16
        Zppm uint8
        Nppm(1, :) uint32
        Ippm(1, :) uint8
        ppmbuf(1, :) uint8
        is_read logical
    end
    methods
        function outObj = PPM_marker
            assert(nargin == 0);
            outObj.is_read = false;
        end
        function read_PPM(inObj, hDsrc)
            assert(isa(hDsrc, 'jp2_data_source'));
            assert(isa(inObj, 'PPM_marker'), 'input for read_PPM() shall be PPM_marker class.');
            inObj.Lppm = get_word(hDsrc);
            assert(inObj.Lppm >= 7 && inObj.Lppm <= 65535);
            inObj.Zppm = get_byte(hDsrc);
            remain_length = uint32(inObj.Lppm - 3);
            inObj.ppmbuf = get_N_byte(hDsrc, remain_length);
            inObj.is_read = true;
        end
        function write_PPM(inObj, m, hDdst, hTile, numTiles)
            assert(isa(hDdst, 'jp2_data_destination'));
            assert(isa(inObj, 'PPM_marker'), 'input for write_PPM() shall be PPM_marker class.');

            len = 0;
            inObj.Zppm = 0;

            buf = cell(1, numTiles);
            t_count = 0;
            for i = 1:numTiles
                t_buf = [];
                num_packet = length(hTile(i).packetInfo);
                for j = 0:num_packet - 1
                    obj = findobj(hTile(i).packetInfo, 'idx', j);
                    t_buf = [t_buf, obj.header];
                end
                inObj.Nppm(i) = length(t_buf);
                buf{i} = t_buf;
                if (len + uint16(inObj.Nppm(i)) + t_count * 4 + 3) > 65535 || i == numTiles %% need to consider in packet
                    hDdst.put_word(m.PPM);
                    inObj.Lppm = 0;
                    for n = i - t_count:i
                        inObj.Lppm = inObj.Lppm + uint16(inObj.Nppm(n));
                    end
                    inObj.Lppm = inObj.Lppm + (t_count + 1) * 4 + 3;
                    hDdst.put_word(inObj.Lppm);
                    hDdst.put_byte(inObj.Zppm);
                    for n = i - t_count:i
                        hDdst.put_dword(inObj.Nppm(n));
                        hDdst.put_N_byte(buf{n});
                    end
                    t_count = 0;
                    len = 0;
                    inObj.Zppm = inObj.Zppm + 1;
                else
                    len = len + uint16(inObj.Nppm(i));
                    t_count = t_count + 1;
                end
            end
        end
    end
end