function t2_make_resolution(hResolutionInfo, hTile, NL, r, c, main_header)
M_OFFSET = 1;
DEBUG = 0;
num_band = 0;

[codingStyle, codingStyleComponent] = get_coding_Styles(main_header, hTile.header, c);

hTileComponent = hTile.components(c + M_OFFSET);
hResolutionInfo.idx = r;
assert(hResolutionInfo.idx_c == c);

NL_r = double(NL) - double(r);

hResolutionInfo.trx0 = ceil_quotient_int(hTileComponent.tcx0, 2^(NL_r), 'int32');
hResolutionInfo.try0 = ceil_quotient_int(hTileComponent.tcy0, 2^(NL_r), 'int32');
hResolutionInfo.trx1 = ceil_quotient_int(hTileComponent.tcx1, 2^(NL_r), 'int32');
hResolutionInfo.try1 = ceil_quotient_int(hTileComponent.tcy1, 2^(NL_r), 'int32');

if r == 0
    nb = double(NL) - double(r);
    b_start = 0;
    b_stop = 0;
    num_band = 1;
else
    nb = double(NL) - double(r) + 1;
    b_start = 1;
    b_stop = 3;
    num_band = 3;
end
% deternime position and size of subband
xob_tab = [0 1 0 1];
yob_tab = [0 0 1 1];
tcx0 = hTileComponent.tcx0;
tcx1 = hTileComponent.tcx1;
tcy0 = hTileComponent.tcy0;
tcy1 = hTileComponent.tcy1;
for b_idx = b_start:b_stop
    xob = xob_tab(b_idx+M_OFFSET);
    yob = yob_tab(b_idx+M_OFFSET);
    tbx0 = ceil_quotient_int((tcx0-(2^(nb-1)*xob)), 2^nb, 'int32');
    tby0 = ceil_quotient_int((tcy0-(2^(nb-1)*yob)), 2^nb, 'int32');
    tbx1 = ceil_quotient_int((tcx1-(2^(nb-1)*xob)), 2^nb, 'int32');
    tby1 = ceil_quotient_int((tcy1-(2^(nb-1)*yob)), 2^nb, 'int32');
    
    hBandInfo = subband_info;
    hBandInfo.pos_x = tbx0;
    hBandInfo.pos_y = tby0;
    hBandInfo.size_x = uint32(tbx1 - tbx0);
    hBandInfo.size_y = uint32(tby1 - tby0);
    hBandInfo.idx = b_idx;
    hBandInfo.dwt_coeffs = zeros(hBandInfo.size_y, hBandInfo.size_x);
    if isempty(hResolutionInfo.subbandInfo) == true
        hResolutionInfo.subbandInfo = hBandInfo;
    else
        hResolutionInfo.subbandInfo = [hResolutionInfo.subbandInfo hBandInfo];
    end
end
hResolutionInfo.num_band = num_band;

if DEBUG == 1
    fprintf('r = %d, resolution size (x,y) = (%d,%d)\n', ...
        r, hResolutionInfo.trx1-hResolutionInfo.trx0,hResolutionInfo.try1-hResolutionInfo.try0);
end
% B.6 precinct
% precinct size in resolution is not the same that in subband!
PP = codingStyleComponent.get_precinct_size_in_exponent();
PPx = PP(:, 1);
PPy = PP(:, 2);

hResolutionInfo.precinct_width = 2^(uint32(PPx(r+M_OFFSET)));
hResolutionInfo.precinct_height = 2^(uint32(PPy(r+M_OFFSET)));

if hResolutionInfo.trx1 > hResolutionInfo.trx0
    hResolutionInfo.numprecinctwide = ...
        ceil_quotient_int(hResolutionInfo.trx1, hResolutionInfo.precinct_width, 'uint32') ...
        - floor_quotient_int(hResolutionInfo.trx0, hResolutionInfo.precinct_width, 'uint32');
else
    hResolutionInfo.numprecinctwide = 0;
end
if hResolutionInfo.try1 > hResolutionInfo.try0
    hResolutionInfo.numprecincthigh = ...
        ceil_quotient_int(hResolutionInfo.try1, hResolutionInfo.precinct_height, 'uint32') ...
        - floor_quotient_int(hResolutionInfo.try0, hResolutionInfo.precinct_height, 'uint32');
else
    hResolutionInfo.numprecincthigh = 0;
end

% size of reduced resolution
Etcr_x = hResolutionInfo.trx0;
Ftcr_x = hResolutionInfo.trx1;
Etcr_y = hResolutionInfo.try0;
Ftcr_y = hResolutionInfo.try1;

% precinct size
Ptcr_x = int32(2^PPx(r + M_OFFSET));
Ptcr_y = int32(2^PPy(r + M_OFFSET));

% determine precinct size in reduced resolution
for y = 1:hResolutionInfo.numprecincthigh
    for x = 1:hResolutionInfo.numprecinctwide
        Etcrp_x = max(Etcr_x, 0 + Ptcr_x * (int32(x-1) + floor_quotient_int(Etcr_x - 0, Ptcr_x, 'int32')));
        Etcrp_y = max(Etcr_y, 0 + Ptcr_y * (int32(y-1) + floor_quotient_int(Etcr_y - 0, Ptcr_y, 'int32')));
        Ftcrp_x = min(Ftcr_x, 0 + Ptcr_x * (int32(x) + floor_quotient_int(Etcr_x - 0, Ptcr_x, 'int32')));
        Ftcrp_y = min(Ftcr_y, 0 + Ptcr_y * (int32(y) + floor_quotient_int(Etcr_y - 0, Ptcr_y, 'int32')));
        if isempty(hResolutionInfo.precinct_resolution) == true
            hResolutionInfo.precinct_resolution = precinct_info(x-1, y-1, Etcrp_x, Etcrp_y, Ftcrp_x, Ftcrp_y, r, hResolutionInfo.subbandInfo);
        else
            tmp_precinct_resolution = precinct_info(x-1, y-1, Etcrp_x, Etcrp_y, Ftcrp_x, Ftcrp_y, r, hResolutionInfo.subbandInfo);
            hResolutionInfo.precinct_resolution = [hResolutionInfo.precinct_resolution tmp_precinct_resolution];
        end
    end
end

hResolutionInfo.is_empty = false;
if (hResolutionInfo.trx0 >= hResolutionInfo.trx1 ...
        || hResolutionInfo.try0 >= hResolutionInfo.try1)
    hResolutionInfo.is_empty = true;
    return; % empty resolution
end
