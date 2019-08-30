classdef state_SP_dec < handle
    properties
        SP_pos uint32
        SP_bits uint8 
        SP_tmp  uint8
        SP_last uint8
        Dref uint8
    end
    methods
        function outObj = state_SP_dec(buf)
            outObj.SP_pos = 0;
            outObj.SP_bits = 0;
            outObj.SP_tmp = 0;
            outObj.SP_last = 0;
            if isempty(buf) == true
                outObj.Dref = [];
            else
                outObj.Dref = buf;
            end
        end
    end
end