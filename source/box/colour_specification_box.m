classdef colour_specification_box < jp2_box_base
    properties
        METH uint8
        PREC uint8
        APPROX uint8
        EnumCS uint32
        PROFILE uint8
        COLPRIMS uint16
        TRANSFC uint16
        MATCOEFFS uint16
        VIDFRNG logical
        VIDFRNG_RSVD uint8
    end
    methods
        function read_contents(inObj)
            inObj.METH = get_byte(inObj.DBox);
            inObj.PREC = get_byte(inObj.DBox);
            inObj.APPROX = get_byte(inObj.DBox);
            if inObj.METH == 1
                fprintf('Enumerated Colourspace\n');
                inObj.EnumCS = get_dword(inObj.DBox);
            elseif inObj.METH == 2
                fprintf('Rstricted ICC profile\n');
                inObj.PROFILE = get_N_byte(inObj.DBox, inObj.LBox - (4 + 4 + 3));
                fid = fopen('tmpicc.icc', 'wb');
                fwrite(fid, inObj.PROFILE);
                fclose(fid);
            elseif inObj.METH == 3
                fprintf('Any ICC profile\n');
                inObj.PROFILE = get_N_byte(inObj.DBox, inObj.LBox - (4 + 4 + 3));
            else
                fprintf('Parameterized Colourspace\n');
                assert(inObj.METH == 5);
                inObj.COLPRIMS = get_word(inObj.DBox);
                inObj.TRANSFC = get_word(inObj.DBox);
                inObj.MATCOEFFS = get_word(inObj.DBox);
                val = get_byte(inObj.DBox);
                inObj.VIDFRNG = bitand(val, 1);
                inObj.VIDFRNG_RSVD = bitand(val, 127);
            end
            inObj.is_read = true;
        end
        function set_contents(inObj, main_header)
            inObj.LBox = 8 + 1 + 1 + 1 + 4;
            inObj.TBox = hex2dec('636F6C72'); % colr
            inObj.METH = 1;
            if main_header.SIZ.Csiz == 3
                inObj.EnumCS = 16;
            else %if main_header.SIZ.Csiz == 1
                inObj.EnumCS = 17;
            end
            inObj.PREC = 0;
            inObj.APPROX = 0;
        end
        function write_contents(inObj, hDdst)
            assert(isa(hDdst, 'jp2_data_destination'));
            inObj.write_box_base(hDdst);
            hDdst.put_byte(inObj.METH);
            hDdst.put_byte(inObj.PREC);
            hDdst.put_byte(inObj.APPROX);
            hDdst.put_dword(inObj.EnumCS);
        end
    end
end