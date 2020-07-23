classdef jp2_boxes < handle
    properties
        hDdst jp2_data_destination
        hDsrc jp2_data_source
        signatureBox jp2_signature_box
        fileTypeBox jp2_file_type_box
        headerBox jp2_header_box
        codestream
        XMLBox xml_box
        UUIDBox uuid_box
        UUIDInfoBox uuid_info_box
    end
    methods
        function outObj = jp2_boxes(in, enc)
            if enc == 0
                outObj.hDsrc = in;
            else
                outObj.hDdst = in;
            end
        end
        function read_contents(inObj)
            inObj.signatureBox = jp2_signature_box;
            inObj.signatureBox.read_contents(inObj.hDsrc);
            assert(inObj.signatureBox.LBox == 12 && strcmp(convert_uint32_to_char(inObj.signatureBox.TBox), 'jP  '));

            hBox = jp2_box_base;
            hBox.read_box_base(inObj.hDsrc);

            while (inObj.hDsrc.pos <= length(inObj.hDsrc.buf))
                switch convert_uint32_to_char(hBox.TBox)
                    case 'ftyp'
                        fprintf('File Type box\n');
                        inObj.fileTypeBox = jp2_file_type_box(hBox);
                        inObj.fileTypeBox.read_contents();
                    case 'jp2h'
                        fprintf('JP2 Header box\n');
                        inObj.headerBox = jp2_header_box(hBox);
                        inObj.headerBox.read_contents();
                    case 'jp2c'
                        fprintf('Contiguous Codestream box\n');
                        inObj.codestream = get_N_byte(hBox.DBox, hBox.LBox - 8);
                    case 'jp2i'
                        fprintf('Intellectual Property box\n');
                    case 'xml '
                        fprintf('XML box\n');
                        inObj.XMLBox = [inObj.XMLBox, xml_box(hBox)];
                        inObj.XMLBox(end).read_contents();
                    case 'uuid'
                        fprintf('UUID box\n');
                        inObj.UUIDBox = [inObj.UUIDBox, uuid_box(hBox)];
                        inObj.UUIDBox(end).read_contents();
                    case 'uinf'
                        fprintf('UUID Info box\n');
                        inObj.UUIDInfoBox = [inObj.UUIDInfoBox, uuid_info_box(hBox)];
                        inObj.UUIDInfoBox(end).read_contents();
                    otherwise
                        fprintf('Unkown box found\n');
                end
                if inObj.hDsrc.pos == length(inObj.hDsrc.buf)
                    break;
                end
                hBox.read_box_base(inObj.hDsrc);
            end
        end
        function write_contents(inObj, main_header, total_length)
            inObj.signatureBox = jp2_signature_box;
            inObj.signatureBox.set_contents();
            inObj.signatureBox.write_contents(inObj.hDdst);
            inObj.fileTypeBox = jp2_file_type_box;
            inObj.fileTypeBox.set_contents(main_header);
            inObj.fileTypeBox.write_contents(inObj.hDdst);
            inObj.headerBox = jp2_header_box;
            inObj.headerBox.set_contents(main_header);
            inObj.headerBox.write_contents(inObj.hDdst);
            inObj.hDdst.put_dword(total_length + 8); % LBox value of Contiguous Codestream box
            inObj.hDdst.put_dword(uint32(hex2dec('6A703263'))); % TBox value of Contiguous Codestream box, 'jp2c'
        end
    end
end
