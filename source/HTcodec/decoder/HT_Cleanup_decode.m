function [mu_n, s_n, sigma_n] = HT_Cleanup_decode(Dcup, QW, QH)

M_OFFSET = 1;
%% Decoding start

%% Retrieve Lcup, Scup and Pcup from byte-streams
Lcup = length(Dcup); % length of all byte-stream
x_0F = uint32(15);
Scup = 16*uint32(Dcup(Lcup-1+1)) + bitand(uint32(Dcup(Lcup-2+1)), x_0F); % length of suffix: MEL and VLC byte-stream
Pcup = Lcup - Scup;% length of MagSgn byte-stream

assert(Lcup == Scup+Pcup);

%% Prepare buffers
sigma = zeros(1, 4*QH*QW, 'uint8');
known_bit = zeros(1, 4*QH*QW, 'uint8');
known_1 = zeros(1, 4*QH*QW, 'uint8');
context = zeros(1, QW*QH, 'int32');
rho = zeros(1, QW*QH, 'uint8');
u_off = zeros(1, QW*QH, 'uint8');
emb_k = zeros(1, QW*QH, 'uint8');
emb_1 = zeros(1, QW*QH, 'uint8');
u = zeros(1, QW*QH, 'int32');
gamma = zeros(1, QW*QH, 'uint8');
kappa = zeros(1, QW*QH, 'uint8');
U = zeros(1, QW*QH, 'int32');
m = zeros(1, 4*QH*QW, 'int32');
v = zeros(1, 4*QH*QW, 'int32');
E = zeros(1, 4*QH*QW, 'uint8');
mu = zeros(1, 4*QH*QW, 'uint32');
s = zeros(1, 4*QH*QW, 'int32');
%MagSgn_rec = zeros(1, 4*QH*QW);

kappa(1:QW) = 1; % set k_q = 1 for initial line-pairs

%% Initialize state machines
state_MS = initMS;
state_MEL_unPacker = initMEL(Pcup);
state_MEL = initMELDecoder;
state_VLC = initVLC(Dcup, Lcup);
%% Decoding of initial line-pairs

dec_CxtVLC_table = get_dec_CxtVLC_table_0_fast;
for q = 0:2:QW-1
    HAVE_2ND_QUAD = true;
    if mod(QW, 2) == 1 && q == QW - 1
        HAVE_2ND_QUAD = false;
    end
    q1 = q; q2 = q + 1;
    %% CxtVLC decoding for each quad in a quad-pair
    [sigma_sw, sigma_w, sigma_sf, sigma_f, ~, ~, ~, ~] = retrieve_neighbouring_significance_pattern(sigma, q1, QW);
    context(q1+M_OFFSET) = bitor(sigma_f, sigma_sf) + 2*sigma_w + 4*sigma_sw;
    
    [rho(q1+M_OFFSET), u_off(q1+M_OFFSET), emb_k(q1+M_OFFSET), emb_1(q1+M_OFFSET)] = ...
        decodeSigEMB(context(q1+M_OFFSET), Dcup, Pcup, Lcup, state_MEL, state_MEL_unPacker, state_VLC, dec_CxtVLC_table);
    % assertion for DEBUG
    if u_off(q1+M_OFFSET) == 0
        assert(emb_k(q1+M_OFFSET) == 0 && emb_1(q1+M_OFFSET) == 0);
    end
    % determine sigma, k and i in association with q1
    for i = 0:3
        sigma(4*q1+M_OFFSET+i) =  bitand(bitshift(rho(q1+M_OFFSET),-i), 1);
        known_bit(4*q1+M_OFFSET+i) = bitand(bitshift(emb_k(q1+M_OFFSET),-i), 1);
        known_1(4*q1+M_OFFSET+i) = bitand(bitshift(emb_1(q1+M_OFFSET),-i), 1);
    end
    
    if HAVE_2ND_QUAD == true
        [sigma_sw, sigma_w, sigma_sf, sigma_f, ~, ~, ~, ~] = retrieve_neighbouring_significance_pattern(sigma, q2, QW);
        context(q2+M_OFFSET) = bitor(sigma_f, sigma_sf) + 2*sigma_w + 4*sigma_sw;
        [rho(q2+M_OFFSET), u_off(q2+M_OFFSET), emb_k(q2+M_OFFSET), emb_1(q2+M_OFFSET)] = ...
            decodeSigEMB(context(q2+M_OFFSET), Dcup, Pcup, Lcup, state_MEL, state_MEL_unPacker, state_VLC, dec_CxtVLC_table);
        % assertion for DEBUG
        if u_off(q2+M_OFFSET) == 0
            assert(emb_k(q2+M_OFFSET) == 0 && emb_1(q2+M_OFFSET) == 0);
        end
        % determine sigma, k and i in association with q2
        for i = 0:3
            sigma(4*q2+M_OFFSET+i) =  bitand(bitshift(rho(q2+M_OFFSET),-i), 1);
            known_bit(4*q2+M_OFFSET+i) = bitand(bitshift(emb_k(q2+M_OFFSET),-i), 1);
            known_1(4*q2+M_OFFSET+i) = bitand(bitshift(emb_1(q2+M_OFFSET),-i), 1);
        end
        
        %% UVLC decoding for two-quads in a quad-pair
        if u_off(q1+M_OFFSET) == 1 && u_off(q2+M_OFFSET) == 1
            s_mel_q1q2 = decodeMELSym(Dcup, Lcup, state_MEL, state_MEL_unPacker);
            if s_mel_q1q2 == 1
                u_pfx1 = decodeUPrefix(Dcup, Pcup, Lcup, state_VLC);
                u_pfx2 = decodeUPrefix(Dcup, Pcup, Lcup, state_VLC);
                u_sfx1 = decodeUSuffix(u_pfx1, Dcup, Pcup, Lcup, state_VLC);
                u_sfx2 = decodeUSuffix(u_pfx2, Dcup, Pcup, Lcup, state_VLC);
                u_ext1 = decodeUExtension(u_sfx1, Dcup, Pcup, Lcup, state_VLC);
                u_ext2 = decodeUExtension(u_sfx2, Dcup, Pcup, Lcup, state_VLC);
                u(q1+M_OFFSET) = 2 + u_pfx1 + u_sfx1 + 4*u_ext1;
                u(q2+M_OFFSET) = 2 + u_pfx2 + u_sfx2 + 4*u_ext2;
            else
                u_pfx1 = decodeUPrefix(Dcup, Pcup, Lcup, state_VLC);
                if u_pfx1 > 2 % (this is equal to u_q1 > 2
                    u_bit = importVLCBit(Dcup, Pcup, Lcup, state_VLC);
                    u(q2+M_OFFSET) = u_bit + 1; % u_pfx = ubit+1;
                    u_sfx1 = decodeUSuffix(u_pfx1, Dcup, Pcup, Lcup, state_VLC);
                    u_ext1 = decodeUExtension(u_sfx1, Dcup, Pcup, Lcup, state_VLC);
                else
                    u_pfx2 = decodeUPrefix(Dcup, Pcup, Lcup, state_VLC);
                    u_sfx1 = decodeUSuffix(u_pfx1, Dcup, Pcup, Lcup, state_VLC);
                    u_sfx2 = decodeUSuffix(u_pfx2, Dcup, Pcup, Lcup, state_VLC);
                    u_ext1 = decodeUExtension(u_sfx1, Dcup, Pcup, Lcup, state_VLC);
                    u_ext2 = decodeUExtension(u_sfx2, Dcup, Pcup, Lcup, state_VLC);
                    u(q2+M_OFFSET) = u_pfx2 + u_sfx2 + 4*u_ext2;
                end
                u(q1+M_OFFSET) = u_pfx1 + u_sfx1 + 4*u_ext1;
            end
        elseif u_off(q1+M_OFFSET) == 1 && u_off(q2+M_OFFSET) == 0
            u_pfx1 = decodeUPrefix(Dcup, Pcup, Lcup, state_VLC);
            u_sfx1 = decodeUSuffix(u_pfx1, Dcup, Pcup, Lcup, state_VLC);
            u_ext1 = decodeUExtension(u_sfx1, Dcup, Pcup, Lcup, state_VLC);
            u(q1+M_OFFSET) = u_pfx1 + u_sfx1 + 4*u_ext1;
            u(q2+M_OFFSET) = 0;
        elseif u_off(q1+M_OFFSET) == 0 && u_off(q2+M_OFFSET) == 1
            u_pfx2 = decodeUPrefix(Dcup, Pcup, Lcup, state_VLC);
            u_sfx2 = decodeUSuffix(u_pfx2, Dcup, Pcup, Lcup, state_VLC);
            u_ext2 = decodeUExtension(u_sfx2, Dcup, Pcup, Lcup, state_VLC);
            u(q1+M_OFFSET) = 0;
            u(q2+M_OFFSET) = u_pfx2 + u_sfx2 + 4*u_ext2;
        else
            u(q1+M_OFFSET) = 0;
            u(q2+M_OFFSET) = 0;
        end
    elseif u_off(q1+M_OFFSET) == 1
        u_pfx1 = decodeUPrefix(Dcup, Pcup, Lcup, state_VLC);
        u_sfx1 = decodeUSuffix(u_pfx1, Dcup, Pcup, Lcup, state_VLC);
        u_ext1 = decodeUExtension(u_sfx1, Dcup, Pcup, Lcup, state_VLC);
        u(q1+M_OFFSET) = u_pfx1 + u_sfx1 + 4*u_ext1;
    else
        u(q1+M_OFFSET) = 0;
        
    end
    
    %% determination of U_q
    U(q1+M_OFFSET) = int32(kappa(q1+M_OFFSET)) + u(q1+M_OFFSET);
    if HAVE_2ND_QUAD == true
        U(q2+M_OFFSET) = int32(kappa(q2+M_OFFSET)) + u(q2+M_OFFSET);
    end
    
    for i = 0:3
        m(4*q1+M_OFFSET+i) = int32(sigma(4*q1+i+M_OFFSET))*U(q1+M_OFFSET) - int32(known_bit(4*q1+i+M_OFFSET));
        if HAVE_2ND_QUAD == true
            m(4*q2+M_OFFSET+i) = int32(sigma(4*q2+i+M_OFFSET))*U(q2+M_OFFSET) - int32(known_bit(4*q2+i+M_OFFSET));
        end
    end
    
    %% compute Magnitude Exponent E
    for i = 0:3
        [E(4*q1+M_OFFSET+i), mu(4*q1+M_OFFSET+i), s(4*q1+M_OFFSET+i), v(4*q1+M_OFFSET+i)] = ...
            recoverMagSgnValue(m(4*q1+M_OFFSET+i), known_1(4*q1+M_OFFSET+i), Dcup, Pcup, Lcup, state_MS);
    end
    if HAVE_2ND_QUAD == true
        for i = 0:3
            [E(4*q2+M_OFFSET+i), mu(4*q2+M_OFFSET+i), s(4*q2+M_OFFSET+i), v(4*q2+M_OFFSET+i)] = ...
                recoverMagSgnValue(m(4*q2+M_OFFSET+i), known_1(4*q2+M_OFFSET+i), Dcup, Pcup, Lcup, state_MS);
        end
    end
    
    % assertion for DEBUG
    if u_off(q1+M_OFFSET) == 1
        assert(U(q1+M_OFFSET) == max(E(4*q1+M_OFFSET:4*q1+3+M_OFFSET)), '%d %d', U(q1+M_OFFSET), max(E(4*q1+M_OFFSET:4*q1+3+M_OFFSET)));
    end
    if HAVE_2ND_QUAD == true
        if u_off(q2+M_OFFSET) == 1
            assert(U(q2+M_OFFSET) == max(E(4*q2+M_OFFSET:4*q2+3+M_OFFSET)));
        end
    end
end

dec_CxtVLC_table = get_dec_CxtVLC_table_1_fast;
%% Decoding of non-initial line-pairs
for QuadRow = 1:QH-1
    for QuadColumn = 0:2:QW-1
        q = QuadColumn+QW*QuadRow;
        HAVE_2ND_QUAD = true;
        if mod(QW, 2) == 1 && QuadColumn == QW - 1
            HAVE_2ND_QUAD = false;
        end
        q1 = q; q2 = q + 1;
        %% CxtVLC decoding for each quad in a quad-pair
        [sigma_sw, sigma_w, ~, ~, sigma_n, sigma_ne, sigma_nw, sigma_nf] = retrieve_neighbouring_significance_pattern(sigma, q1, QW);
        context(q1+M_OFFSET) = bitor(sigma_nw, sigma_n) + 2*bitor(sigma_w, sigma_sw) + 4*bitor(sigma_ne, sigma_nf);
        [rho(q1+M_OFFSET), u_off(q1+M_OFFSET), emb_k(q1+M_OFFSET), emb_1(q1+M_OFFSET)] = ...
            decodeSigEMB(context(q1+M_OFFSET), Dcup, Pcup, Lcup, state_MEL, state_MEL_unPacker, state_VLC, dec_CxtVLC_table);
        % assertion for DEBUG
        if u_off(q1+M_OFFSET) == 0
            assert(emb_k(q1+M_OFFSET) == 0 && emb_1(q1+M_OFFSET) == 0);
        end
        % determine sigma, k and i in association with q1
        for i = 0:3
            sigma(4*q1+M_OFFSET+i) =  bitand(bitshift(rho(q1+M_OFFSET),-i), 1);
            known_bit(4*q1+M_OFFSET+i) = bitand(bitshift(emb_k(q1+M_OFFSET),-i), 1);
            known_1(4*q1+M_OFFSET+i) = bitand(bitshift(emb_1(q1+M_OFFSET),-i), 1);
        end
        
        if HAVE_2ND_QUAD == true
            [sigma_sw, sigma_w, ~, ~, sigma_n, sigma_ne, sigma_nw, sigma_nf] = retrieve_neighbouring_significance_pattern(sigma, q2, QW);
            context(q2+M_OFFSET) = bitor(sigma_nw, sigma_n) + 2*bitor(sigma_w, sigma_sw) + 4*bitor(sigma_ne, sigma_nf);
            [rho(q2+M_OFFSET), u_off(q2+M_OFFSET), emb_k(q2+M_OFFSET), emb_1(q2+M_OFFSET)] = ...
                decodeSigEMB(context(q2+M_OFFSET), Dcup, Pcup, Lcup, state_MEL, state_MEL_unPacker, state_VLC, dec_CxtVLC_table);
            % assertion for DEBUG
            if u_off(q2+M_OFFSET) == 0
                assert(emb_k(q2+M_OFFSET) == 0 && emb_1(q2+M_OFFSET) == 0);
            end
            % determine sigma, k and i in association with q2
            for i = 0:3
                sigma(4*q2+M_OFFSET+i) =  bitand(bitshift(rho(q2+M_OFFSET),-i), 1);
                known_bit(4*q2+M_OFFSET+i) = bitand(bitshift(emb_k(q2+M_OFFSET),-i), 1);
                known_1(4*q2+M_OFFSET+i) = bitand(bitshift(emb_1(q2+M_OFFSET),-i), 1);
            end
            
            %% UVLC decoding for two-quads in a quad-pair
            if u_off(q1+M_OFFSET) == 1 && u_off(q2+M_OFFSET) == 1
                u_pfx1 = decodeUPrefix(Dcup, Pcup, Lcup, state_VLC);
                u_pfx2 = decodeUPrefix(Dcup, Pcup, Lcup, state_VLC);
                u_sfx1 = decodeUSuffix(u_pfx1, Dcup, Pcup, Lcup, state_VLC);
                u_sfx2 = decodeUSuffix(u_pfx2, Dcup, Pcup, Lcup, state_VLC);
                u_ext1 = decodeUExtension(u_sfx1, Dcup, Pcup, Lcup, state_VLC);
                u_ext2 = decodeUExtension(u_sfx2, Dcup, Pcup, Lcup, state_VLC);
                u(q1+M_OFFSET) = u_pfx1 + u_sfx1 + 4*u_ext1;
                u(q2+M_OFFSET) = u_pfx2 + u_sfx2 + 4*u_ext2;
            elseif u_off(q1+M_OFFSET) == 1 && u_off(q2+M_OFFSET) == 0
                u_pfx1 = decodeUPrefix(Dcup, Pcup, Lcup, state_VLC);
                u_sfx1 = decodeUSuffix(u_pfx1, Dcup, Pcup, Lcup, state_VLC);
                u_ext1 = decodeUExtension(u_sfx1, Dcup, Pcup, Lcup, state_VLC);
                u(q1+M_OFFSET) = u_pfx1 + u_sfx1 + 4*u_ext1;
                u(q2+M_OFFSET) = 0;
            elseif u_off(q1+M_OFFSET) == 0 && u_off(q2+M_OFFSET) == 1
                u(q1+M_OFFSET) = 0;
                u_pfx2 = decodeUPrefix(Dcup, Pcup, Lcup, state_VLC);
                u_sfx2 = decodeUSuffix(u_pfx2, Dcup, Pcup, Lcup, state_VLC);
                u_ext2 = decodeUExtension(u_sfx2, Dcup, Pcup, Lcup, state_VLC);
                u(q2+M_OFFSET) = u_pfx2 + u_sfx2 + 4*u_ext2;
            else
                u(q1+M_OFFSET) = 0;
                u(q2+M_OFFSET) = 0;
            end
        elseif u_off(q1+M_OFFSET) == 1
            u_pfx1 = decodeUPrefix(Dcup, Pcup, Lcup, state_VLC);
            u_sfx1 = decodeUSuffix(u_pfx1, Dcup, Pcup, Lcup, state_VLC);
            u_ext1 = decodeUExtension(u_sfx1, Dcup, Pcup, Lcup, state_VLC);
            u(q1+M_OFFSET) = u_pfx1 + u_sfx1 + 4*u_ext1;
        else
            u(q1+M_OFFSET) = 0;
        end
        
        gamma(q1+M_OFFSET) = compute_gamma_from_rho(rho(q1+M_OFFSET));
        kappa(q1+M_OFFSET) = form_exponent_predictors(E, gamma(q1+M_OFFSET), q1, QW);
        if HAVE_2ND_QUAD == true
            gamma(q2+M_OFFSET) = compute_gamma_from_rho(rho(q2+M_OFFSET));
            kappa(q2+M_OFFSET) = form_exponent_predictors(E, gamma(q2+M_OFFSET), q2, QW);
        end
        %% determination of U_q
        U(q1+M_OFFSET) = int32(kappa(q1+M_OFFSET)) + u(q1+M_OFFSET);
        if HAVE_2ND_QUAD == true
            U(q2+M_OFFSET) = int32(kappa(q2+M_OFFSET)) + u(q2+M_OFFSET);
        end
        for i = 0:3
            m(4*q1+M_OFFSET+i) = int32(sigma(4*q1+i+M_OFFSET))*U(q1+M_OFFSET) - int32(known_bit(4*q1+i+M_OFFSET));
            if HAVE_2ND_QUAD == true
                m(4*q2+M_OFFSET+i) = int32(sigma(4*q2+i+M_OFFSET))*U(q2+M_OFFSET) - int32(known_bit(4*q2+i+M_OFFSET));
            end
        end
        
        %% compute Magnitude Exponent E
        for i = 0:3
            [E(4*q1+M_OFFSET+i), mu(4*q1+M_OFFSET+i), s(4*q1+M_OFFSET+i), v(4*q1+M_OFFSET+i)] = ...
                recoverMagSgnValue(m(4*q1+M_OFFSET+i), known_1(4*q1+M_OFFSET+i), Dcup, Pcup, Lcup, state_MS);
        end
        if HAVE_2ND_QUAD == true
            for i = 0:3
                [E(4*q2+M_OFFSET+i), mu(4*q2+M_OFFSET+i), s(4*q2+M_OFFSET+i), v(4*q2+M_OFFSET+i)] = ...
                    recoverMagSgnValue(m(4*q2+M_OFFSET+i), known_1(4*q2+M_OFFSET+i), Dcup, Pcup, Lcup, state_MS);
            end
        end

        % assertion for DEBUG
        if u_off(q1+M_OFFSET) == 1
            assert(U(q1+M_OFFSET) == max(E(4*q1+M_OFFSET:4*q1+3+M_OFFSET)),'%d', q1);
        end
        if HAVE_2ND_QUAD == true
            if u_off(q2+M_OFFSET) == 1
                assert(U(q2+M_OFFSET) == max(E(4*q2+M_OFFSET:4*q2+3+M_OFFSET)));
            end
        end
    end
end
% convert scanning order
mu_n = makeInverseQuadScanorder(mu, QW, QH, false);
s_n = makeInverseQuadScanorder(s, QW, QH, false);
sigma_n = makeInverseQuadScanorder(sigma, QW, QH, false);
