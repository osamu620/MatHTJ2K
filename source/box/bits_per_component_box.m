classdef bits_per_component_box < jp2_box_base
    properties
        BPC uint8
    end
    methods
        function read_contents(inObj)
            i = 1;
            num_bytes = 4 + 4; %LBox + TBox
            while num_bytes < inObj.LBox
                inObj.BPC(i) = get_byte(inObj.DBox);
                i = i + 1;
                num_bytes = num_bytes + 1;
            end
            inObj.is_read = true;
        end
        function set_contents(inObj, main_header)
            inObj.LBox = 8;
            inObj.TBox = hex2dec('62706363'); % 'bpcc'
            for i = 1:main_header.SIZ.Csiz
                inObj.BPC(i) = main_header.SIZ.Ssiz(i);
            end
        end
        function write_contents(inObj, hDdst)
            assert(isa(hDdst, 'jp2_data_destination'));
            inObj.write_box_base(hDdst);
            for i = 1:length(inObj.BPC)
                hDdst.put_byte(inObj.BPC(i));
            end
        end
    end
end