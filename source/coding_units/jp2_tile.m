classdef jp2_tile < handle
    properties
        SOT SOT_marker
        idx uint32
        idx_x uint32
        idx_y uint32
        tile_pos_x int32
        tile_pos_y int32
        tile_size_x uint32
        tile_size_y uint32
        components jp2_tile_component
        src_data jp2_data_source
        resolution resolution_info
        packetPointer cell
        packetInfo jp2_packet
        output
        buf
        ROImask logical
        composite_output
        header j2k_tile_part_header
        is_read logical
    end
    methods
        function outObj = jp2_tile(numtile_wide, p, q, tx0, ty0, tx1, ty1)
            if nargin == 0
                outObj.idx = 0;
                outObj.idx_x = 0;
                outObj.idx_y = 0;
                outObj.tile_pos_x = 0;
                outObj.tile_pos_y = 0;
                outObj.tile_size_x = 0;
                outObj.tile_size_y = 0;
                outObj.src_data = jp2_data_source;
                outObj.is_read = false;
            else
                outObj.SOT = SOT_marker;
                outObj.idx = p + q* numtile_wide;
                outObj.idx_x = p;
                outObj.idx_y = q;
                outObj.tile_pos_x = tx0;
                outObj.tile_pos_y = ty0;
                outObj.tile_size_x = tx1 - tx0;
                outObj.tile_size_y = ty1 - ty0;
                outObj.is_read = false;
            end
        end
        function outObj = add_tile(inObj, numtile_wide, x, y, tx0, ty0, tx1, ty1)
            if nargin <= 1
                tmpObj = jp2_tile;
                outObj = [inObj, tmpObj];
            else
                tmpObj = jp2_tile(numtile_wide, x, y, tx0, ty0, tx1, ty1);
                outObj = [inObj, tmpObj];
            end
        end
        function composite_out = put_tile_into_composite_output(inObj, main_header, composite_out, reduce_NL)
            M_OFFSET = 1;
            for c = 0:main_header.SIZ.Csiz - 1
                [~, codingStyleComponent] = get_coding_Styles(main_header, inObj.header, c);
                c_NL = codingStyleComponent.get_number_of_decomposition_levels();
                reduced_LL = findobj(inObj.resolution, 'idx', c_NL - reduce_NL, '-and', 'idx_c', c);
                
                c_ty0(c + M_OFFSET) = reduced_LL.try0;
                c_ty1(c + M_OFFSET) = reduced_LL.try1;
                c_tx0(c + M_OFFSET) = reduced_LL.trx0;
                c_tx1(c + M_OFFSET )= reduced_LL.trx1;
            end
            ty0 = max(c_ty0);
            ty1 = max(c_ty1);
            tx0 = max(c_tx0);
            tx1 = max(c_tx1);

            composite_out(ty0 + M_OFFSET:ty1, tx0 + M_OFFSET:tx1, :) = inObj.composite_output;
        end
        function out = put_tile_into_output(inObj, main_header, out, reduce_NL)
            M_OFFSET = 1;
  
            for c = 0:main_header.SIZ.Csiz - 1
                [~, codingStyleComponent] = get_coding_Styles(main_header, inObj.header, c);
                c_NL = codingStyleComponent.get_number_of_decomposition_levels();
                reduced_LL = findobj(inObj.resolution, 'idx', c_NL - reduce_NL, '-and', 'idx_c', c);
                
                tcy0 = reduced_LL.try0;
                tcy1 = reduced_LL.try1;
                tcx0 = reduced_LL.trx0;
                tcx1 = reduced_LL.trx1;
                out{c + M_OFFSET}(tcy0 + M_OFFSET:tcy1, tcx0 + M_OFFSET:tcx1) = inObj.output{c + M_OFFSET};
            end
        end
    end
end