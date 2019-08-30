function fdwt(hTile, main_header, c, use_MEX)
M_OFFSET = 1;

[codingStyle, codingStyleComponent] = get_coding_Styles(main_header, hTile.header, c);
dwt_filter = codingStyleComponent.get_transformation();
NL = codingStyleComponent.get_number_of_decomposition_levels();

lev = 0;

LL = hTile.components(c + M_OFFSET).samples;

while lev < NL
    currentResolution = findobj(hTile.resolution, 'idx', NL - lev, '-and', 'idx_c', c);
    u0 = currentResolution.trx0;
    u1 = currentResolution.trx1;
    v0 = currentResolution.try0;
    v1 = currentResolution.try1;
    if u0 == u1 || v0 == v1
        % if we are here, current resolution is empty. 
        break;
    end
    if use_MEX == true
        [LL, HL, LH, HH] = fdwt_2d_sd_mex(LL, u0, u1, v0, v1, dwt_filter);
    else
        [LL, HL, LH, HH] = fdwt_2d_sd(LL, u0, u1, v0, v1, dwt_filter);
    end
    currentResolution.subbandInfo(1).dwt_coeffs = HL;
    currentResolution.subbandInfo(2).dwt_coeffs = LH;
    currentResolution.subbandInfo(3).dwt_coeffs = HH;
    lev = lev + 1;
end

currentResolution = findobj(hTile.resolution, 'idx', NL - lev, '-and', 'idx_c', c);
currentResolution.subbandInfo(1).dwt_coeffs = LL;
