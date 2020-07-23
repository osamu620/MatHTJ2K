classdef SOT_marker < handle
    properties
        Lsot uint16
        Isot uint16
        Psot uint32
        TPsot uint8
        TNsot uint8
        is_read logical
    end
    methods
        function read_SOT(inObj, hDsrc)
            assert(isa(hDsrc, 'jp2_data_source'));
            assert(isa(inObj, 'SOT_marker'), 'input for readSOT() shall be SOT_marker class.');
            inObj.Lsot = get_word(hDsrc);
            assert(inObj.Lsot == 10, 'Lsot is wrong');
            inObj.Isot = get_word(hDsrc);
            inObj.Psot = get_dword(hDsrc);
            inObj.TPsot = get_byte(hDsrc);
            inObj.TNsot = get_byte(hDsrc);
            inObj.is_read = true;
        end
        function write_SOT(inObj, m, hDdst)
            assert(isa(hDdst, 'jp2_data_destination'));
            assert(isa(inObj, 'SOT_marker'), 'input for writeSOT() shall be SOT_marker class.');
            put_word(hDdst, m.SOT); %SOT
            put_word(hDdst, inObj.Lsot);
            put_word(hDdst, inObj.Isot);
            put_dword(hDdst, inObj.Psot);
            put_byte(hDdst, inObj.TPsot);
            put_byte(hDdst, inObj.TNsot);
        end
        function out = get_tile_index(inObj)
            out = inObj.Isot;
        end
        function out = get_length(inObj)
            out = inObj.Psot;
        end
        function out = get_tile_part_index(inObj)
            out = inObj.TPsot;
        end
        function out = get_number_of_tile_parts(inObj)
            out = inObj.TNsot;
        end
    end
end
