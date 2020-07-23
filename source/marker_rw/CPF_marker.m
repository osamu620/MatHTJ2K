classdef CPF_marker < handle
    properties
        Lcpf(1, 1) uint16
        Pcpf(1, :) uint16
        is_read logical
    end
    methods
        function outObj = CPF_marker
            outObj.is_read = false;
        end
        function read_CPF(inObj, hDsrc)
            assert(isa(hDsrc, 'jp2_data_source'));
            assert(isa(inObj, 'CPF_marker'), 'input for read_CPF() shall be CPF_marker class.');
            inObj.Lcpf = hDsrc.get_word();
            N = (inObj.Lcpf - 2) / 2;
            for i = 1:N
                inObj.Pcpf(i) = hDsrc.get_word();
            end
        end
    end
end