classdef CRG_marker < handle
    properties
        Lcrg uint16
        Xcrg (1,:) uint16
        Ycrg (1,:) uint16
        is_read logical
    end
    methods
        function outObj = CRG_marker
            assert(nargin == 0);
            outObj.is_read = false;
        end
        function read_CRG(inObj, hDsrc, Csiz)
            assert(isa(hDsrc,'jp2_data_source'));
            assert(isa(inObj,'CRG_marker'), 'input for readCRGmarker() shall be CRG_marker class.');
            inObj.Lcrg = get_word(hDsrc);
            assert(inObj.Lcrg >= 6 && inObj.Lcrg <= 65534);
            for i = 1:Csiz
                inObj.Xcrg = get_word(hDsrc);
                inObj.Ycrg = get_word(hDsrc);
            end
            inObj.is_read = true;
        end
    end
end