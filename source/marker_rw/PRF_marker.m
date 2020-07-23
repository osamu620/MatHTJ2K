classdef PRF_marker < handle
    properties
        Lprf(1, 1) uint16
        Pprf(1, :) uint16
    end
    methods
        function read_PRF(inObj, hDsrc)
            assert(isa(hDsrc, 'jp2_data_source'));
            assert(isa(inObj, 'PRF_marker'), 'input for read_PRF() shall be PRF_marker class.');
            inObj.Lprf = hDsrc.get_word();
            assert(inObj.Lprf >= 4 && inObj.Lprf <= 65534);
            n = (inObj.Lprf - 2) / 2;
            PRFnum = 4095;
            inObj.Pprf = zeros(1, n);
            for i = 1:n
                inObj.Pprf(i) = hDsrc.get_word();
                PRFnum = PRFnum + inObj.Pprf(i) * 2^(16 * (i - 1));
            end
        end
    end
end