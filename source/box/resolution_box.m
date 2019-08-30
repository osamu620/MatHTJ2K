classdef resolution_box < jp2_box_base
    properties
        resc capture_resolution_box
        resd default_display_resolution_box
    end
    methods
        function read_contents(inObj)
            while inObj.DBox.pos < length(inObj.DBox.buf)
                hBox = jp2_box_base;
                hBox.read_box_base(inObj.DBox);
                switch convert_uint32_to_char(hBox.TBox)
                    case 'resc'
                        inObj.resc = capture_resolution_box(hBox);
                        inObj.resc.read_contents();
                    case 'resd'
                        inObj.resd = default_display_resolution_box(hBox);
                        inObj.resd.read_contents();
                    otherwise
                        fprintf('Unkown box is found in resolution box\n');
                end
            end
            inObj.is_read = true;
        end
    end
end