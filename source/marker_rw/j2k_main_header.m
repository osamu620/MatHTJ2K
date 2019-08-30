classdef j2k_main_header < handle
    properties
        SIZ SIZ_marker
        COD COD_marker
        COC COC_marker
        RGN RGN_marker
        QCD QCD_marker
        QCC QCC_marker
        POC POC_marker
        COM COM_marker
        CAP CAP_marker
        CRG CRG_marker
        TLM TLM_marker
        PPM PPM_marker
        CPF CPF_marker
        PRF PRF_marker
        Cap15_b14_15 (1,1) int8 = -1 
        Cap15_b13 logical
        Cap15_b12 logical
        Cap15_b11 logical
        Cap15_b5 logical
        Cap15_b0_4 uint8
        Cap15_magb uint8
    end
    methods
        function outObj = j2k_main_header
            % nothing to do here
        end
        function [numTiles_x, numTiles_y, use_SOP, use_PPM, use_TLM, use_PPT, use_PLT] = create(inObj, inputArgs)
            use_PPM = false;
            if strcmp(inputArgs.use_PPM, 'yes')
                use_PPM = true;
            end
            use_TLM = false;
            if strcmp(inputArgs.use_TLM, 'yes')
                use_TLM = true;
            end
            
            flag_CAP = bitand(bitshift(inputArgs.Cmodes, -6), 1);
            if isempty(inputArgs.cParam) == false
                for n = 1:length(inputArgs.cParam)
                    if isempty(inputArgs.cParam(n).Cmodes) == false
                        flag_CAP = bitor(flag_CAP,  bitand(bitshift(inputArgs.cParam(n).Cmodes, -6), 1));
                    end
                end
            end
            if isempty(inputArgs.tParam) == false
                for n = 1:length(inputArgs.tParam)
                    if isempty(inputArgs.tParam(n).Cmodes) == false
                        flag_CAP = bitor(flag_CAP,  bitand(bitshift(inputArgs.tParam(n).Cmodes, -6), 1));
                    end
                end
            end
            if isempty(inputArgs.tcParam) == false
                for n = 1:length(inputArgs.tcParam)
                    if isempty(inputArgs.tcParam(n).Cmodes) == false
                        flag_CAP = bitor(flag_CAP,  bitand(bitshift(inputArgs.tcParam(n).Cmodes, -6), 1));
                    end
                end
            end
            
            %% create parameter set for SIZ marker segment
            is_signed = zeros(1, inputArgs.numComponents);
            Ssiz = zeros(1, inputArgs.numComponents);
            XRsiz = zeros(1, inputArgs.numComponents);
            YRsiz = zeros(1, inputArgs.numComponents);
            for i = 1:inputArgs.numComponents
                is_signed(i) = false;
                Ssiz(i) = inputArgs.bitDepth-1;
                XRsiz(i) = 1; % currently, subsampling of components is not implemented.
                YRsiz(i) = 1; % currently, subsampling of components is not implemented.
            end
            % default is all origins are aligned (0,0)
            XOsiz = inputArgs.refgrid_origin(2); YOsiz = inputArgs.refgrid_origin(1);
            XTOsiz = inputArgs.tile_origin(2); YTOsiz = inputArgs.tile_origin(1);
            
            % set SIZ marker
            inObj.SIZ = SIZ_marker(...
                inputArgs.img_size_x, inputArgs.img_size_y, XOsiz, YOsiz, ...
                inputArgs.tile(2), inputArgs.tile(1), XTOsiz, YTOsiz, ...
                inputArgs.numComponents, Ssiz, XRsiz, YRsiz, ...
                is_signed, flag_CAP ...
                );
            % determine number of tiles
            numTiles_x = ceil_quotient_int((inputArgs.img_size_x - XTOsiz), inputArgs.tile(2), 'double');
            numTiles_y = ceil_quotient_int((inputArgs.img_size_y - YTOsiz), inputArgs.tile(1), 'double');
            
            %% create parameter set for COD marker segment
            % Scod
            % is_maximum_precincts; given by input argument
            use_SOP = false;
            use_EPH = false;
            if strcmp(inputArgs.use_SOP, 'yes')
                use_SOP = true;
            end
            if strcmp(inputArgs.use_EPH, 'yes')
                use_EPH = true;
            end
            % SGcod
            % Progression order, SGcod(0), uint8; given by input argument
            % Number of layers, SGcod(1), uint16; given by input argument
            % Multiple component transformation, SGcod(2), uint8
            if strcmp(inputArgs.ycc, 'yes')
                use_YCbCr_trafo = 1;
            else
                use_YCbCr_trafo = 0;
            end
            % SPCod
            % Number of decomposition levels; given by input argument
            % Code-block style; given by input argument
            % Precinct size, the highest resolution level at the first.
            if strcmp(inputArgs.use_precincts, 'no') == true
                is_maximum_precincts = true;
                PPx = 15; % dummy, just for COD_marker constructor
                PPy = 15; % dummy, just for COD_marker constructor
            else
                assert(isempty(inputArgs.precincts) == false);
                is_maximum_precincts = false;
                PPx = log2(inputArgs.precincts(:, 2));
                PPy = log2(inputArgs.precincts(:, 1));
            end
            % set COD marker
            % Transformation  0:lossy, 1: lossless
            if strcmp(inputArgs.reversible, 'yes')
                transformation = 1;
            else
                transformation = 0;
            end
            inObj.COD = COD_marker(is_maximum_precincts, use_SOP, use_EPH ...
                , inputArgs.order, inputArgs.layers, use_YCbCr_trafo ...
                , inputArgs.levels, log2(inputArgs.blk(2))-2, log2(inputArgs.blk(1))-2 ...
                , inputArgs.Cmodes, transformation, PPx, PPy);
            
            %% create parameter set for QCD marker segment
            % quantization step size is derived ?
            is_derived = false;
            % set exponent and mantissa for step size
            if transformation == 1
                % lossless
                BIBO_gain = get_BIBO_gain(inputArgs.levels, inObj.COD.get_transformation());
                exponent = zeros(1, 3*inputArgs.levels + 1, 'uint8');
                for i=1:3*inputArgs.levels+1
                    gain = BIBO_gain(i);
                    range = inputArgs.bitDepth - inputArgs.guard;
                    while gain > 0.9
                        range = range + 1;
                        gain = gain * 0.5;
                    end
                    exponent(i) = range;
                end
                exponent = exponent + use_YCbCr_trafo;
                exponent = bitshift(exponent, 3);
                % create marker
                inObj.QCD = QCD_marker(inputArgs.guard, inputArgs.levels, transformation, is_derived, exponent);
            else
                % lossy
                Wb = weight_mse(inputArgs.levels, transformation);
                exponent = zeros(1, 3*inputArgs.levels + 1, 'uint16');
                mantissa = zeros(1, 3*inputArgs.levels + 1, 'uint16');
                for i=1:length(Wb)
                    [exponent(i), mantissa(i)] = step_to_eps_mu(Wb(i), inputArgs.qstep);
                end
                inObj.QCD = QCD_marker(inputArgs.guard, inputArgs.levels, transformation, is_derived, exponent, mantissa);
            end
            
            %% create parameter set for COC marker segment
            if isempty(inputArgs.cParam) == false
                for nc = 0:inObj.SIZ.Csiz - 1
                    obj = findobj(inputArgs.cParam, 'idx', nc);
                    if isempty(obj)
                        continue;
                    end
                    
                    NL = obj.levels;
                    cobj = obj;
                    while isempty(NL)
                        p = cobj.parent;
                        NL = p.levels;
                        cobj = p;
                    end
                    
                    rev = obj.reversible;
                    cobj = obj;
                    while isempty(rev)
                        p = cobj.parent;
                        rev = p.reversible;
                        cobj = p;
                    end
                    transformation = 0;
                    if strcmp(rev, 'yes') == true
                        transformation = 1;
                    end
                    
                    Cmodes = obj.Cmodes;
                    cobj = obj;
                    while isempty(Cmodes)
                        p = cobj.parent;
                        Cmodes = p.Cmodes;
                        cobj = p;
                    end
                    
                    upre = obj.use_precincts;
                    cobj = obj;
                    while isempty(upre)
                        p = cobj.parent;
                        upre = p.use_precincts;
                        cobj = p;
                    end
                    is_maximum_precincts = 1;
                    if strcmp(upre, 'yes') == true
                        is_maximum_precincts = 0;
                    end
                    if is_maximum_precincts == 0
                        pre = obj.precincts;
                        cobj = obj;
                        while isempty(pre)
                            p = cobj.parent;
                            pre = p.precincts;
                            cobj = p;
                        end
                        PPx = log2(pre(:, 2));
                        PPy = log2(pre(:, 1));
                    else
                        PPx = 15; PPy = 15;
                    end
                    
                    cblk = obj.blk;
                    cobj = obj;
                    while isempty(cblk)
                        p = cobj.parent;
                        cblk = p.blk;
                        cobj = p;
                    end
                    blk_log2_size_x = log2(cblk(:, 2));
                    blk_log2_size_y = log2(cblk(:, 1));
                    if isempty(obj.levels) == false || isempty(obj.use_precincts)  == false || ...
                            isempty(obj.precincts)  == false || isempty(obj.reversible)  == false || ...
                            isempty(obj.blk)  == false || isempty(obj.Cmodes)  == false
                        
                        inObj.COC = [inObj.COC COC_marker(inObj.SIZ.Csiz, obj.idx, is_maximum_precincts ...
                            , NL, blk_log2_size_x - 2, blk_log2_size_y - 2 ...
                            , Cmodes, transformation, PPx, PPy)];
                    end
                end
            end
            %% create parameter set for QCC marker segment
            if isempty(inputArgs.cParam) == false
                for nc = 0:inObj.SIZ.Csiz - 1
                    obj = findobj(inputArgs.cParam, 'idx', nc);
                    if (isempty(obj) || isempty(obj.qstep) == true || isempty(obj.guard) == true) && isempty(findobj(inObj.COC, 'Ccoc', nc)) == true
                        continue;
                    end
                    
                    NL = obj.levels;
                    cobj = obj;
                    while isempty(NL)
                        p = cobj.parent;
                        NL = p.levels;
                        cobj = p;
                    end
                    
                    rev = obj.reversible;
                    cobj = obj;
                    while isempty(rev)
                        p = cobj.parent;
                        rev = p.reversible;
                        cobj = p;
                    end
                    transformation = 0;
                    if strcmp(rev, 'yes') == true
                        transformation = 1;
                    end
                    
                    nG = obj.guard;
                    cobj = obj;
                    while isempty(nG)
                        p = cobj.parent;
                        nG = p.guard;
                        cobj = p;
                    end
                    
                    qs = obj.qstep;
                    cobj = obj;
                    while isempty(qs)
                        p = cobj.parent;
                        qs = p.qstep;
                        cobj = p;
                    end
                    if isempty(obj.qstep) == false || isempty(obj.guard) == false || isempty(obj.levels) == false && obj.levels ~= inputArgs.levels || isempty(obj.reversible) == false && strcmp(obj.reversible, inputArgs.reversible)
                        % quantization step size is derived ?
                        is_derived = false;
                        
                        % set exponent and mantissa for step size
                        if transformation == 1
                            % lossless
                            BIBO_gain = get_BIBO_gain(NL, transformation);
                            exponent = zeros(1, 3*NL + 1, 'uint8');
                            for i=1:3*NL+1
                                gain = BIBO_gain(i);
                                range = inputArgs.bitDepth - nG;
                                while gain > 0.9
                                    range = range + 1;
                                    gain = gain * 0.5;
                                end
                                exponent(i) = range;
                            end
                            exponent = exponent + use_YCbCr_trafo;
                            exponent = bitshift(exponent, 3);
                            % create marker
                            inObj.QCC = [inObj.QCC QCC_marker(inObj.SIZ.Csiz, nc, nG, NL, transformation, is_derived, exponent)];
                        else
                            % lossy
                            Wb = weight_mse(NL, transformation);
                            exponent = zeros(1, 3*NL + 1, 'uint16');
                            mantissa = zeros(1, 3*NL + 1, 'uint16');
                            for i=1:length(Wb)
                                [exponent(i), mantissa(i)] = step_to_eps_mu(Wb(i), qs);
                            end
                            inObj.QCC = [inObj.QCC QCC_marker(inObj.SIZ.Csiz, nc, nG, NL, transformation, is_derived, exponent, mantissa)];
                        end
                    end
                end
            end
            
            %% prepare PPT marker segments, if necessary
            use_PPT = zeros(1, numTiles_y * numTiles_x, 'logical');
            if length(inputArgs.PPT_tiles) > numTiles_y * numTiles_x
                fprintf('WARNING: Number of elements in ''use_PPT'' parameter exceeds the number of available tiles.\n');
            end
            for i = 1:length(inputArgs.PPT_tiles)
                if inputArgs.PPT_tiles(i) >= 0
                    use_PPT(inputArgs.PPT_tiles(i)+1) = true;
                    assert(use_PPM == false, 'ERROR: PPM and PPT marker segments cannot be used together.');
                end
            end
            
            %% prepare PLT marker segments, if necessary
            use_PLT = zeros(1, numTiles_y * numTiles_x, 'logical');
            if length(inputArgs.PLT_tiles) > numTiles_y * numTiles_x
                fprintf('WARNING: Number of elements in ''use_PLT'' parameter exceeds the number of available tiles.\n');
            end
            for i = 1:length(inputArgs.PLT_tiles)
                if inputArgs.PLT_tiles(i) >= 0
                    use_PLT(inputArgs.PLT_tiles(i)+1) = true;
                end
            end
            
            %% create parameter set for CAP marker segment
            if flag_CAP == true
                Pcap = 2^(32-15);
                flag_HTONLY = true;
                flag_HTDECLARED = false;
                if bitand(bitshift(inputArgs.Cmodes, -6), 1) == false
                    flag_HTONLY = false;
                end
                if isempty(inputArgs.tParam) == false
                    for n = 1:length(inputArgs.tParam)
                        if inputArgs.tParam(n).Cmodes < 64
                            flag_HTONLY = false;
                            break;
                        end
                    end
                end
                if isempty(inputArgs.cParam) == false
                    for n = 1:length(inputArgs.cParam)
                        if inputArgs.cParam(n).Cmodes < 64
                            flag_HTONLY = false;
                            break;
                        end
                    end
                end
                if isempty(inputArgs.tcParam) == false
                    for n = 1:length(inputArgs.tcParam)
                        if inputArgs.tcParam(n).Cmodes < 64
                            flag_HTONLY = false;
                            break;
                        end
                    end
                end
                if flag_HTONLY == false
                    flag_HTDECLARED = true;
                end
                Bits14_15 = flag_HTDECLARED*2*(flag_HTONLY == false);
                Bit13 = 0; % 0:SINGLEHT, 1:MULTIHT
                Bit12 = 0; % 0:RGNFREE, 1:RGN
                HET_flag= false;
                if isempty(inputArgs.tParam) == false || isempty(inputArgs.tcParam) == false || nnz(use_PPT) ~= 0
                    HET_flag = true;
                end
                if HET_flag == false
                    Bit11 = 0; % HOMOGENEOUS or HETEROGENEOUS
                else
                    Bit11 = 1; % HOMOGENEOUS or HETEROGENEOUS
                end
                if inObj.COD.get_transformation == 1
                    Bit5 = 0; % HTREV
                else
                    Bit5 = 1; % HTIRV
                end
                Bits0_4 = 0;
                % MAGB may be renewed later
                Ccap15 = Bits14_15*2^14 + Bit13*2^13 + Bit12*2^12 + Bit11*2^11 ...
                    + Bit5*2^5 + Bits0_4;
                inObj.CAP = CAP_marker(Pcap, Ccap15);
            end
            if isempty(inputArgs.main_POC) == false
                if inputArgs.main_POC.check(inObj, inObj) == false
                    error('ERROR: Supplied progression order attributes are insuffient to cover all packets for the tile.');
                end
                inObj.POC = inputArgs.main_POC;
                n = inObj.POC.number_progression_order_change;
                if inObj.SIZ.Csiz < 257
                    inObj.POC.Lpoc = 2 + 7*n;
                else
                    inObj.POC.Lpoc = 2 + 9*n;
                end
            end
            %% create parameter set for COM marker segment
            comment = uint8('Kakadu-vxt7.10.6-Beta2');%'OsamuOsamuOsamuOsamuOs');
            if isempty(comment) == false
                inObj.COM = COM_marker(comment, 1);
            end
        end
        function write(inObj, JP2markers, hDdst, tile_Set, numTiles, use_PPM, use_TLM)
            % SIZ
            inObj.SIZ.write_SIZ(JP2markers, hDdst);
            % CAP
            if isempty(inObj.CAP) == false
                %% TODO: considering how to determine rev or irrev when only tilepart COD or COC has HT mode
                if inObj.COD.get_transformation() == 1
                    MAGB = uint16(max(inObj.QCD.get_exponent()));% lossless
                else
                    MAGB = uint16(min(inObj.QCD.get_exponent()));% lossy: not precise, the actual \mu?
                end
                if MAGB < 27
                    Bits0_4 = MAGB - 8;
                elseif MAGB <=71
                    Bits0_4 = (MAGB - 27)/4 + 19;
                else
                    Bits0_4 = 31;
                end
                inObj.CAP.Ccap = bitor(inObj.CAP.Ccap, Bits0_4);
                inObj.CAP.write_CAP(JP2markers, hDdst);
            end
            % PRF; if necessary
            % COD and COC
            inObj.COD.write_COD(JP2markers, hDdst);
            if isempty(inObj.COC) == false
                for i = 1:length(inObj.COC)
                    inObj.COC(i).write_COC(JP2markers, hDdst, inObj.SIZ.Csiz);
                end
            end
            % QCD and QCC
            inObj.QCD.write_QCD(JP2markers, hDdst);
            if isempty(inObj.QCC) == false
                for i = 1:length(inObj.QCC)
                    cObj = findobj(inObj.COC, 'Ccoc', inObj.QCC(i).Cqcc);
                    if isempty(cObj) == true
                        cObj = inObj.COD;
                    end
                    inObj.QCC(i).write_QCC(JP2markers, hDdst, inObj.SIZ.Csiz, cObj.get_number_of_decomposition_levels(), cObj.get_transformation());
                end
            end
            % POC, if necessary
            if isempty(inObj.POC) == false
                inObj.POC.write_POC(JP2markers, hDdst, inObj.SIZ.Csiz);
            end
            % COM, if necessary
            if isempty(inObj.COM) == false
                for i = 1:length(inObj.COM)
                    inObj.COM(i).write_COM(JP2markers, hDdst);
                end
            end
            
            % PPM, if necessary
            if use_PPM == true
                inObj.PPM = PPM_marker;
                inObj.PPM.write_PPM(JP2markers, hDdst, tile_Set, numTiles);
            end
            % TLM, if necessary
            if use_TLM == true
                % prepare TLM marker segment
                ST = uint16(1);
                if length(tile_Set) > 255
                    ST = uint16(2);
                end
                inObj.TLM = TLM_marker(ST, tile_Set);
                inObj.TLM.write_TLM(JP2markers, hDdst);
            end
        end % end of write
        function read_SIZ(inObj, hDsrc)
            if isempty(inObj.SIZ) == true
                inObj.SIZ = SIZ_marker;
                inObj.SIZ.read_SIZ(hDsrc);
            else
                error('ERROR: Only one SIZ marker segment per codestream is allowed.');
            end
        end
        function read_CAP(inObj, hDsrc)
            if isempty(inObj.CAP) == true
                inObj.CAP = CAP_marker;
                inObj.CAP.read_CAP(hDsrc);
                [inObj.Cap15_b14_15, inObj.Cap15_b13, inObj.Cap15_b12, inObj.Cap15_b11, inObj.Cap15_b5, inObj.Cap15_b0_4, inObj.Cap15_magb] = inObj.CAP.parse_Ccap15();
            else
                error('ERROR: Only one CAP marker segment per codestream is allowed.');
            end
        end
        function read_COD(inObj, hDsrc)
            if isempty(inObj.COD) == true
                inObj.COD = COD_marker;
                inObj.COD.read_COD(hDsrc);
            else
                error('ERROR: Only one COD marker segment in the main header is allowed.');
            end
        end
        function read_QCD(inObj, hDsrc)
            if isempty(inObj.QCD) == true
                inObj.QCD = QCD_marker;
                inObj.QCD.read_QCD(hDsrc);
            else
                error('ERROR: Only one QCD marker segment in the main header is allowed.');
            end
        end
        function read_COC(inObj, hDsrc)
            if isempty(inObj.COC) == true
                inObj.COC = COC_marker;
            else
                inObj.COC = [inObj.COC COC_marker];
            end
            inObj.COC(end).read_COC(hDsrc, inObj.SIZ.Csiz);
        end
        function read_QCC(inObj, hDsrc)
            if isempty(inObj.QCC) == true
                inObj.QCC = QCC_marker;
            else
                inObj.QCC = [inObj.QCC QCC_marker];
            end
            inObj.QCC(end).read_QCC(hDsrc, inObj.SIZ.Csiz);
        end
        function read_RGN(inObj, hDsrc)
            if isempty(inObj.RGN) == true
                inObj.RGN = RGN_marker;
            else
                inObj.RGN = [inObj.RGN RGN_marker];
            end
            inObj.RGN(end).read_RGN(hDsrc, inObj.SIZ.Csiz);
        end
        function read_POC(inObj, hDsrc)
            if isempty(inObj.POC) == true
                inObj.POC = POC_marker;
            else
                error('ERROR: Only one POC marker segment in the main header is allowed.');
            end
            inObj.POC.read_POC(hDsrc, inObj.SIZ.Csiz);
        end
        function read_PPM(inObj, hDsrc)
            if isempty(inObj.PPM) == true
                inObj.PPM = PPM_marker;
            else
                inObj.PPM = [inObj.PPM PPM_marker];
            end
            inObj.PPM(end).read_PPM(hDsrc);
        end
        function read_TLM(inObj, hDsrc)
            if isempty(inObj.TLM) == true
                inObj.TLM = TLM_marker;
            else
                inObj.TLM = [inObj.TLM TLM_marker];
            end
            inObj.TLM(end).read_TLM(hDsrc);
        end
        function read_CRG(inObj, hDsrc)
            if isempty(inObj.CRG) == true
                inObj.CRG = CRG_marker;
            else
                error('ERROR: Only one CRG marker segment in the main header is allowed.');
            end
            inObj.CRG.read_CRG(hDsrc, inObj.SIZ.Csiz);
        end
        function read_COM(inObj, hDsrc)
            if isempty(inObj.COM) == true
                inObj.COM = COM_marker;
            else
                inObj.COM = [inObj.COM COM_marker];
            end
            inObj.COM(end).read_COM(hDsrc);
            if inObj.COM(end).Rcom == 1
                fprintf('Main header comment: %s\n', inObj.COM(end).comments);
            end
        end
        function read_CPF(inObj, hDsrc)
            if isempty(inObj.CPF) == true
                inObj.CPF = CPF_marker;
            else
                error('ERROR: Only one CPF marker segment in the main header is allowed.');
            end
            inObj.CPF.read_CPF(hDsrc);
        end
        function read_PRF(inObj, hDsrc)
            if isempty(inObj.PRF) == true
                inObj.PRF = PRF_marker;
            else
                error('ERROR: Only one PRF marker segment in the main header is allowed.');
            end
            inObj.PRF.read_PRF(hDsrc, inObj.SIZ.Csiz);
        end
        function len = get_length(inObj)
            len = 2; % length of SOC
            if isempty(inObj.SIZ) == false
                len = len + 2;
                len = len + inObj.SIZ.Lsiz;
            end
            if isempty(inObj.CAP) == false
                len = len + 2;
                len = len + inObj.CAP.Lcap;
            end
            if isempty(inObj.PRF) == false
                len = len + 2;
                len = len + inObj.PRF.Lprf;
            end
            if isempty(inObj.COD) == false
                len = len + 2;
                len = len + inObj.COD.Lcod;
            end
            if isempty(inObj.QCD) == false
                len = len + 2;
                len = len + inObj.QCD.Lqcd;
            end
            if isempty(inObj.COC) == false
                for i = 1:length(inObj.COC)
                    len = len + 2;
                    len = len + inObj.COC(i).Lcoc;
                end
            end
            if isempty(inObj.QCC) == false
                for i = 1:length(inObj.QCC)
                    len = len + 2;
                    len = len + inObj.QCC(i).Lqcc;
                end
            end
            if isempty(inObj.RGN) == false
                for i = 1:length(inObj.RGN)
                    len = len + 2;
                    len = len + inObj.RGN(i).Lrgn;
                end
            end
            if isempty(inObj.PPM) == false
                for i = 1:length(inObj.PPM)
                    len = len + 2;
                    len = len + inObj.PPM(i).Lppm;
                end
            end
            if isempty(inObj.TLM) == false
                for i = 1:length(inObj.TLM)
                    len = len + 2;
                    len = len + inObj.TLM(i).Ltlm;
                end
            end
            if isempty(inObj.CRG) == false
                len = len + 2;
                len = len + inObj.CRG.Lcrg;
            end
            if isempty(inObj.COM) == false
                for i = 1:length(inObj.COM)
                    len = len + 2;
                    len = len + inObj.COM(i).Lcom;
                end
            end
            if isempty(inObj.CPF) == false
                len = len + 2;
                len = len + inObj.CPF.Lcpf;
            end
            len = uint32(len);
        end
    end
end