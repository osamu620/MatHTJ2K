classdef packet_header_reader < handle
    properties
        hDsrc jp2_data_source
        byte uint8
        last_byte uint8
        bits int8
        num_header_bytes uint32
    end
    methods
        function outObj = packet_header_reader(hDsrc)
            outObj.hDsrc = hDsrc;
            outObj.byte = get_byte(outObj.hDsrc);
            outObj.last_byte = outObj.byte;
            outObj.bits = int8(8);
            outObj.num_header_bytes = uint32(1);
        end
        function bit = get_bit(inObj)
            if inObj.bits == 0
                inObj.byte = get_byte(inObj.hDsrc);
                % if the last byte was FF, next 1 bit shall be skipped.
                if inObj.last_byte == 255
                    inObj.bits = int8(7);
                else
                    inObj.bits = int8(8);
                end
                inObj.last_byte = inObj.byte;
                inObj.num_header_bytes = inObj.num_header_bytes + uint32(1);
            end
            inObj.bits = inObj.bits - int8(1);
            bit = bitand(bitshift(inObj.byte, -inObj.bits), uint8(1));
            % DEBUG
            %fprintf('\t\t  byte: %d, bit:%d, bits_left %d pos: %d\n', inObj.byte, bit, inObj.bits, inObj.num_header_bytes);
        end
        function codeword = get_bits(inObj, bits_to_read)
            codeword = uint32(0);
            for i = 1:bits_to_read
                if inObj.bits == 0
                    inObj.byte = get_byte(inObj.hDsrc);
                    % if the last byte was FF, next 1 bit shall be skipped.
                    if inObj.last_byte == 255
                        inObj.bits = int8(7);
                    else
                        inObj.bits = int8(8);
                    end
                    inObj.last_byte = inObj.byte;
                    inObj.num_header_bytes = inObj.num_header_bytes + uint32(1);
                end
                inObj.bits = inObj.bits - 1;
                bit = bitand(bitshift(inObj.byte, -inObj.bits), uint8(1));
                % DEBUG
                %fprintf('\t\t  byte: %d, bit:%d, bits_left %d pos: %d\n', inObj.byte, bit, inObj.bits, inObj.num_header_bytes);
                codeword = bitshift(codeword, 1) + uint32(bit);
            end
        end
        function flush(inObj)
            inObj.bits = 0;
        end
    end
end