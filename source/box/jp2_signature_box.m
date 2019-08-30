classdef jp2_signature_box < jp2_box_base
    properties
        signature uint32
    end
    methods
        function outObj = jp2_signature_box
            outObj.is_read = false;
        end
        function read_contents(inObj, hDsrc)
            assert(isa(hDsrc,'jp2_data_source'));
            inObj.read_box_base(hDsrc);
            inObj.signature = get_dword(inObj.DBox); 
            assert(inObj.signature == hex2dec('0D0A870A'));
            inObj.is_read = true;
        end
        function set_contents(inObj)
            inObj.LBox = 12;
            inObj.TBox = hex2dec('6A502020'); % 'jP  '
            inObj.signature = hex2dec('0D0A870A');
        end
        function write_contents(inObj, hDdst)
            assert(isa(hDdst,'jp2_data_destination'));
            inObj.write_box_base(hDdst);
            hDdst.put_dword(inObj.signature);
        end
    end
end
