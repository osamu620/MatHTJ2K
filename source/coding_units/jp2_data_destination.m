classdef jp2_data_destination < handle
    properties
        type uint8
        ID double
        buf uint8
        pos uint32
    end

    methods
        function outObj = jp2_data_destination(t, name, maxsize)
            if nargin < 3
                maxsize = 1024 * 1024 * 10; % 10MB
            end
            outObj.type = t;
            outObj.pos = 0;
            if outObj.type == 0 % file
                outObj.ID = fopen(name, 'w');
            elseif outObj.type == 1 % array
                outObj.ID = 0;
                outObj.buf = zeros(1, maxsize, 'uint8'); % 5MB
            end
        end
        function put_byte(inObj, byte)
            assert(isscalar(byte));
            assert(isinteger(byte) && byte >= 0 && byte <= 2^8 - 1);
            if inObj.type == 0
                fwrite(inObj.ID, byte, 'uint8');
            elseif inObj.type == 1
                if inObj.pos + 1 > length(inObj.buf)
                    tmpbuf = inObj.buf;
                    inObj.buf = zeros(1, length(tmpbuf) + 4096, 'uint8');
                    inObj.buf(1:length(tmpbuf)) = tmpbuf;
                end
                inObj.buf(inObj.pos + 1) = byte;
            end
            inObj.pos = inObj.pos + 1;
        end
        function put_word(inObj, word)
            assert(isscalar(word));
            assert(isinteger(word) && word >= 0 && word <= 2^16 - 1);
            UpperByte = bitshift(word, -8);
            LowerByte = bitand(word, 255);
            put_byte(inObj, UpperByte);
            put_byte(inObj, LowerByte);
        end
        function put_dword(inObj, dword)
            assert(isscalar(dword));
            assert(isinteger(dword) && dword >= 0 && dword <= 2^32 - 1);
            UpperWord = bitshift(dword, -16);
            LowerWord = bitand(dword, 2^16 - 1);
            put_word(inObj, UpperWord);
            put_word(inObj, LowerWord);
        end
        function put_N_byte(inObj, bytes)
            assert(isvector(bytes));
            assert(isa(bytes, 'uint8'));
            if isempty(bytes) == false
                if inObj.type == 0 % file
                    fwrite(inObj.ID, bytes, 'uint8');
                elseif inObj.type == 1
                    inObj.buf(inObj.pos + 1:inObj.pos + length(bytes)) = bytes;
                end
                inObj.pos = inObj.pos + length(bytes);
            end
        end
        function flush(inObj)
            inObj.buf = inObj.buf(1:inObj.pos);
        end
        % Destructor
        function delete(Obj)
            if Obj.type == 0 % file
                fclose(Obj.ID);
            elseif Obj.type == 1 % array
                Obj.buf = [];
            end
        end
    end
end
