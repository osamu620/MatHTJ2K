classdef state_MR_dec < handle
    properties
        MR_pos int32
        MR_bits uint8 
        MR_last uint8
        MR_tmp  uint8
        Dref uint8
    end
    methods
        function outObj = state_MR_dec(buf)
            outObj.MR_bits = 0;
            outObj.MR_last = 255;
            outObj.MR_tmp = 0;
            if isempty(buf) == true
                outObj.Dref = [];
                outObj.MR_pos = -1;
            else
                outObj.Dref = buf;
                outObj.MR_pos = length(buf) - 1;
            end
        end
    end
end