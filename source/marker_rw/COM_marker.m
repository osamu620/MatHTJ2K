classdef COM_marker < handle
    properties
        Lcom uint16
        Rcom uint16
        comments uint8
        is_read logical
    end
    methods
        function outObj = COM_marker(comment, is_text)
            if nargin == 0
                outObj.is_read = false;
            else
                outObj.Lcom = 4 + length(comment);
                if is_text == true
                    outObj.Rcom = 1;
                else
                    outObj.Rcom = 0;
                end
                for i = 1:length(comment)
                    outObj.comments(i) = comment(i);
                end
            end
        end
        function read_COM(inObj, hDsrc)
            assert(isa(hDsrc, 'jp2_data_source'));
            assert(isa(inObj, 'COM_marker'), 'input for readCOMmarker() shall be COM_marker class.');
            %
            inObj.Lcom = get_word(hDsrc);
            inObj.Rcom = get_word(hDsrc);
            inObj.comments = zeros(1, inObj.Lcom - 4);
            for i = 1:inObj.Lcom - 4
                inObj.comments(i) = get_byte(hDsrc);
            end
            assert(inObj.Rcom < 2, 'Rcom value is incorrect.\n');
            if inObj.Rcom == 1 % text comments
                inObj.comments = char(inObj.comments);
            end
            inObj.is_read = true;
        end
        function write_COM(inObj, m, hDdst)
            assert(isa(hDdst, 'jp2_data_destination'));
            assert(isa(inObj, 'COM_marker'), 'input for write_COM() shall be COM_marker class.');
            put_word(hDdst, m.COM);
            put_word(hDdst, inObj.Lcom);
            put_word(hDdst, inObj.Rcom);
            for i = 1:inObj.Lcom - 4
                put_byte(hDdst, inObj.comments(i));
            end
        end
    end
end