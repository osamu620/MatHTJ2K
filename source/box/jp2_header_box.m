classdef jp2_header_box < jp2_box_base
    properties
        ihdr image_header_box
        bpcc bits_per_component_box
        colr colour_specification_box
        pclr palette_box
        cmap component_mapping_box
        cdef channel_definition_box
        res resolution_box
    end
    methods
        function read_contents(inObj)
            %assert(isa(hDsrc,'jp2_data_source'));
            inObj.LBox = get_dword(inObj.DBox);
            assert(inObj.LBox == 22);
            tmpTBox = get_dword(inObj.DBox);
            assert(strcmp(convert_uint32_to_char(tmpTBox), 'ihdr'));
            inObj.ihdr = image_header_box(inObj);
            
            inObj.ihdr.read_contents();
            while inObj.DBox.pos < length(inObj.DBox.buf)
                hBox = jp2_box_base;
                hBox.read_box_base(inObj.DBox);
                switch convert_uint32_to_char(hBox.TBox)
                    case 'bpcc'
                        fprintf('Bits Per Component box\n');
                        inObj.bpcc = bits_per_component_box(hBox);
                        inObj.bpcc.read_contents();
                    case 'colr'
                        fprintf('Colour Specification box\n');
                        inObj.colr = [inObj.colr colour_specification_box(hBox)];
                        inObj.colr(end).read_contents();
                    case 'pclr'
                        fprintf('Palette box\n');
                        inObj.pclr = palette_box(hBox);
                        inObj.pclr.read_contents();
                    case 'cmap'
                        fprintf('Component Mapping box\n');
                        inObj.cmap = component_mapping_box(hBox);
                        inObj.cmap.read_contents();
                    case 'cdef'
                        fprintf('Channel Definition box\n');
                        inObj.cdef = channel_definition_box(hBox);
                        inObj.cdef.read_contents();
                    case 'res '
                        fprintf('Resolution box\n');
                        inObj.res = resolution_box(hBox);
                        inObj.res.read_contents();
                    otherwise
                        fprintf('Unkown box is found in JP2 Header box\n');
                end
            end
            if inObj.ihdr.UnkC == 0
                assert(isempty(inObj.colr) == false, 'ERROR: Colour Specification box shall be appear when UnkC = 0');
            end
            inObj.is_read = true;
        end
        function set_contents(inObj, main_header)
            inObj.TBox = hex2dec('6A703268'); % 'jp2h'
            % ihdr
            inObj.ihdr = image_header_box;
            inObj.ihdr.set_contents(main_header);
            % bpcc
            if inObj.ihdr.BPC == 255
                inObj.bpcc = bits_per_component_box;
                inObj.bpcc.set_contents(main_header);
            end
            % colr
            inObj.colr = colour_specification_box;
            inObj.colr.set_contents(main_header);
            inObj.LBox = inObj.ihdr.LBox + inObj.colr.LBox + 8;
        end
        function write_contents(inObj, hDdst)
            inObj.write_box_base(hDdst);
            inObj.ihdr.write_contents(hDdst);
            if isempty(inObj.bpcc) == false
                inObj.bpcc.write_contents(hDdst);
            end
            inObj.colr.write_contents(hDdst);
        end
    end
end
