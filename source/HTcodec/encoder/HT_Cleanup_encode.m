function [encoder_output, sigma, QW, QH] = HT_Cleanup_encode(codeblock_coeff, p) %#codegen

M_OFFSET = 1; % for matlab offset

%% make storages for significance(sigma), exponents(E) and MagSgn values (v)
[sigma, E, v, QW, QH] = make_storage_for_significance_exponents_MagSgnValues(codeblock_coeff, p);

%% prepare buffers
output = zeros(QW * QH, 3, 'uint8'); %
U = zeros(1, QW * QH, 'uint8'); %
kappa = zeros(1, QW * QH, 'uint8'); %
u = zeros(1, QW * QH, 'int32'); %
u_off = zeros(1, QW * QH, 'uint8'); %
gamma = zeros(1, QW * QH, 'uint8'); %
eps_bar = zeros(1, QW * QH, 'uint8'); %
rho = zeros(1, QW * QH, 'uint8'); %
n = zeros(1, QW * QH, 'int32');
context = zeros(1, QW * QH, 'uint8'); %
m = zeros(1, 4 * QW * QH, 'uint8'); %
m_mel = zeros(1, QW * QH, 'uint8'); %
s_mel = zeros(1, QW * QH, 'uint8'); %
CxtVLC = zeros(1, QW * QH, 'int32'); %
iemb_k = zeros(1, QW * QH, 'uint8'); %
l_w = zeros(1, QW * QH, 'uint8'); %

%% CxtVLC for an initial line-pair
enc_CxtVLC_table_0 = get_enc_CxtVLC_table_0;

%% CxtVLC for non-initial line-pairs
enc_CxtVLC_table_1 = get_enc_CxtVLC_table_1;

%% initialize state machines
% MEL and MELPacker
state_MEL = initMELEncoder;
state_MELPacker = initMELPacker;
MEL_buf = zeros(1, 64 * 64, 'uint8');
% VLCPacker
state_VLC = initVLCPacker;
VLC_buf = zeros(1, 64 * 64, 'uint8');
VLC_buf(1) = 255;

% MagSgn
state_MS = initMSPacker;
MS_buf = zeros(1, 65535 - 4079, 'uint8');

enc_table_UVLC = get_enc_UVLC_table_initial;

%% INITIAL-PAIRS
for q = 0:2:QW - 1
    HAVE_2ND_QUAD = true;
    if mod(QW, 2) == 1 && q == QW - 1
        HAVE_2ND_QUAD = false;
    end
    q1 = q; % if QW-1 is even(equal to QW is odd), nothing shold not be done for q2!
    q2 = q + 1; % if QW-1 is even(equal to QW is odd), nothing shold not be done for q2!

    %% 1st quad in the pair
    rho(q1 + M_OFFSET) = retrieve_significance_pattern(sigma, q1);
    kappa(q1 + M_OFFSET) = 1; % kappa_q shall always equals to 1 for initial line-pairs

    [U(q1 + M_OFFSET), u(q1 + M_OFFSET), u_off(q1 + M_OFFSET), eps_bar(q1 + M_OFFSET)] = ...
        compute_magnitudeExponent_residual_EMBpattern(E, q1, kappa(q1 + M_OFFSET));

    [sigma_sw, sigma_w, sigma_sf, sigma_f, ~, ~, ~, ~] = ...
        retrieve_neighbouring_significance_pattern(sigma, q1, QW);

    context(q1 + M_OFFSET) = bitor(sigma_f, sigma_sf) + 2 * sigma_w + 4 * sigma_sw;

    n(q1 + M_OFFSET) = int32(eps_bar(q1 + M_OFFSET)) + 16 * int32(rho(q1 + M_OFFSET)) + 256 * int32(context(q1 + M_OFFSET));
    output(q1 + M_OFFSET, :) = enc_CxtVLC_table_0(n(q1 + M_OFFSET) + 1, :); % returns a triplet (w, iemb_k_q,l_w) from CxtVLC_table
    CxtVLC(q1 + M_OFFSET) = output(q1 + M_OFFSET, 1);
    iemb_k(q1 + M_OFFSET) = output(q1 + M_OFFSET, 2);
    l_w(q1 + M_OFFSET) = output(q1 + M_OFFSET, 3);

    if HAVE_2ND_QUAD == true

        %% 2nd quad in the pair
        rho(q2 + M_OFFSET) = retrieve_significance_pattern(sigma, q2);
        kappa(q2 + M_OFFSET) = 1; % kappa_q shall always equals to 1 for initial line-pairs

        [U(q2 + M_OFFSET), u(q2 + M_OFFSET), u_off(q2 + M_OFFSET), eps_bar(q2 + M_OFFSET)] = ...
            compute_magnitudeExponent_residual_EMBpattern(E, q2, kappa(q2 + M_OFFSET));

        [sigma_sw, sigma_w, sigma_sf, sigma_f, ~, ~, ~, ~] = ...
            retrieve_neighbouring_significance_pattern(sigma, q2, QW);

        context(q2 + M_OFFSET) = bitor(sigma_f, sigma_sf) + 2 * sigma_w + 4 * sigma_sw;

        n(q2 + M_OFFSET) = int32(eps_bar(q2 + M_OFFSET)) + 16 * int32(rho(q2 + M_OFFSET)) + 256 * int32(context(q2 + M_OFFSET));
        output(q2 + M_OFFSET, :) = enc_CxtVLC_table_0(n(q2 + M_OFFSET) + 1, :); % returns a triplet (w, iemb_k_q,l_w) from CxtVLC_table
        CxtVLC(q2 + M_OFFSET) = output(q2 + M_OFFSET, 1);
        iemb_k(q2 + M_OFFSET) = output(q2 + M_OFFSET, 2);
        l_w(q2 + M_OFFSET) = output(q2 + M_OFFSET, 3);
    end

    %% MEL encoding
    if context(q1 + M_OFFSET) == 0
        if rho(q1 + M_OFFSET) ~= 0
            MEL_buf = encodeMEL(1, 1, MEL_buf, state_MEL, state_MELPacker);
        else
            MEL_buf = encodeMEL(0, 1, MEL_buf, state_MEL, state_MELPacker);
        end
    end
    if HAVE_2ND_QUAD == true
        if context(q2 + M_OFFSET) == 0
            if rho(q2 + M_OFFSET) ~= 0
                MEL_buf = encodeMEL(1, 1, MEL_buf, state_MEL, state_MELPacker);
            else
                if min([u(q1 + M_OFFSET), u(q2 + M_OFFSET)]) > 2
                    MEL_buf = encodeMEL(1, 1, MEL_buf, state_MEL, state_MELPacker);
                else
                    MEL_buf = encodeMEL(0, 1, MEL_buf, state_MEL, state_MELPacker);
                end
            end
        elseif u_off(q1 + M_OFFSET) == 1 && u_off(q2 + M_OFFSET) == 1
            if min([u(q1 + M_OFFSET), u(q2 + M_OFFSET)]) > 2
                MEL_buf = encodeMEL(1, 1, MEL_buf, state_MEL, state_MELPacker);
            else
                MEL_buf = encodeMEL(0, 1, MEL_buf, state_MEL, state_MELPacker);
            end
        end
    end

    %% UVLC encoding
    if HAVE_2ND_QUAD == true
        VLC_buf = emitVLCBits(CxtVLC(q1 + M_OFFSET), l_w(q1 + M_OFFSET), VLC_buf, state_VLC);
        VLC_buf = emitVLCBits(CxtVLC(q2 + M_OFFSET), l_w(q2 + M_OFFSET), VLC_buf, state_VLC);
        [cwd, len] = pack_UVLC_codeword_components_reversed_table(enc_table_UVLC, u(q1 + M_OFFSET), u(q2 + M_OFFSET));
        VLC_buf = emitVLCBits(cwd, len, VLC_buf, state_VLC);
    else % all other cases in the first row of quads
        VLC_buf = emitVLCBits(CxtVLC(q1 + M_OFFSET), l_w(q1 + M_OFFSET), VLC_buf, state_VLC);
        [cwd, len] = pack_UVLC_codeword_components_reversed_table(enc_table_UVLC, u(q1 + M_OFFSET));
        VLC_buf = emitVLCBits(cwd, len, VLC_buf, state_VLC);
    end

    %% MagSgn encoding
    m(4 * q1 + M_OFFSET:4 * (q1 + 1)) = compute_MagSgn_bitCounts(rho, U, iemb_k, q1);
    for j = 0:3
        idx = 4 * q1 + j;
        MS_buf = emitMagSgnBits(v(idx + M_OFFSET), m(idx + M_OFFSET), MS_buf, state_MS);
    end
    if HAVE_2ND_QUAD == true
        m(4 * q2 + M_OFFSET:4 * (q2 + 1)) = compute_MagSgn_bitCounts(rho, U, iemb_k, q2);
        for j = 0:3
            idx = 4 * q2 + j;
            MS_buf = emitMagSgnBits(v(idx + M_OFFSET), m(idx + M_OFFSET), MS_buf, state_MS);
        end
    end
end

enc_table_UVLC = get_enc_UVLC_table_noninitial;

%% NON-INITIAL PAIRS
%for q=QW:2:QW*QH-1
for QuadRow = 2:QH
    for QuadColumn = 0:2:QW - 1
        q = QuadColumn + QW * (QuadRow - 1);
        HAVE_2ND_QUAD = true;
        if mod(QW, 2) == 1 && QuadColumn == QW - 1
            HAVE_2ND_QUAD = false;
        end
        q1 = q; % if QW-1 is even(equal to QW is odd), nothing shold not be done for q2!
        q2 = q + 1; % if QW-1 is even(equal to QW is odd), nothing shold not be done for q2!

        %% 1st quad in the pair
        rho(q1 + M_OFFSET) = retrieve_significance_pattern(sigma, q1);
        gamma(q1 + M_OFFSET) = compute_gamma_from_rho(rho(q1 + M_OFFSET));
        kappa(q1 + M_OFFSET) = form_exponent_predictors(E, gamma(q1 + M_OFFSET), q1, QW);

        [U(q1 + M_OFFSET), u(q1 + M_OFFSET), u_off(q1 + M_OFFSET), eps_bar(q1 + M_OFFSET)] = ...
            compute_magnitudeExponent_residual_EMBpattern(E, q1, kappa(q1 + M_OFFSET));

        [sigma_sw, sigma_w, ~, ~, sigma_n, sigma_ne, sigma_nw, sigma_nf] = ...
            retrieve_neighbouring_significance_pattern(sigma, q1, QW);

        context(q1 + M_OFFSET) = bitor(sigma_nw, sigma_n) + 2 * bitor(sigma_w, sigma_sw) + 4 * bitor(sigma_ne, sigma_nf);

        n(q1 + M_OFFSET) = int32(eps_bar(q1 + M_OFFSET)) + 16 * int32(rho(q1 + M_OFFSET)) + 256 * int32(context(q1 + M_OFFSET));
        output(q1 + M_OFFSET, :) = enc_CxtVLC_table_1(n(q1 + M_OFFSET) + 1, :); % returns a triplet (w, iemb_k_q,l_w) from CxtVLC_table
        CxtVLC(q1 + M_OFFSET) = output(q1 + M_OFFSET, 1);
        iemb_k(q1 + M_OFFSET) = output(q1 + M_OFFSET, 2);
        l_w(q1 + M_OFFSET) = output(q1 + M_OFFSET, 3);

        if HAVE_2ND_QUAD == true

            %% 2nd quad in the pair
            rho(q2 + M_OFFSET) = retrieve_significance_pattern(sigma, q2);
            gamma(q2 + M_OFFSET) = compute_gamma_from_rho(rho(q2 + M_OFFSET));
            kappa(q2 + M_OFFSET) = form_exponent_predictors(E, gamma(q2 + M_OFFSET), q2, QW);

            [U(q2 + M_OFFSET), u(q2 + M_OFFSET), u_off(q2 + M_OFFSET), eps_bar(q2 + M_OFFSET)] = ...
                compute_magnitudeExponent_residual_EMBpattern(E, q2, kappa(q2 + M_OFFSET));

            [sigma_sw, sigma_w, ~, ~, sigma_n, sigma_ne, sigma_nw, sigma_nf] = ...
                retrieve_neighbouring_significance_pattern(sigma, q2, QW);

            context(q2 + M_OFFSET) = bitor(sigma_nw, sigma_n) + 2 * bitor(sigma_w, sigma_sw) + 4 * bitor(sigma_ne, sigma_nf);

            n(q2 + M_OFFSET) = int32(eps_bar(q2 + M_OFFSET)) + 16 * int32(rho(q2 + M_OFFSET)) + 256 * int32(context(q2 + M_OFFSET));
            output(q2 + M_OFFSET, :) = enc_CxtVLC_table_1(n(q2 + M_OFFSET) + 1, :); % returns a triplet (w, iemb_k_q,l_w) from CxtVLC_table
            CxtVLC(q2 + M_OFFSET) = output(q2 + M_OFFSET, 1);
            iemb_k(q2 + M_OFFSET) = output(q2 + M_OFFSET, 2);
            l_w(q2 + M_OFFSET) = output(q2 + M_OFFSET, 3);
        end

        %% MEL encoding
        if context(q1 + M_OFFSET) == 0
            if rho(q1 + M_OFFSET) ~= 0
                MEL_buf = encodeMEL(1, 1, MEL_buf, state_MEL, state_MELPacker);
            else
                MEL_buf = encodeMEL(0, 1, MEL_buf, state_MEL, state_MELPacker);
            end
        end
        if HAVE_2ND_QUAD == true
            if context(q2 + M_OFFSET) == 0
                if rho(q2 + M_OFFSET) ~= 0
                    MEL_buf = encodeMEL(1, 1, MEL_buf, state_MEL, state_MELPacker);
                else
                    MEL_buf = encodeMEL(0, 1, MEL_buf, state_MEL, state_MELPacker);
                end
            end
        end

        %% UVLC encoding
        VLC_buf = emitVLCBits(CxtVLC(q1 + M_OFFSET), l_w(q1 + M_OFFSET), VLC_buf, state_VLC);
        if HAVE_2ND_QUAD == true
            VLC_buf = emitVLCBits(CxtVLC(q2 + M_OFFSET), l_w(q2 + M_OFFSET), VLC_buf, state_VLC);
        end
        if HAVE_2ND_QUAD == true
            [cwd, len] = pack_UVLC_codeword_components_reversed_table(enc_table_UVLC, u(q1 + M_OFFSET), u(q2 + M_OFFSET));
        else
            [cwd, len] = pack_UVLC_codeword_components_reversed_table(enc_table_UVLC, u(q1 + M_OFFSET));
        end
        VLC_buf = emitVLCBits(cwd, len, VLC_buf, state_VLC);

        %% MagSgn encoding
        m(4 * q1 + M_OFFSET:4 * (q1 + 1)) = compute_MagSgn_bitCounts(rho, U, iemb_k, q1);
        for j = 0:3
            idx = 4 * q1 + j;
            MS_buf = emitMagSgnBits(v(idx + M_OFFSET), m(idx + M_OFFSET), MS_buf, state_MS);
        end
        if HAVE_2ND_QUAD == true
            m(4 * q2 + M_OFFSET:4 * (q2 + 1)) = compute_MagSgn_bitCounts(rho, U, iemb_k, q2);
            for j = 0:3
                idx = 4 * q2 + j;
                MS_buf = emitMagSgnBits(v(idx + M_OFFSET), m(idx + M_OFFSET), MS_buf, state_MS);
            end
        end
    end
end

%% termination of MEL bit-stream
MEL_buf = termMEL(MEL_buf, state_MEL, state_MELPacker);

%% Bit-stuffing to produce MagSgn byte-stream from MagSgn bit-stream
MS_buf = termMSPacker(MS_buf, state_MS);
MS_buf = MS_buf(1:state_MS.MS_pos);

%% termination of MEL and VLC bit-streams
[MEL_buf, VLC_buf] = termMELandVLCPackers(MEL_buf, VLC_buf, state_MELPacker, state_VLC);
MEL_buf = MEL_buf(1:state_MELPacker.MEL_pos);
VLC_buf = VLC_buf(1:state_VLC.VLC_pos);

% DEBUG
% fprintf('MATLAB* MagSgnbytes = %d, MELbytes = %d, VLCbytes = %d\n', state_MS.MS_pos, state_MELPacker.MEL_pos, state_VLC.VLC_pos);
% Because the termination process in this implementation is very simple,
% values showed above may differ from the values produced by Reference software

%% Make VLC-bytestream reversed
VLC_buf = fliplr(VLC_buf);

Dcup = [MS_buf, MEL_buf, VLC_buf];
Lcup = length(Dcup);
Scup = state_MELPacker.MEL_pos + state_VLC.VLC_pos; % Suffix length
Dcup(Lcup - 1 + M_OFFSET) = bitshift(Scup, -4);
x_F0 = uint8(240);
x_0F = uint32(15);
Dcup(Lcup - 2 + M_OFFSET) = bitor(bitand(Dcup(Lcup - 2 + M_OFFSET), x_F0), uint8(bitand(Scup, x_0F)));

encoder_output = Dcup;
