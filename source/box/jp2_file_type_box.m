classdef jp2_file_type_box < jp2_box_base
    properties
        BR uint32
        MinV uint32
        CLi uint32
    end
    methods
        function read_contents(inObj) 
            inObj.BR = get_dword(inObj.DBox);
            Brand = convert_uint32_to_char(inObj.BR);
            assert(strcmp(Brand, 'jp2 ') || strcmp(Brand, 'jpx ') || strcmp(Brand, 'jph '));
            
            inObj.MinV = get_dword(inObj.DBox);
            if inObj.MinV ~= 0
                fprintf('WARNING: The value of minor version in FileType Box is invalid.');
            end
            
            i = 1;
            while inObj.DBox.pos < length(inObj.DBox.buf)
                inObj.CLi(i) = get_dword(inObj.DBox);
                i = i + 1;
            end
            assert(ismember(1785737760, inObj.CLi) || ismember(1785751584, inObj.CLi)); % at least one CLi shall be 'jp2 ' or 'jph '
            inObj.is_read = true;
        end
        function set_contents(inObj, main_header)
            if isempty(main_header.CAP) == false
                inObj.BR = hex2dec('6A706820'); % 'jph '
                inObj.CLi = hex2dec('6A706820');
            else
                inObj.BR = hex2dec('6A703220'); % 'jp2 '
                inObj.CLi = hex2dec('6A703220');
            end
            inObj.MinV = 0;
            inObj.TBox = hex2dec('66747970'); % 'ftyp'
            inObj.LBox = 4+4+4+4;
            for i = 1:length(inObj.CLi)
                inObj.LBox = inObj.LBox + 4;
            end
        end
        function write_contents(inObj, hDdst)
            assert(isa(hDdst,'jp2_data_destination'));
            inObj.write_box_base(hDdst);
            hDdst.put_dword(inObj.BR);
            hDdst.put_dword(inObj.MinV);
            for i = 1:length(inObj.CLi)
                hDdst.put_dword(inObj.CLi(i));
            end
        end
    end
end
