classdef jp2_box_base < handle
    properties
        LBox uint32
        TBox uint32
        XLBox uint64
        DBox jp2_data_source
        is_read logical
    end
    methods
        function outObj = jp2_box_base(inObj)
            if nargin == 0
                outObj.is_read = false;
            elseif nargin == 1
                outObj.LBox = inObj.LBox;
                outObj.TBox = inObj.TBox;
                outObj.XLBox = inObj.XLBox;
                outObj.DBox = inObj.DBox;
                outObj.is_read = false;
            end
        end
        function out = get_length(inObj)
            assert(inObj.is_read == true);
            out = inObj.LBox;
        end
        function out = get_type(inObj)
            assert(inObj.is_read == true);
            out = inObj.TBox;
        end
        function out = get_xlength(inObj)
            assert(inObj.is_read == true && inObj.LBox == 1);
            out = inObj.XLBox;
        end
        %
        function read_box_base(inObj, hDsrc)
            assert(isa(hDsrc,'jp2_data_source'));
            tmpLBox = get_dword(hDsrc);
            assert(tmpLBox == 0 || tmpLBox == 1 || (tmpLBox >= 8 && tmpLBox < 2^32 -1));
            inObj.LBox = tmpLBox;
            
            inObj.TBox =  get_dword(hDsrc);
            
            if inObj.LBox == 0 % Box length was not known when the LBox field was written.
                inObj.LBox = length(hDsrc.buf) - hDsrc.pos + 8;
            elseif inObj.LBox == 1 % Box length is written as XLBox.
                inObj.XLBox = uint64(get_dword(hDsrc))*2^32 + uint64(get_dword(hDsrc));
            end
            bytes_to_read = 0;
            if isempty(inObj.XLBox) == true
                bytes_to_read = inObj.LBox - 8;
            else
                bytes_to_read = inObj.XLBox - 8;
            end
            inObj.DBox = jp2_data_source(get_N_byte(hDsrc, bytes_to_read));
        end
        function write_box_base(inObj, hDdst)
            assert(isa(hDdst,'jp2_data_destination'));
            hDdst.put_dword(inObj.LBox);
            hDdst.put_dword(inObj.TBox);
        end
    end
end
        
        