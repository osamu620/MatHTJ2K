function [elapsedTime, time_for_blockcoding] = encode_HTJ2K(FileName, inputImg, use_MEX, varargin)
% encode_HTJ2K   : JPEG 2000 Part 1 (ISO/IEC 15444-1) and HTJ2K (JPEG 2000 Part 15, ISO/IEC 15444-15) compression.
%
% Usage:
% [total_processing_time(sec), block_copding_time(sec)] = encode_HTJ2K(filename, inputimage, use_MEX, <parameters>)
%
% filename                 : File name of compressed image. Extension for file-format shall be ".jp2" or ".jph"
%                            Exntensions for codestream can be any other extensions.
% inputimage               : Array of input image; supported input classes are uint8, int8, uint16, int16, uint32, int32, single.
% use_MEX, logical         : If true, MEX version of blockcoding algorithm is used. Default is true.
%
% Valid entries of parameters (in any order); d: decimal integer, f:decimal float, s: string vector with ''
% (Some parameters accept :Td, :Cd or :TdCd after its name to specify a tile or a component.)
%                          (T and C are index for a tile and a component, respectively.)
%
% 'levels', d, TC          : Number of DWT decomposition level (0 to 32), default is 5.
% 'reversible', s,  TC     : Reversible compression ('yes') or irreversible('no'). Default is 'no'.
% 'cmodes', s, TC          : If you want to use HTJ2K, 'HT' is a valid parameter (may be with 'CAUSAL')
%                            For Part 1 coding, 'BYPASS', 'RESET', 'CAUSAL', 'ERTERM' and 'SEGMARK' are valid.
%                            '|' shall be used as delimiters for those entries.
%                            Default is 'HT'.
% 'rate', f                : Target coding rate (> 0). RD optimization is done by PCRD-opt.
%                            if Cmodes is set to 'HT', this value is ignored. (no RD optimization)
% 'layers', d, T           : Number of quality layers (0<= num_layers <= 65535); if HT, this value is ignored.
% 'blk', [d d], TC         : Codeblock size, vertical first, [64 64] is default.
% 'tile', [d,d]            : Tile size, vertical first, one tile is default.
% 'use_precincts', s, TC   : Specify precinct size ('yes'), or Use maximum precinct size ('no'). Default is 'no'.
% 'precincts', [d,d], TC   : Precinct size, vertical first, values shall be power of two.
%                            Default is maximum precinct (unspecified = [2^15 2^15])
% 'order', s, T            : Progression order ('LRCP', 'RLCP', 'RPCL', 'PCRL', 'CPRL')
%                            Default is 'LRCP'.
% 'qstep', f, TC           : Base step size for quantization, in most case,  0 < base_stepsize <= 2.0
% 'Qfactor', d             : Qfactor, 0 to 100, 0: Lowest quality, 100: Highest quality.
% 'guard', d, TC           : Number of guard bits, 1 is default. 0 <= GuardBits <= 7.
% 'use_SOP', s, T          : use SOP marker segment ('yes'). Default is 'no'.
% 'use_EPH', s, T          : use EPH marker ('yes'). Default is 'no'.
% 'origin', [d d]          : Specify the origin of the reference grid, vertical first, [0 0] is default.
% 'tile_origin', [d d]     : Specify the tile origin of the reference grid, vertical first, [0 0] is default.
% 'use_PPT', [d, ...], T   : Specify the index of tile which uses PPT marker segment in raster order.
%                            Default is no tile uses PPT marker.
% 'use_PLT', [d, ...], T   : Specify the index of tile which uses PLT marker segment in raster order.
%                            Default is no tile uses PLT marker.
% 'use_PPM', s             : use PPM marker segment ('yes'). Default is 'no'.
% 'use_TLM', s             : use TLM marker segment ('yes'). Default is 'no'.
% 'ochange', {d,d,d,d,d,s}, T : Progressive order change. {RS, CS, LYE, RE, CE, 'order' (see 'order')}. Default is no entry.
%
% TODO: RGN, PLM, CRG, PRF, CPF markers and ERTERM processing
%       HT SigProp and MagRef encoding (encoding moddules are ready, but construction of packet header is not yet perfectly done)
% August 28, 2019 (c) Osamu WATANABE, Takushoku University and Vrije Universiteit Brussel

M_OFFSET = 1; % offset for MATLAB index
DEBUG = 0; % If this is set to 1, some information will be shown.

%% parse input arguments
if nargin < 3
    error('Number of input arguments is insufficient.');
end

inputArgs = jp2_inputArguments(inputImg, FileName);
[main_header, tilepart_header, numTiles_x, numTiles_y, use_SOP, use_PPM, use_TLM, use_PPT, use_PLT] = inputArgs.parse_args(varargin);

% ROI is not yet implemented....
ROImask = [];
if isempty(inputArgs.ROI) == false
    ROImask = zeros(size(inputImg, 1), size(inputImg, 2), 'logical');
    ROImask(floor(inputArgs.ROI(1) * main_header.SIZ.Ysiz):floor((inputArgs.ROI(1) + inputArgs.ROI(3)) * main_header.SIZ.Ysiz), ...
        floor(inputArgs.ROI(2) * main_header.SIZ.Xsiz):floor((inputArgs.ROI(2) + inputArgs.ROI(4)) * main_header.SIZ.Xsiz)) = 1;
end

%% create codestream destination
% Destination type(1st argument):
% FILE = 0;
% MEMORY = 1;
j2c_dst = jp2_data_destination(1, FileName, main_header.SIZ.Xsiz * main_header.SIZ.Ysiz * uint32(main_header.SIZ.Csiz));

%% defined markers
JP2markers = jp2_markers;

time_start = tic;
time_for_blockcoding = 0;

%% create tiles
tile_Set = [];
for q = 0:numTiles_y - 1
    for p = 0:numTiles_x - 1
        tx0 = max(main_header.SIZ.XTOsiz + p * main_header.SIZ.XTsiz, main_header.SIZ.XOsiz);
        ty0 = max(main_header.SIZ.YTOsiz + q * main_header.SIZ.YTsiz, main_header.SIZ.YOsiz);
        tx1 = min(main_header.SIZ.XTOsiz + (p + 1) * main_header.SIZ.XTsiz, main_header.SIZ.Xsiz);
        ty1 = min(main_header.SIZ.YTOsiz + (q + 1) * main_header.SIZ.YTsiz, main_header.SIZ.Ysiz);
        tile_Set = [tile_Set, jp2_tile(numTiles_x, p, q, tx0, ty0, tx1, ty1)];
        currentTile = tile_Set(p + q * numTiles_x + M_OFFSET);
        currentTile.header = findobj(tilepart_header, 'idx', p + q * numTiles_x);

        for c = 0:main_header.SIZ.Csiz - 1
            tcx0 = ceil_quotient_int(tx0, main_header.SIZ.XRsiz(c + M_OFFSET), 'uint32');
            tcx1 = ceil_quotient_int(tx1, main_header.SIZ.XRsiz(c + M_OFFSET), 'uint32');
            tcy0 = ceil_quotient_int(ty0, main_header.SIZ.YRsiz(c + M_OFFSET), 'uint32');
            tcy1 = ceil_quotient_int(ty1, main_header.SIZ.YRsiz(c + M_OFFSET), 'uint32');
            currentTile.components(c + M_OFFSET) = jp2_tile_component(c, tcx0, tcy0, tcx1, tcy1);
        end

        currentTile.buf = inputImg(currentTile.tile_pos_y + M_OFFSET:currentTile.tile_pos_y + int32(currentTile.tile_size_y), ...
            currentTile.tile_pos_x + M_OFFSET:currentTile.tile_pos_x + int32(currentTile.tile_size_x), :);
        % ROI is not yet implemented....
        if isempty(inputArgs.ROI) == false
            currentTile.ROImask = ROImask(currentTile.tile_pos_y + M_OFFSET:currentTile.tile_pos_y + int32(currentTile.tile_size_y), ...
                currentTile.tile_pos_x + M_OFFSET:currentTile.tile_pos_x + int32(currentTile.tile_size_x));
        end
    end
end

%% encode tile
total_length = main_header.get_length();
for tile_idx = 0:numTiles_y * numTiles_x - 1
    fprintf('==== Encoding tile %d ====\n', tile_idx);
    time_for_blockcoding_per_tile = encode_tile(use_MEX, tile_Set(tile_idx + M_OFFSET), main_header, inputArgs.rate);
    time_for_blockcoding = time_for_blockcoding + time_for_blockcoding_per_tile;

    %% set Psot value; length of compressed tile data (packet headers and its correcponding bodies)
    tileLength = 0;
    num_packet = length(tile_Set(tile_idx + M_OFFSET).packetInfo);
    for packet_idx = 1:num_packet
        if use_PPT(tile_idx + M_OFFSET) == false && use_PPM == false
            tileLength = tileLength + length(tile_Set(tile_idx + M_OFFSET).packetInfo(packet_idx).header);
        end
        tileLength = tileLength + length(tile_Set(tile_idx + M_OFFSET).packetInfo(packet_idx).body);
        tileLength = tileLength + (use_SOP == true) * 6; % taking SOP length into account
    end
    if use_PPT(tile_idx + M_OFFSET) == true
        tile_Set(tile_idx + M_OFFSET).header.set_PPT(tile_Set(tile_idx + M_OFFSET));
    end
    if use_PLT(tile_idx + M_OFFSET) == true == true
        tile_Set(tile_idx + M_OFFSET).header.set_PLT(tile_Set(tile_idx + M_OFFSET));
    end
    tile_Set(tile_idx + M_OFFSET).header.set_length(uint32(tileLength));
    total_length = total_length + tile_Set(tile_idx + M_OFFSET).header.SOT.Psot;
end
total_length = total_length + 2; % add length of EOC

%% output
if endsWith(FileName, '.jp2', 'IgnoreCase', true) || endsWith(FileName, '.jph', 'IgnoreCase', true)
    jp2Boxes = jp2_boxes(j2c_dst, 1);
    jp2Boxes.write_contents(main_header, total_length);
end
% write SOC marker
put_word(j2c_dst, JP2markers.SOC);
% write main header
main_header.write(JP2markers, j2c_dst, tile_Set, numTiles_y * numTiles_x, use_PPM, use_TLM);
% write tile data
for tile_idx = 0:numTiles_y * numTiles_x - 1
    % write tile-part header
    tile_Set(tile_idx + M_OFFSET).header.write(JP2markers, j2c_dst, main_header);
    num_packet = length(tile_Set(tile_idx + M_OFFSET).packetInfo);
    for packet_idx = 0:num_packet - 1
        obj = tile_Set(tile_idx + M_OFFSET).packetInfo(packet_idx + M_OFFSET);
        if use_SOP == true
            % write SOP marker segments, if needed
            j2c_dst.put_word(JP2markers.SOP); %SOP: FF91
            j2c_dst.put_word(uint16(4)); % Lsop is always 4.
            j2c_dst.put_word(uint16(packet_idx)); % Nsop
        end
        if use_PPM == false && use_PPT(tile_idx + M_OFFSET) == false
            % write packet headers distributed in codestream
            j2c_dst.put_N_byte(obj.header);
        end
        % write packet bodies
        j2c_dst.put_N_byte(obj.body);
    end

end
elapsedTime = toc(time_start);
% write EOC marker
j2c_dst.put_word(JP2markers.EOC);

%% if compressed data is stored in memory, write those into file
if j2c_dst.type == 1
    fid = fopen(FileName, 'w');
    j2c_dst.flush;
    fwrite(fid, j2c_dst.buf, 'uint8');
    fclose(fid);
end

%% delete j2c_data_destination
j2c_dst.delete;
fprintf('Total:%f (sec), Block-coding: %f (sec)\n', elapsedTime, time_for_blockcoding);