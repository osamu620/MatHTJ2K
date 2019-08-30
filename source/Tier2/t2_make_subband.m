function t2_make_subband(c, hResolutionInfo, b, hPband, main_header, RI, num_layers, color_gain, NL, transformation, band_weights, codeblock_size, Cmodes, is_derived, epsilons, mantissas, nG)

M_OFFSET = 1;

hBandInfo = hResolutionInfo.subbandInfo(b);
hBandInfo.idx_c = c;

r = hResolutionInfo.idx;
if r == 0
    nb = double(NL) - double(r);
else
    nb = double(NL) - double(r) + 1;
end

gain_b = [0 1 1 2];

if transformation == 1 % lossless
    hBandInfo.epsilon_b = epsilons(3*(NL - nb) + hBandInfo.idx + M_OFFSET);
    hBandInfo.M_b = hBandInfo.epsilon_b + nG - 1; % Eq. E-2 15444-1
    hBandInfo.Delta_b = 1.0;
    hBandInfo.normalized_delta = 1.0/2^double(RI(c + M_OFFSET));
    hBandInfo.W_b = band_weights(3*(NL - nb) + hBandInfo.idx + M_OFFSET);
    hBandInfo.is_reversible = true;
else % lossy
    if is_derived == true
        % scalar quantization derived
        assert(length(epsilons) == 1 && length(mantissas) == 1);
        % derive exponent and mantissa according to Eq. E-5
        hBandInfo.epsilon_b = uint8(epsilons) - NL + nb;
        hBandInfo.mantissa_b = mantissas;
        hBandInfo.M_b = hBandInfo.epsilon_b + nG - 1; % Eq. E-2 15444-1
    else
        % scalar quantization expounded
        hBandInfo.epsilon_b = epsilons(3*(NL - nb) + hBandInfo.idx + M_OFFSET);
        hBandInfo.mantissa_b = mantissas(3*(NL - nb) + hBandInfo.idx + M_OFFSET);
        hBandInfo.M_b = hBandInfo.epsilon_b + nG - 1; % Eq. E-2 15444-1
    end
    Rb = RI(c + M_OFFSET) + gain_b(hBandInfo.idx + M_OFFSET);
    hBandInfo.Delta_b = 2^(double(Rb) - double(hBandInfo.epsilon_b))*(1+ double(hBandInfo.mantissa_b)/2^11);
    hBandInfo.normalized_delta = 2^(-double(hBandInfo.epsilon_b))*(1+ double(hBandInfo.mantissa_b)/2^11);
    hBandInfo.W_b = band_weights(3*(NL - nb) + hBandInfo.idx + M_OFFSET);
    hBandInfo.is_reversible = false;
end

%% propagate to precinct subband
hPband.band_idx = hBandInfo.idx;
hPband.epsilon_b = hBandInfo.epsilon_b;
hPband.mantissa_b = hBandInfo.mantissa_b;
hPband.M_b = hBandInfo.M_b;
hPband.Delta_b = hBandInfo.Delta_b;
hPband.normalized_delta = hBandInfo.normalized_delta;
hPband.W_b = hBandInfo.W_b;
hPband.is_reversible = hBandInfo.is_reversible;
hPband.idx_c = hBandInfo.idx_c;

%% calculate mse weight for MSB, this weight is used to estimate distortion
if main_header.SIZ.Csiz == 3
    Gc = color_gain(hPband.idx_c + M_OFFSET);
    % get CSF weight value
    Wc = get_CSF_weight(hPband.idx_c, nb, hPband.band_idx);
else
    Gc = 1.0;
    Wc = 1.0;
end
msb_mse = (hPband.normalized_delta * 2^double(hPband.M_b-1))^2 * hPband.W_b * Gc * Wc^2;
hPband.msb_mse = msb_mse;

%% determine codeblock size and build codeblock structure
if r == 0
    sr = 0;
else % r> 0
    sr = 1;
end

xob_tab = [0 1 0 1];
yob_tab = [0 0 1 1];
xob = xob_tab(hPband.band_idx+M_OFFSET);
yob = yob_tab(hPband.band_idx+M_OFFSET);

codeblock_size = int32(codeblock_size);

Jtc_x = 2^codeblock_size(1);
Jtc_y = 2^codeblock_size(2);

Jtcr_x = min(Jtc_x, 2^(-sr)*int32(hResolutionInfo.precinct_width));
Jtcr_y = min(Jtc_y, 2^(-sr)*int32(hResolutionInfo.precinct_height));
hPband.CblkSizX = uint16(Jtcr_x);
hPband.CblkSizY = uint16(Jtcr_y);

Etcrpb_x = hPband.pos_x;
Etcrpb_y = hPband.pos_y;
Ftcrpb_x = int32(hPband.size_x) + hPband.pos_x;
Ftcrpb_y = int32(hPband.size_y) + hPband.pos_y;
Omega_C_b_x = ceil_quotient_int(0 - xob, 2^sr, 'int32');
Omega_C_b_y = ceil_quotient_int(0 - yob, 2^sr, 'int32');

if Ftcrpb_x > Etcrpb_x
    hPband.numCblksX = ceil_quotient_int(Ftcrpb_x - Omega_C_b_x, Jtcr_x, 'uint32') ...
        - floor_quotient_int(Etcrpb_x - Omega_C_b_x, Jtcr_x, 'uint32');
else
    hPband.numCblksX = 0;
end
if Ftcrpb_y > Etcrpb_y
    hPband.numCblksY = ceil_quotient_int(Ftcrpb_y - Omega_C_b_y, Jtcr_y, 'uint32') ...
        - floor_quotient_int(Etcrpb_y - Omega_C_b_y, Jtcr_y, 'uint32');
else
    hPband.numCblksY = 0;
end
raster_precinct_idx = hPband.precinct_idx_x + hPband.precinct_idx_y * hResolutionInfo.numprecinctwide;

numCblksY = int32(hPband.numCblksY);
numCblksX = int32(hPband.numCblksX);
idx_c = hPband.idx_c;
pband_size_x = int32(hPband.size_x);
pband_size_y = int32(hPband.size_y);
band_idx = hPband.band_idx;
M_b = hPband.M_b;
W_b = hPband.W_b;
Delta_b = hPband.Delta_b;
normalized_delta = hPband.normalized_delta;

if numCblksX * numCblksY ~= 0
    for idx_y = 0: numCblksY-1
        for idx_x = 0:numCblksX-1
            E_Jtcr_x = max(hPband.pos_x, Jtcr_x * (idx_x + floor_quotient_int(hPband.pos_x, Jtcr_x, 'int32')));
            E_Jtcr_y = max(hPband.pos_y, Jtcr_y * (idx_y + floor_quotient_int(hPband.pos_y, Jtcr_y, 'int32')));
            F_Jtcr_x = min(hPband.pos_x + pband_size_x, Jtcr_x * (idx_x + 1 + floor_quotient_int(hPband.pos_x, Jtcr_x, 'int32')));
            F_Jtcr_y = min(hPband.pos_y + pband_size_y, Jtcr_y * (idx_y + 1 + floor_quotient_int(hPband.pos_y, Jtcr_y, 'int32')));
            
            pos_x = E_Jtcr_x - hPband.pos_x;
            pos_y = E_Jtcr_y - hPband.pos_y;
            size_x = F_Jtcr_x - E_Jtcr_x;
            size_y = F_Jtcr_y - E_Jtcr_y;
            
            currentCodeblock = codeblock_body([], idx_c, uint32(idx_x), uint32(idx_y), ...
                pos_x, pos_y, uint16(size_x), uint16(size_y), ...
                band_idx, raster_precinct_idx, r, ...
                Cmodes, num_layers, M_b, W_b, Delta_b, normalized_delta);
            add_codeblockinfo_to_pband(hPband, currentCodeblock);
            
        end
    end
    hPband.numCblksX = hPband.numCblksX;
    hPband.numCblksY = hPband.numCblksY;
    % code-block inclusion information
    hPband.inclusionInfo = tagTree(hPband.numCblksX, hPband.numCblksY);
    % ZBP information
    hPband.ZBPInfo = tagTree(hPband.numCblksX, hPband.numCblksY);
end


