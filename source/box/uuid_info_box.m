classdef uuid_info_box < jp2_box_base
    properties
        Ulist uuid_list_box
        DE data_entry_url_box
    end
    methods
        function read_contents(inObj)
            while inObj.DBox.pos < length(inObj.DBox.buf)
                hBox = jp2_box_base;
                hBox.read_box_base(inObj.DBox);
                switch convert_uint32_to_char(hBox.TBox)
                    case 'ulst'
                        inObj.Ulist = uuid_list_box(hBox);
                        inObj.Ulist.read_contents();
                    case 'url '
                        inObj.DE = data_entry_url_box(hBox);
                        inObj.DE.read_contents();
                    otherwise
                        fprintf('Unkown box is found in _UUID Info Box\n');
                end
            end
            inObj.is_read = true;
        end
    end
end
