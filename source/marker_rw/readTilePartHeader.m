function [WORD, tilepart_header_length] = readTilePartHeader(main_header, hDsrc, hTile, is_first_tile_part)

tilepart_header_length = uint32(0);

%% defined markers
TilePartmarkers = jp2_markers(false);
if is_first_tile_part == true
    hTile.header = j2k_tile_part_header;
end
%% read marker segments
WORD = get_word(hDsrc);
while WORD ~= TilePartmarkers.SOD && WORD ~= TilePartmarkers.EOC
    switch WORD
        case TilePartmarkers.COD
            assert(is_first_tile_part == true);
            fprintf('INFO: Tile part COD is found in tile #%3d\n', hTile.idx);
            assert(isempty(hTile.header.COD), 'ERROR: no more than one COD is allowed in tile-part header\n');
            hTile.header.read_COD(hDsrc);
            tilepart_header_length = add_tile_part_header_length(tilepart_header_length, uint32(hTile.header.COD.Lcod));
        case TilePartmarkers.COC
            assert(is_first_tile_part == true);
            fprintf('INFO: Tile part COC is found in tile #%3d\n', hTile.idx);
            hTile.header.read_COC(hDsrc, main_header.SIZ.Csiz);
            tilepart_header_length = add_tile_part_header_length(tilepart_header_length, uint32(hTile.header.COC(end).Lcoc));
        case TilePartmarkers.QCD
            assert(is_first_tile_part == true);
            fprintf('INFO: Tile part QCD is found in tile #%3d\n', hTile.idx);
            assert(isempty(hTile.header.QCD), 'ERROR: no more than one QCD is allowed in tile-part header\n');
            hTile.header.read_QCD(hDsrc);
            tilepart_header_length = add_tile_part_header_length(tilepart_header_length, uint32(hTile.header.QCD.Lqcd));
        case TilePartmarkers.QCC
            fprintf('INFO: Tile part QCC is found in tile #%3d\n', hTile.idx);
            assert(is_first_tile_part == true);
            hTile.header.read_QCC(hDsrc, main_header.SIZ.Csiz);
            tilepart_header_length = add_tile_part_header_length(tilepart_header_length, uint32(hTile.header.QCC(end).Lqcc));
        case TilePartmarkers.RGN
            fprintf('INFO: Tile part RGN is found in tile #%3d\n', hTile.idx);
            assert(is_first_tile_part == true);
            hTile.header.read_RGN(hDsrc, main_header.SIZ.Csiz);
            tilepart_header_length = add_tile_part_header_length(tilepart_header_length, uint32(hTile.header.RGN(end).Lrgn));
        case TilePartmarkers.POC
            fprintf('INFO: Tile part POC is found in tile #%3d\n', hTile.idx);
            hTile.header.read_POC(hDsrc, main_header.SIZ.Csiz);
            tilepart_header_length = add_tile_part_header_length(tilepart_header_length, uint32(hTile.header.POC(end).Lpoc));
        case TilePartmarkers.PPT
            fprintf('INFO: PPT is found in tile #%3d\n', hTile.idx);
            hTile.header.read_PPT(hDsrc);
            tilepart_header_length = add_tile_part_header_length(tilepart_header_length, uint32(hTile.header.PPT(end).Lppt));
        case TilePartmarkers.PLT
            fprintf('INFO: PLT is found in tile #%3d\n', hTile.idx);
            hTile.header.read_PLT(hDsrc);
            tilepart_header_length = add_tile_part_header_length(tilepart_header_length, uint32(hTile.header.PLT(end).Lplt));
        case TilePartmarkers.COM
            fprintf('INFO: Tile part COM is found in tile #%3d\n', hTile.idx);
            hTile.header.read_COM(hDsrc);
            tilepart_header_length = add_tile_part_header_length(tilepart_header_length, uint32(hTile.header.COM(end).Lcom));
    end
    WORD = get_word(hDsrc);
end

if tilepart_header_length ~= 0
    hTile.header.is_empty = false;
end

length_of_SOT_SOD = int32(14); % = SOT(2) + Lsot(=10) + SOD(2);
tilepart_header_length = tilepart_header_length + uint32(length_of_SOT_SOD);

%-----
    function num_bytes = add_tile_part_header_length(num_bytes, L)
        num_bytes = num_bytes + L + 2;
    end
end