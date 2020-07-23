classdef image_header_box < jp2_box_base
    properties
        HEIGHT uint32
        WIDTH uint32
        NC uint16
        BPC uint8
        C uint8
        UnkC uint8
        IPR uint8
    end
    methods
        function outObj = image_header_box(inObj)
            if nargin == 1
                outObj.LBox = inObj.LBox;
                outObj.XLBox = inObj.XLBox;
                outObj.TBox = inObj.TBox;
                outObj.DBox = inObj.DBox;
                outObj.is_read = false;
            end
        end
        function read_contents(inObj)
            inObj.HEIGHT = get_dword(inObj.DBox);
            inObj.WIDTH = get_dword(inObj.DBox);
            inObj.NC = get_word(inObj.DBox);
            inObj.BPC = get_byte(inObj.DBox);
            inObj.C = get_byte(inObj.DBox);
            inObj.UnkC = get_byte(inObj.DBox);
            inObj.IPR = get_byte(inObj.DBox);
            inObj.is_read = true;
        end
        function set_contents(inObj, main_header)
            inObj.LBox = 22;
            inObj.TBox = hex2dec('69686472'); % 'ihdr'
            inObj.HEIGHT = main_header.SIZ.Ysiz - main_header.SIZ.YOsiz;
            inObj.WIDTH = main_header.SIZ.Xsiz - main_header.SIZ.XOsiz;
            inObj.NC = main_header.SIZ.Csiz;
            val = main_header.SIZ.Ssiz(1);
            if inObj.NC > 1
                for i = 2:inObj.NC
                    if val ~= main_header.SIZ.Ssiz(i)
                        val = 255;
                        break;
                    end
                end
            end
            inObj.BPC = val;
            inObj.C = 7;
            inObj.UnkC = 0;
            inObj.IPR = 0;
        end
        function write_contents(inObj, hDdst)
            assert(isa(hDdst, 'jp2_data_destination'));
            inObj.write_box_base(hDdst);
            hDdst.put_dword(inObj.HEIGHT);
            hDdst.put_dword(inObj.WIDTH);
            hDdst.put_word(inObj.NC);
            hDdst.put_byte(inObj.BPC);
            hDdst.put_byte(inObj.C);
            hDdst.put_byte(inObj.UnkC);
            hDdst.put_byte(inObj.IPR);
        end
    end
end
