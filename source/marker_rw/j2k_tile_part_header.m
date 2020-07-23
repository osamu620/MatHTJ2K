classdef j2k_tile_part_header < handle
    properties
        idx int32
        SOT SOT_marker
        COD COD_marker
        COC COC_marker
        RGN RGN_marker
        QCD QCD_marker
        QCC QCC_marker
        POC POC_marker
        COM COM_marker
        PPT PPT_marker
        PLT PLT_marker
        is_empty logical
    end
    methods
        function outObj = j2k_tile_part_header(tile_index)
            if nargin ~= 0
                outObj.SOT = SOT_marker;
                outObj.SOT.Lsot = 10;
                outObj.SOT.Isot = tile_index;
                outObj.SOT.TPsot = 0;
                outObj.SOT.TNsot = 1;
                outObj.SOT.Psot = 0; % tile-length will be calculated later.
                outObj.is_empty = false;
            end
            outObj.is_empty = true;
        end
        function set_length(inObj, tileLength)
            inObj.SOT.Psot = tileLength + 14; % 2(SOT) + 10(Lsot)  + 2(SOD)
            if isempty(inObj.COD) == false
                inObj.SOT.Psot = inObj.SOT.Psot + uint32(inObj.COD.Lcod) + 2;
            end
            if isempty(inObj.QCD) == false
                inObj.SOT.Psot = inObj.SOT.Psot + uint32(inObj.QCD.Lqcd) + 2;
            end
            if isempty(inObj.RGN) == false
                for i = 1:length(inObj.RGN)
                    inObj.SOT.Psot = inObj.SOT.Psot + uint32(inObj.RGN(i).Lrgn) + 2;
                end
            end
            if isempty(inObj.COC) == false
                for i = 1:length(inObj.COC)
                    inObj.SOT.Psot = inObj.SOT.Psot + uint32(inObj.COC(i).Lcoc) + 2;
                end
            end
            if isempty(inObj.QCC) == false
                for i = 1:length(inObj.QCC)
                    inObj.SOT.Psot = inObj.SOT.Psot + uint32(inObj.QCC(i).Lqcc) + 2;
                end
            end
            if isempty(inObj.POC) == false
                for i = 1:length(inObj.POC)
                    inObj.SOT.Psot = inObj.SOT.Psot + uint32(inObj.POC(i).Lpoc) + 2;
                end
            end
            if isempty(inObj.COM) == false
                for i = 1:length(inObj.COM)
                    inObj.SOT.Psot = inObj.SOT.Psot + uint32(inObj.COM(i).Lcom) + 2;
                end
            end
            if isempty(inObj.PPT) == false
                for i = 1:length(inObj.PPT)
                    inObj.SOT.Psot = inObj.SOT.Psot + uint32(inObj.PPT(i).Lppt) + 2;
                end
            end
            if isempty(inObj.PLT) == false
                for i = 1:length(inObj.PLT)
                    inObj.SOT.Psot = inObj.SOT.Psot + uint32(inObj.PLT(i).Lplt) + 2;
                end
            end
        end

        %% COD
        function create_COD(inObj, inputArgs)
            obj = findobj(inputArgs.tParam, 'idx', inObj.idx);
            if isempty(obj) == true
                return;
            end

            %% create parameter set for COD marker segment

            uSOP = obj.use_SOP;
            cobj = obj;
            while isempty(uSOP)
                p = cobj.parent;
                if isa(p, 'component_parameters')
                    p = p.parent;
                end
                uSOP = p.use_SOP;
                cobj = p;
            end
            use_SOP = false;
            if strcmp(uSOP, 'yes')
                use_SOP = true;
            end

            uEPH = obj.use_EPH;
            cobj = obj;
            while isempty(uEPH)
                p = cobj.parent;
                if isa(p, 'component_parameters')
                    p = p.parent;
                end
                uEPH = p.use_EPH;
                cobj = p;
            end
            use_EPH = false;
            if strcmp(uEPH, 'yes')
                use_EPH = true;
            end

            ycc = obj.ycc;
            cobj = obj;
            while isempty(ycc)
                p = cobj.parent;
                if isa(p, 'component_parameters')
                    p = p.parent;
                end
                ycc = p.ycc;
                cobj = p;
            end
            use_YCbCr_trafo = 0;
            if strcmp(ycc, 'yes')
                use_YCbCr_trafo = 1;
            end

            nlayers = obj.layers;
            cobj = obj;
            while isempty(nlayers)
                p = cobj.parent;
                if isa(p, 'component_parameters')
                    p = p.parent;
                end
                nlayers = p.layers;
                cobj = p;
            end

            norder = obj.order;
            cobj = obj;
            while isempty(norder)
                p = cobj.parent;
                if isa(p, 'component_parameters')
                    p = p.parent;
                end
                norder = p.order;
                cobj = p;
            end

            NL = obj.levels;
            cobj = obj;
            while isempty(NL)
                p = cobj.parent;
                if isa(p, 'component_parameters')
                    p = p.parent;
                end
                NL = p.levels;
                cobj = p;
            end

            rev = obj.reversible;
            cobj = obj;
            while isempty(rev)
                p = cobj.parent;
                if isa(p, 'component_parameters')
                    p = p.parent;
                end
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
                if isa(p, 'component_parameters')
                    p = p.parent;
                end
                Cmodes = p.Cmodes;
                cobj = p;
            end

            upre = obj.use_precincts;
            cobj = obj;
            while isempty(upre)
                p = cobj.parent;
                if isa(p, 'component_parameters')
                    p = p.parent;
                end
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
                    if isa(p, 'component_parameters')
                        p = p.parent;
                    end
                    pre = p.precincts;
                    cobj = p;
                end
                PPx = log2(pre(:, 2));
                PPy = log2(pre(:, 1));
            else
                PPx = 15;
                PPy = 15;
            end

            cblk = obj.blk;
            cobj = obj;
            while isempty(cblk)
                p = cobj.parent;
                if isa(p, 'component_parameters')
                    p = p.parent;
                end
                cblk = p.blk;
                cobj = p;
            end
            blk_log2_size_x = log2(cblk(:, 2));
            blk_log2_size_y = log2(cblk(:, 1));

            pobj = inputArgs;

            cond = (isempty(obj.layers) == false && obj.layers ~= pobj.layers) || ...
                (isempty(obj.order) == false && obj.order ~= pobj.order) || ...
                (isempty(obj.ycc) == false && strcmp(obj.ycc, pobj.ycc) == false) || ...
                (isempty(obj.use_SOP) == false && strcmp(obj.use_SOP, pobj.use_SOP) == false) || ...
                (isempty(obj.use_EPH) == false && strcmp(obj.use_EPH, pobj.use_EPH) == false) || ...
                (isempty(obj.use_precincts) == false && strcmp(obj.use_precincts, pobj.use_precincts) == false) || ...
                (isempty(obj.reversible) == false && strcmp(obj.reversible, pobj.reversible) == false) || ...
                (isempty(obj.levels) == false && obj.levels ~= pobj.levels) || ...
                (isempty(obj.Cmodes) == false && obj.Cmodes ~= pobj.Cmodes) || ...
                (isempty(obj.precincts) == false && isequal(obj.precincts, pobj.precincts) == false) || ...
                (isempty(obj.blk) == false && isequal(obj.blk, pobj.blk) == false);
            if cond
                inObj.COD = COD_marker(is_maximum_precincts, use_SOP, use_EPH ...
                    , norder, nlayers, use_YCbCr_trafo ...
                    , NL, blk_log2_size_x - 2, blk_log2_size_y - 2 ...
                    , Cmodes, transformation, PPx, PPy);
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

        %% QCD
        function create_QCD(inObj, inputArgs)
            obj = findobj(inputArgs.tParam, 'idx', inObj.idx);
            if isempty(obj) == false && (isempty(obj.qstep) == false || isempty(obj.guard) == false)

                %% create parameter set for QCD marker segment
                % quantization step size is derived ?
                is_derived = false;
                if isempty(obj.levels)
                    NL = inputArgs.levels;
                else
                    NL = obj.levels;
                end

                if isempty(obj.reversible)
                    tObj = inputArgs;
                else
                    tObj = obj;
                end
                if strcmp(tObj.reversible, 'yes')
                    transformation = 1;
                else
                    transformation = 0;
                end
                if isempty(obj.ycc)
                    tObj = inputArgs;
                else
                    tObj = obj;
                end
                if strcmp(tObj.ycc, 'yes')
                    use_YCbCr_trafo = 1;
                else
                    use_YCbCr_trafo = 0;
                end

                if isempty(obj.guard)
                    nG = inputArgs.guard;
                else
                    nG = obj.guard;
                end

                if isempty(obj.qstep)
                    qs = inputArgs.qstep;
                else
                    qs = obj.qstep;
                end
                % set exponent and mantissa for step size
                if transformation == 1
                    % lossless
                    BIBO_gain = get_BIBO_gain(NL, transformation);
                    exponent = zeros(1, 3 * NL + 1, 'uint8');
                    for i = 1:3 * NL + 1
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
                    % set QCD marker
                    inObj.QCD = QCD_marker(nG, NL, transformation, is_derived, exponent);
                else
                    % lossy
                    Wb = weight_mse(NL, transformation);
                    exponent = zeros(1, 3 * NL + 1, 'uint16');
                    mantissa = zeros(1, 3 * NL + 1, 'uint16');
                    for i = 1:length(Wb)
                        [exponent(i), mantissa(i)] = step_to_eps_mu(Wb(i), qs);
                    end
                    % set QCD marker
                    inObj.QCD = QCD_marker(nG, NL, transformation, is_derived, exponent, mantissa);
                end
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

        %% COC
        function create_COC(inObj, inputArgs, t, Csiz, main_header)
            for nc = 0:Csiz - 1
                obj = findobj(inputArgs.tcParam, 'idx_t', t, '-and', 'idx_c', nc);
                if isempty(obj)
                    obj = findobj(inputArgs.tParam, 'idx', t);
                    if isempty(obj)
                        obj = findobj(inputArgs.cParam, 'idx', nc);
                    end
                end
                if isempty(obj)
                    continue;
                end
                % DWT levels
                NL = obj.levels;
                cobj = obj;
                while isempty(NL)
                    if isa(cobj.parent, 'component_parameters') == true
                        p = findobj(cobj.parent, 'idx', nc);
                        if isempty(p)
                            p = inputArgs;
                        end
                    else
                        p = cobj.parent;
                    end
                    NL = p.levels;
                    cobj = p;
                end
                % codeblock style
                Cmodes = obj.Cmodes;
                cobj = obj;
                while isempty(Cmodes)
                    if isa(cobj.parent, 'component_parameters') == true
                        p = findobj(cobj.parent, 'idx', nc);
                        if isempty(p)
                            p = inputArgs;
                        end
                    else
                        p = cobj.parent;
                    end
                    Cmodes = p.Cmodes;
                    cobj = p;
                end

                % transformation
                rev = obj.reversible;
                cobj = obj;
                while isempty(rev)
                    if isa(cobj.parent, 'component_parameters') == true
                        p = findobj(cobj.parent, 'idx', nc);
                        if isempty(p)
                            p = inputArgs;
                        end
                    else
                        p = cobj.parent;
                    end
                    rev = p.reversible;
                    cobj = p;
                end
                transformation = 0;
                if strcmp(rev, 'yes') == true
                    transformation = 1;
                end

                % precincts
                upre = obj.use_precincts;
                cobj = obj;
                while isempty(upre)
                    if isa(cobj.parent, 'component_parameters') == true
                        p = findobj(cobj.parent, 'idx', nc);
                        if isempty(p)
                            p = inputArgs;
                        end
                    else
                        p = cobj.parent;
                    end
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
                        if isa(cobj.parent, 'component_parameters') == true
                            p = findobj(cobj.parent, 'idx', nc);
                            if isempty(p)
                                p = inputArgs;
                            end
                        else
                            p = cobj.parent;
                        end
                        pre = p.precincts;
                        cobj = p;
                    end
                    PPx = log2(pre(:, 2));
                    PPy = log2(pre(:, 1));
                else
                    PPx = 15;
                    PPy = 15;
                end

                % codeblock size
                cblk = obj.blk;
                cobj = obj;
                while isempty(cblk)
                    if isa(cobj.parent, 'component_parameters') == true
                        p = findobj(cobj.parent, 'idx', nc);
                        if isempty(p)
                            p = inputArgs;
                        end
                    else
                        p = cobj.parent;
                    end
                    cblk = p.blk;
                    cobj = p;
                end
                blk_log2_size_x = log2(cblk(:, 2));
                blk_log2_size_y = log2(cblk(:, 1));


                % set COC marker
                tmpCOC = COC_marker(Csiz, nc, is_maximum_precincts, NL, ...
                    blk_log2_size_x - 2, blk_log2_size_y - 2, Cmodes, transformation, PPx, PPy);
                pobj = findobj(inObj.COD);
                if isempty(pobj) == false
                    if pobj.get_number_of_decomposition_levels() ~= NL || ...
                            pobj.get_transformation() ~= transformation || ...
                            isequal(pobj.get_codeblock_size_in_exponent(), log2(cblk)) == false || ...
                            pobj.get_codeblock_style() ~= Cmodes || ...
                            pobj.is_maximum_precincts() ~= is_maximum_precincts && isequal(pobj.get_precinct_size_in_exponent(), [PPy, PPx]) == false
                        inObj.COC = [inObj.COC, tmpCOC];
                    end
                else
                    pobj = findobj(main_header.COC, 'Ccoc', nc);
                    if isempty(pobj) == false
                        if isequal(pobj, tmpCOC) == false
                            inObj.COC = [inObj.COC, tmpCOC];
                        end
                    else
                        pobj = findobj(main_header.COD);
                        if pobj.get_number_of_decomposition_levels() ~= NL || ...
                                pobj.get_transformation() ~= transformation || ...
                                isequal(pobj.get_codeblock_size_in_exponent(), log2(cblk)) == false || ...
                                pobj.get_codeblock_style() ~= Cmodes || ...
                                pobj.is_maximum_precincts() ~= is_maximum_precincts && isequal(pobj.get_precinct_size_in_exponent(), [PPy, PPx]) == false
                            inObj.COC = [inObj.COC, tmpCOC];
                        end
                    end
                end
            end

        end

        %% QCC
        function create_QCC(inObj, inputArgs, t, Csiz, main_header)
            for nc = 0:Csiz - 1
                obj = findobj(inputArgs.tcParam, 'idx_t', t, '-and', 'idx_c', nc);
                if isempty(obj)
                    obj = findobj(inputArgs.tParam, 'idx', t);
                    if isempty(obj)
                        obj = findobj(inputArgs.cParam, 'idx', nc);
                    end
                end
                if isempty(obj)
                    continue;
                end

                NL = obj.levels;
                cobj = obj;
                while isempty(NL)
                    if isa(cobj.parent, 'component_parameters') == true
                        p = findobj(cobj.parent, 'idx', nc);
                        if isempty(p)
                            p = inputArgs;
                        end
                    else
                        p = cobj.parent;
                    end
                    NL = p.levels;
                    cobj = p;
                end

                rev = obj.reversible;
                cobj = obj;
                while isempty(rev)
                    if isa(cobj.parent, 'component_parameters') == true
                        p = findobj(cobj.parent, 'idx', nc);
                        if isempty(p)
                            p = inputArgs;
                        end
                    else
                        p = cobj.parent;
                    end
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
                    if isa(cobj.parent, 'component_parameters') == true
                        p = findobj(cobj.parent, 'idx', nc);
                        if isempty(p)
                            p = inputArgs;
                        end
                    else
                        p = cobj.parent;
                    end
                    nG = p.guard;
                    cobj = p;
                end

                qs = obj.qstep;
                cobj = obj;
                while isempty(qs)
                    if isa(cobj.parent, 'component_parameters') == true
                        p = findobj(cobj.parent, 'idx', nc);
                        if isempty(p)
                            p = inputArgs;
                        end
                    else
                        p = cobj.parent;
                    end
                    qs = p.qstep;
                    cobj = p;
                end

                pobj = findobj(inputArgs.tParam, 'idx', t);
                if isempty(pobj) == false
                    ycc = pobj.ycc;
                    cobj = pobj;
                    while isempty(ycc)
                        p = cobj.parent;
                        if isa(p, 'jp2_inputArguments') %|| isa(p, 'tile_parameters')
                            ycc = p.ycc;
                        end
                        cobj = p;
                    end
                else
                    ycc = inputArgs.ycc;
                end
                use_YCbCr_trafo = 0;
                if strcmp(ycc, 'yes') == true
                    use_YCbCr_trafo = 1;
                end

                %% create parameter set for QCC marker segment
                % quantization step size is derived ?
                is_derived = false;

                % set exponent and mantissa for step size
                if transformation == 1
                    % lossless
                    BIBO_gain = get_BIBO_gain(NL, transformation);
                    exponent = zeros(1, 3 * NL + 1, 'uint8');
                    for i = 1:3 * NL + 1
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
                    % set QCC marker
                    tmpQCC = QCC_marker(Csiz, nc, nG, NL, transformation, is_derived, exponent);
                else
                    % lossy
                    Wb = weight_mse(NL, transformation);
                    exponent = zeros(1, 3 * NL + 1, 'uint16');
                    mantissa = zeros(1, 3 * NL + 1, 'uint16');
                    for i = 1:length(Wb)
                        [exponent(i), mantissa(i)] = step_to_eps_mu(Wb(i), qs);
                    end
                    % set QCC marker
                    tmpQCC = QCC_marker(Csiz, nc, nG, NL, transformation, is_derived, exponent, mantissa);
                end
                pobj = inObj.QCD;
                if isempty(pobj) == false
                    if isequal(pobj.Sqcd, tmpQCC.Sqcc) == false || isequal(pobj.SPqcd, tmpQCC.SPqcc) == false
                        inObj.QCC = [inObj.QCC, tmpQCC];
                    end
                else
                    pobj = findobj(main_header.QCC, 'Cqcc', nc);
                    if isempty(pobj) == false
                        if isequal(pobj, tmpQCC) == false
                            inObj.QCC = [inObj.QCC, tmpQCC];
                        end
                    else
                        pobj = findobj(main_header.QCD);
                        if isequal(pobj.Sqcd, tmpQCC.Sqcc) == false || isequal(pobj.SPqcd, tmpQCC.SPqcc) == false
                            inObj.QCC = [inObj.QCC, tmpQCC];
                        end
                    end
                end
            end
        end
        function create_POC(inObj, inputArgs, main_header)
            obj = findobj(inputArgs.tParam, 'idx', inObj.idx);
            if isempty(obj) == true || isempty(obj.tilepart_POC) == true
                return;
            end

            if obj.tilepart_POC.check(inObj, main_header) == false
                error('ERROR: Supplied progression order attributes are insuffient to cover all packets for the tile.');
            end
            inObj.POC = obj.tilepart_POC;
            n = inObj.POC.number_progression_order_change;
            if main_header.SIZ.Csiz < 257
                inObj.POC.Lpoc = 2 + 7 * n;
            else
                inObj.POC.Lpoc = 2 + 9 * n;
            end
        end
        function read_COC(inObj, hDsrc, Csiz)
            if isempty(inObj.COC) == true
                inObj.COC = COC_marker;
            else
                inObj.COC = [inObj.COC, COC_marker];
            end
            inObj.COC(end).read_COC(hDsrc, Csiz);
        end
        function read_QCC(inObj, hDsrc, Csiz)
            if isempty(inObj.QCC) == true
                inObj.QCC = QCC_marker;
            else
                inObj.QCC = [inObj.QCC, QCC_marker];
            end
            inObj.QCC(end).read_QCC(hDsrc, Csiz);
        end
        function read_RGN(inObj, hDsrc, Csiz)
            if isempty(inObj.RGN) == true
                inObj.RGN = RGN_marker;
            else
                inObj.RGN = [inObj.RGN, RGN_marker];
            end
            inObj.RGN(end).read_RGN(hDsrc, Csiz);
        end
        function read_POC(inObj, hDsrc, Csiz)
            if isempty(inObj.POC) == true
                inObj.POC = POC_marker();
                inObj.POC.read_POC(hDsrc, Csiz);
            else
                fprintf('WARNING: More than one POC marker segment are found in a tilepart header.\n');
                fprintf('However, the last POC marker will be skipped because at most only one POC marker segment may appear in any header.\n');
                tmp = POC_marker();
                tmp.read_POC(hDsrc, Csiz);
            end
        end
        function read_COM(inObj, hDsrc)
            if isempty(inObj.COM) == true
                inObj.COM = COM_marker;
            else
                inObj.COM = [inObj.COM, COM_marker];
            end
            inObj.COM(end).read_COM(hDsrc);
            if inObj.COM(end).Rcom == 1
                fprintf('Tile-part comment: %s\n', inObj.COM(end).comments);
            end
        end
        function read_PPT(inObj, hDsrc)
            if isempty(inObj.PPT) == true
                inObj.PPT = PPT_marker;
            else
                inObj.PPT = [inObj.PPT, PPT_marker];
            end
            inObj.PPT(end).read_PPT(hDsrc);
        end
        function read_PLT(inObj, hDsrc)
            if isempty(inObj.PLT) == true
                inObj.PLT = PLT_marker;
            else
                inObj.PLT = [inObj.PLT, PLT_marker];
            end
            inObj.PLT(end).read_PLT(hDsrc);
        end
        function set_PPT(inObj, hTile)
            inObj.PPT = PPT_marker;
            inObj.PPT.create_PPT(hTile);
        end
        function set_PLT(inObj, hTile)
            inObj.PLT = PLT_marker;
            inObj.PLT.make_PLT(hTile);
        end
        function write(inObj, m, hDdst, main_header)
            inObj.SOT.write_SOT(m, hDdst);
            if isempty(inObj.COD) == false
                inObj.COD.write_COD(m, hDdst);
            end
            if isempty(inObj.COC) == false
                for i = 1:length(inObj.COC)
                    inObj.COC(i).write_COC(m, hDdst, main_header.SIZ.Csiz);
                end
            end
            if isempty(inObj.QCD) == false
                inObj.QCD.write_QCD(m, hDdst);
            end
            if isempty(inObj.QCC) == false
                for i = 1:length(inObj.QCC)
                    if isempty(findobj(inObj.COC, 'Ccoc', inObj.QCC(i).Cqcc)) == false
                        cObj = findobj(inObj.COC, 'Ccoc', inObj.QCC(i).Cqcc);
                    elseif isempty(findobj(inObj.COD)) == false
                        cObj = inObj.COD;
                    elseif isempty(findobj(main_header.COC, 'Ccoc', inObj.QCC(i).Cqcc)) == false
                        cObj = findobj(main_header.COC, 'Ccoc', inObj.QCC(i).Cqcc);
                    else
                        cObj = main_header.COD;
                    end
                    inObj.QCC(i).write_QCC(m, hDdst, main_header.SIZ.Csiz, cObj.get_number_of_decomposition_levels(), cObj.get_transformation());
                end
            end
            if isempty(inObj.POC) == false
                inObj.POC.write_POC(m, hDdst, main_header.SIZ.Csiz);
            end
            if isempty(inObj.PPT) == false
                for i = 1:length(inObj.PPT)
                    inObj.PPT(i).write_PPT(m, hDdst);
                end
            end
            if isempty(inObj.PLT) == false
                inObj.PLT.write_PLT(m, hDdst);
            end
            % SOD
            put_word(hDdst, m.SOD);
        end
    end
end