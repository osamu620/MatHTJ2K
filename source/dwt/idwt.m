function Ixy = idwt(hTile, main_header, c, reduce_NL, use_MEX)
M_OFFSET = 1;

[codingStyle, codingStyleComponent] = get_coding_Styles(main_header, hTile.header, c);
dwt_filter = codingStyleComponent.get_transformation();
NL = codingStyleComponent.get_number_of_decomposition_levels();

lev = NL;

if NL - reduce_NL > 0
    while lev > reduce_NL
        currentResolution = findobj(hTile.resolution, 'idx_c', c, '-and', 'idx', NL - lev);
        nextResolution = findobj(hTile.resolution, 'idx_c', c, '-and', 'idx', NL - lev + 1);
        u0 = nextResolution.trx0;
        u1 = nextResolution.trx1;
        v0 = nextResolution.try0;
        v1 = nextResolution.try1;
        nextLL = subband_info(0, u0, v0, uint32(u1 - u0), uint32(v1 - v0), zeros(v1 - v0, u1 - u0), 0, 0);
        nextResolution.subbandInfo = [nextLL, nextResolution.subbandInfo];
        LL = findobj(currentResolution.subbandInfo, 'idx', 0);
        HL = findobj(nextResolution.subbandInfo, 'idx', 1);
        LH = findobj(nextResolution.subbandInfo, 'idx', 2);
        HH = findobj(nextResolution.subbandInfo, 'idx', 3);
        if u1 ~= u0 && v1 ~= v0
            if use_MEX == true
                nextLL.dwt_coeffs = idwt_2d_sr_mex(LL.dwt_coeffs, HL.dwt_coeffs, LH.dwt_coeffs, HH.dwt_coeffs, u0, u1, v0, v1, dwt_filter);
            else
                nextLL.dwt_coeffs = idwt_2d_sr(LL.dwt_coeffs, HL.dwt_coeffs, LH.dwt_coeffs, HH.dwt_coeffs, u0, u1, v0, v1, dwt_filter);
            end
        end
        lev = lev - 1;
    end
    %currentResolution = findobj(hTile.resolution, 'idx_c', c, '-and', 'idx', NL - reduce_NL);
    %hTile.components(c + M_OFFSET).samples = currentResolution.subbandInfo(1).dwt_coeffs;
    hTile.components(c + M_OFFSET).samples = nextLL.dwt_coeffs;
else
    % NL = 0 means, no DWT decomposition was done.
    currentResolution = findobj(hTile.resolution, 'idx_c', c, '-and', 'idx', 0);
    LL = findobj(currentResolution.subbandInfo, 'idx', 0);
    hTile.components(c + M_OFFSET).samples = LL.dwt_coeffs;
end

Ixy = hTile.components(c + M_OFFSET).samples;