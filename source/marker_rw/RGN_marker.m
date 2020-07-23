classdef RGN_marker < matlab.mixin.Copyable
    properties
        Lrgn uint16
        Crgn uint16
        Srgn uint8
        SPrgn uint8
        is_read logical
    end
    methods
        function outObj = RGN_marker()
            if nargin == 0
                outObj.Lrgn = 0;
                outObj.Crgn = 0;
                outObj.Srgn = 0;
                outObj.SPrgn = 0;
                outObj.is_read = false;
            end
        end
        function read_RGN(inObj, hDsrc, Csiz)
            assert(isa(hDsrc, 'jp2_data_source'));
            assert(isa(inObj, 'RGN_marker'), 'input for readRGNmarker() shall be RGN_marker class.');
            inObj.Lrgn = get_word(hDsrc);
            if Csiz < 257
                assert(inObj.Lrgn == 5);
                inObj.Crgn = get_byte(hDsrc);
            else
                assert(inObj.Lrgn == 6);
                inObj.Crgn = get_word(hDsrc);
            end
            inObj.Srgn = get_byte(hDsrc);
            assert(inObj.Srgn == 0);
            inObj.SPrgn = get_byte(hDsrc);
            inObj.is_read = true;
        end
    end
    methods (Access = protected)
        function cp = copyElement(inObj)
            cp = RGN_marker;
            cp.Lrgn = inObj.Lrgn;
            cp.Crgn = inObj.Crgn;
            cp.Srgn = inObj.Srgn;
            cp.SPrgn = inObj.SPrgn;
            cp.is_read = inObj.is_read;
        end
    end
end