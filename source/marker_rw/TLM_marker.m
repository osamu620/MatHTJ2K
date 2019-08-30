classdef TLM_marker < handle
    properties
        Ltlm uint16
        Ztlm uint8
        Stlm uint8
        Ttlm (1,:) uint16
        Ptlm (1,:) uint32
        is_read logical
    end
    methods
        function outObj = TLM_marker(ST, hTile)
            if nargin ~= 0
                assert(nargin == 2);
                nTile = length(hTile);
                SP = uint16(0);
                for n = 1:nTile
                    if hTile(n).SOT.Psot > 65535
                        SP = uint16(1);
                        break;
                    end
                end
                outObj.Stlm = uint8((SP*4 + ST)*16);
                outObj.Ztlm = 0;
                for n = 1:nTile
                    assert(isinteger(ST) && isinteger(SP) && ST >=0 && ST <= 2 && SP >=0 && SP<= 1);
                    if ST ~= 0
                        outObj.Ttlm(n) = n - 1;
                    end
                    outObj.Ptlm(n) = hTile(n).header.SOT.Psot;
                end
                outObj.Ltlm = 4 + (SP*2 + (2 + ST))*nTile;
            end
            outObj.is_read = false;
        end
        function read_TLM(inObj, hDsrc)
            assert(isa(hDsrc,'jp2_data_source'));
            assert(isa(inObj,'TLM_marker'), 'input for read_TLM() shall be TLM_marker class.');
            inObj.Ltlm = get_word(hDsrc);
            assert(inObj.Ltlm >= 6 && inObj.Ltlm <= 65535);
            inObj.Ztlm = get_byte(hDsrc);
            inObj.Stlm = get_byte(hDsrc);
            ST = uint16(bitand(bitshift(inObj.Stlm, -4), 3));
            SP = uint16(bitand(bitshift(inObj.Stlm, -6), 1));
            num_tile_parts = 0;
            if SP == 0
                num_tile_parts = (inObj.Ltlm - 4)/(2+ST);
            else
                assert(SP == 1);
                num_tile_parts = (inObj.Ltlm - 4)/(4+ST);
            end
             
            for i = 1:num_tile_parts
                if ST == 2
                    inObj.Ttlm(i) = get_word(hDsrc);
                elseif ST == 1
                    inObj.Ttlm(i)= get_byte(hDsrc);
                end
                if SP == 0
                    inObj.Ptlm(i) = uint32(get_word(hDsrc));
                elseif SP == 1
                    inObj.Ptlm(i) = get_dword(hDsrc);
                end
            end
            inObj.is_read = true;
        end
        function write_TLM(inObj, m, hDdst)
            assert(isa(hDdst,'jp2_data_destination'));
            assert(isa(inObj,'TLM_marker'), 'input for write_TLM() shall be TLM_marker class.');
            hDdst.put_word(m.TLM);
            hDdst.put_word(inObj.Ltlm);
            hDdst.put_byte(inObj.Ztlm);
            hDdst.put_byte(inObj.Stlm);
            num_tile_parts = 0;
            ST = bitand(bitshift(inObj.Stlm, -4), 3);
            SP = bitshift(inObj.Stlm, -6);
            if SP == 0
                num_tile_parts = (inObj.Ltlm - 4)/uint16(2+ST);
            else
                assert(SP == 1);
                num_tile_parts = (inObj.Ltlm - 4)/uint16(4+ST);
            end 
            for i = 1:num_tile_parts
                if ST ~= 0
                    if ST == 1
                        hDdst.put_byte(inObj.Ttlm(i));
                    else
                        assert(ST == 2);
                        hDdst.put_word(inObj.Ttlm(i));
                    end
                end
                if SP == 0
                    hDdst.put_word(inObj.Ptlm(i));
                else
                    assert(SP == 1);
                    hDdst.put_dword(inObj.Ptlm(i));
                end
            end
        end
    end
end