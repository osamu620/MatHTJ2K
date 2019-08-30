classdef jp2_data_source < handle
    properties
        buf uint8
        pos uint32
    end
    methods
        function outObj = jp2_data_source(filebuf)
            if nargin ~= 0
                outObj.pos = 0;
                outObj.buf = filebuf;
            else
                outObj.pos = 0;
                outObj.buf = [];
            end
        end
        function byte = get_byte(inObj)
             byte = inObj.buf(inObj.pos + uint32(1));
            inObj.pos = inObj.pos + uint32(1);
        end
        function word = get_word(inObj)
            byte = get_byte(inObj);
            word = uint16(byte)*uint16(256) + uint16(get_byte(inObj));
        end
        function dword = get_dword(inObj)
            byte = get_byte(inObj);
            word = uint16(byte)*uint16(256) + uint16(get_byte(inObj));
            dword = uint32(word)*uint32(65536) + uint32(get_word(inObj));
        end
        function bytes = get_N_byte(inObj, n)
            if n > 0
                bytes = inObj.buf(inObj.pos+1:inObj.pos+n);
                inObj.pos = inObj.pos + uint32(n);
            else
                bytes = [];
            end
        end
        % Destructor
        function delete(Obj)
            % do nothing
        end
    end
end

