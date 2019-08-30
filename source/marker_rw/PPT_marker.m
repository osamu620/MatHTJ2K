classdef PPT_marker < handle
    properties
        Lppt uint16
        Zppt uint8
        Ippt (1,:) uint8
        is_read logical
    end
    methods
        function outObj = PPT_marker
            assert(nargin == 0);
            outObj.is_read = false;
        end
        function read_PPT(inObj, hDsrc)
            assert(isa(hDsrc,'jp2_data_source'));
            assert(isa(inObj,'PPT_marker'), 'input for read_PPT() shall be PPT_marker class.');
            inObj.Lppt = get_word(hDsrc);
            assert(inObj.Lppt >= 4 && inObj.Lppt <= 65535);
            inObj.Zppt = get_byte(hDsrc);
            assert(inObj.Zppt >= 0 && inObj.Zppt <= 255);
            inObj.Ippt = get_N_byte(hDsrc, uint32(inObj.Lppt - 3));
        end
        function create_PPT(inObj, hTile)
            inObj.Ippt = [];
            inObj.Zppt = 0;
            num_packet = length(hTile.packetInfo);
            for i = 0:num_packet - 1
                obj = findobj(hTile.packetInfo, 'idx', i);
                inObj.Ippt = [inObj.Ippt obj.header];
            end
            inObj.Lppt = length(inObj.Ippt) + 3;
        end
        function write_PPT(inObj, m, hDdst)
            assert(isa(hDdst,'jp2_data_destination'));
            assert(isa(inObj,'PPT_marker'), 'input for write_PPT() shall be PPT_marker class.');
            hDdst.put_word(m.PPT);
            hDdst.put_word(inObj.Lppt);
            hDdst.put_byte(inObj.Zppt);
            hDdst.put_N_byte(inObj.Ippt);
        end
    end
end