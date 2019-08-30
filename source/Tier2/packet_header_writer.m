classdef packet_header_writer < handle
    properties
        buf uint8
        byte uint8
        last_byte uint8
        bits uint8
        num_bytes uint32
    end
    methods
        function outObj = packet_header_writer
            outObj.buf = uint8(0);
            outObj.byte = uint8(0);
            outObj.last_byte = uint8(0);
            outObj.bits = uint8(8);
            outObj.num_bytes = uint32(0);
        end
        function put_bit(inObj, bit)            
            if inObj.bits == uint8(0)
                inObj.last_byte = inObj.byte;
                % if the last byte was FF, next 1 bit shall be skipped.
                if inObj.last_byte == 255
                    inObj.bits = uint8(7);
                else
                    inObj.bits = uint8(8);
                end
                % go to next byte
                inObj.buf(inObj.num_bytes + 1) = inObj.byte;
                inObj.num_bytes = inObj.num_bytes + 1;
                inObj.byte = uint8(0);
            end
            inObj.bits = inObj.bits - 1;
            inObj.byte = inObj.byte + bitshift(uint8(bit), inObj.bits);
            % DEBUG
            %fprintf('\t\t  bit: %d, byte: %d, bit_pos:%d\n', bit, inObj.byte, inObj.bits);
        end
        function  put_bits(inObj, codeword, bits_to_write)
            %codeword = uint32(0);
            for i = bits_to_write - 1:-1:0
                bit = bitand(bitshift(codeword, -i), 1);
                put_bit(inObj, bit);
            end
        end
        function flush(inObj, is_use_EPH)
            if inObj.bits > 0
                for i = 1:inObj.bits
                    put_bit(inObj, 0);
                end
            end
            inObj.buf(inObj.num_bytes + 1) = inObj.byte;
            inObj.num_bytes = inObj.num_bytes + 1;
            % if the last byte is 0xFF, a bit 0 shall be added.
            if inObj.byte == 255
                inObj.buf(inObj.num_bytes + 1) = 0;
                inObj.num_bytes = inObj.num_bytes + 1;
            end
            if is_use_EPH == true
                inObj.buf(inObj.num_bytes + 1:inObj.num_bytes + 2) = [255 146];
            end
        end
    end
end