classdef jp2_inputArguments < handle
    properties
        img_size_x (1,1) {mustBeNonnegative, mustBeInteger}
        img_size_y (1,1) {mustBeNonnegative, mustBeInteger}
        numComponents (1,1) {mustBeNonnegative, mustBeInteger}
        bitDepth (1,1) {mustBeNonnegative, mustBeInteger, mustBeLessThan(bitDepth, 32)}
        levels (1,1) {mustBeNonnegative,  mustBeLessThanOrEqual(levels, 32)} = 5
        reversible (1,:) char {mustBeMember(reversible, {'yes', 'no'})}  = 'no'
        ycc (1,:) char {mustBeMember(ycc, {'yes', 'no'})}  = 'yes'
        rate (1,1) {mustBePositive} = 32.0
        layers (1,1) {mustBePositive, mustBeLessThanOrEqual(layers, 65535)} = 1
        blk (1,2) {mustBePositive, mustBeLessThanOrEqual(blk, 128), mustBeGreaterThanOrEqual(blk, 4)} = [64 64]
        tile (1,2) {mustBeNonnegative, mustBeInteger} = [0 0]
        use_precincts (1,:) char {mustBeMember(use_precincts, {'yes', 'no'})} = 'no'
        precincts (:,2) {mustBePositive, mustBeInteger,  mustBeLessThanOrEqual(precincts, 32768)}
        order (1,1) {mustBeNonnegative, mustBeInteger, mustBeLessThanOrEqual(order, 4)} = 0
        qstep (1,1) {mustBePositive, mustBeLessThanOrEqual(qstep, 2)} = 1/256
        guard (1,1) {mustBePositive, mustBeInteger, mustBeLessThanOrEqual(guard, 7)} = 1
        Cmodes (1,1) {mustBeNonnegative, mustBeInteger} = 64
        use_SOP (1,:) char {mustBeMember(use_SOP, {'yes', 'no'})}  = 'no'
        use_EPH (1,:) char {mustBeMember(use_EPH, {'yes', 'no'})}  = 'no'
        refgrid_origin (1,2) {mustBeNonnegative, mustBeInteger} = [0 0]
        tile_origin (1,2) {mustBeNonnegative, mustBeInteger} = [0 0]
        PPT_tiles (1,:) {mustBeInteger} = -1 % default no PPT
        PLT_tiles (1,:) {mustBeInteger} = -1 % default no PLT
        use_PPM (1,:) char {mustBeMember(use_PPM, {'yes', 'no'})}  = 'no'
        use_TLM (1,:) char {mustBeMember(use_TLM, {'yes', 'no'})}  = 'no'
        ROI (1,:) double {mustBeNonnegative}
        cParam component_parameters
        tParam tile_parameters
        tcParam tile_component_parameters
        main_POC POC_marker
    end
    methods
        function outObj = jp2_inputArguments(inputImg, FileName)
            [outObj.img_size_y, outObj.img_size_x, outObj.numComponents] = size(inputImg);
            outObj.tile = [outObj.img_size_y, outObj.img_size_x];
            origClass = class(inputImg);
            switch origClass
                case {'uint8', 'int8'}
                    outObj.bitDepth = 8;
                case {'uint16', 'int16'}
                    outObj.bitDepth = 16;
                case {'uint32', 'int32'}
                    outObj. bitDepth = 31;
                case 'single'
                    outObj.bitDepth = 31;
                case 'double'
                    error('Class %s of input image is currently not supported\n', origClass);
                otherwise
                    error('Class %s of input image is not supported\n', origClass);
            end
            if endsWith(FileName, '.jp2', 'IgnoreCase',true)
                outObj.Cmodes = 0;
            elseif endsWith(FileName, '.jph', 'IgnoreCase',true)
                outObj.Cmodes = 64;
            end
        end
        function [main_header, tilepart_header, numTiles_x, numTiles_y, use_SOP, use_PPM, use_TLM, use_PPT, use_PLT] = parse_args(inObj, argin)
            M_OFFSET = 1;
            %% parse and check input arguments
            tilepart_header = [];
            if isempty(argin) == false
                n_arg = size(argin, 2);
                assert(mod(n_arg, 2) == 0 && n_arg >= 2, 'Number of entries for coding parameters shall be even. Please check the input arguments.');
                n = 1;
                %% origin, tile, and tile-origin
                while n < n_arg
                    switch argin{n}
                        case 'tile'
                            inObj.tile = argin{n+1};
                        case 'origin'
                            inObj.refgrid_origin = argin{n+1};
                        case 'tile_origin'
                            inObj.tile_origin = argin{n+1};
                    end
                    n = n + 2;
                end
                assert(0 <= inObj.tile_origin(1) && inObj.tile_origin(1) <= inObj.refgrid_origin(1));
                assert(0 <= inObj.tile_origin(2) && inObj.tile_origin(2) <= inObj.refgrid_origin(2));
                assert(inObj.tile(1) + inObj.tile_origin(1) > inObj.refgrid_origin(1));
                assert(inObj.tile(2) + inObj.tile_origin(2) > inObj.refgrid_origin(2));
                
                numTiles = 1;
                numTiles = numTiles * ceil_quotient_int((inObj.img_size_x - inObj.tile_origin(2)), inObj.tile(2), 'double');
                numTiles = numTiles * ceil_quotient_int((inObj.img_size_y - inObj.tile_origin(1)), inObj.tile(1), 'double');
                
                for i = 0:numTiles-1
                    tilepart_header = [tilepart_header j2k_tile_part_header(i)];
                    tilepart_header(end).idx = i;
                end
                %% main header: COD, QCD, POC, PPT, PPM, TLM
                n = 1;
                while n < n_arg
                    switch argin{n}
                        case 'levels'
                            inObj.levels = argin{n+1};
                        case 'reversible'
                            inObj.reversible = argin{n+1};
                        case 'ycc'
                            inObj.ycc = argin{n+1};
                        case 'cmodes'
                            block_coding_mode = regexp(argin{n+1}, '\|', 'split');
                            modeFlag = 0;
                            if isempty(block_coding_mode) == false
                                for i = 1:length(block_coding_mode)
                                    switch block_coding_mode{i}
                                        case ''
                                            % no mode specified.
                                        case 'BYPASS'
                                            modeFlag = modeFlag + 1;
                                        case 'RESET'
                                            modeFlag = modeFlag + 2;
                                        case 'RESTART'
                                            modeFlag = modeFlag + 4;
                                        case 'CAUSAL'
                                            modeFlag = modeFlag + 8;
                                        case 'ERTERM'
                                            modeFlag = modeFlag + 16;
                                        case 'SEGMARK'
                                            modeFlag = modeFlag + 32;
                                        case 'HT'
                                            modeFlag = modeFlag + 64;
                                        otherwise
                                            error('unknown block coding mode is specified.');
                                    end
                                end
                            end
                            if bitand(bitshift(modeFlag, -6), 1) == true
                                % 183 = 10110111
                                assert(bitand(modeFlag, 183) == 0, 'When HT is present, only CAUSAL can be used together.');
                            end
                            inObj.Cmodes = modeFlag;
                        case 'rate'
                            inObj.rate = argin{n+1};
                        case 'layers'
                            inObj.layers = argin{n+1};
                        case 'blk'
                            inObj.blk = argin{n+1};
                            assert(log2(inObj.blk(1)) == floor(log2(inObj.blk(1))) && ...
                                log2(inObj.blk(2)) == floor(log2(inObj.blk(2))), 'Codeblock size shall be power of two.')
                            assert(inObj.blk(1) * inObj.blk(2) <= 4096, ...
                                'Each value in code block size [Cy Cx], Cy*Cx shall be equal to or less than 4096.');
                        case 'use_precincts'
                            inObj.use_precincts = argin{n+1};
                        case 'precincts'
                            inObj.precincts = argin{n+1};
                            inObj.use_precincts = 'yes';
                            for i = 1:size(inObj.precincts, 1)
                                assert(log2(inObj.precincts(i,1)) == floor(log2(inObj.precincts(i,1))) && ...
                                    log2(inObj.precincts(i,2)) == floor(log2(inObj.precincts(i,2))), 'Precinct size shall be power of two.')
                            end
                        case 'order'
                            Porder = argin{n+1};
                            if strcmp(Porder, 'LRCP')
                                inObj.order = 0;
                            elseif strcmp(Porder, 'RLCP')
                                inObj.order = 1;
                            elseif strcmp(Porder, 'RPCL')
                                inObj.order = 2;
                            elseif strcmp(Porder, 'PCRL')
                                inObj.order = 3;
                            elseif strcmp(Porder, 'CPRL')
                                inObj.order = 4;
                            else
                                error('Progression order shall be one of LRCP, RLCP, RPCL, PCRL, CPRL.');
                            end
                        case 'ochange'
                            Pochange = argin{n+1};
                            Porder = Pochange{6};
                            if strcmp(Porder, 'LRCP')
                                pchange_num = 0;
                            elseif strcmp(Porder, 'RLCP')
                                pchange_num = 1;
                            elseif strcmp(Porder, 'RPCL')
                                pchange_num = 2;
                            elseif strcmp(Porder, 'PCRL')
                                pchange_num = 3;
                            elseif strcmp(Porder, 'CPRL')
                                pchange_num = 4;
                            else
                                error('Progression order shall be one of LRCP, RLCP, RPCL, PCRL, CPRL.');
                            end
                            if isempty(inObj.main_POC) == true
                                inObj.main_POC = POC_marker(Pochange{1}, Pochange{2}, Pochange{3}, Pochange{4}, Pochange{5}, pchange_num);
                            else
                                inObj.main_POC.add_POC(Pochange{1}, Pochange{2}, Pochange{3}, Pochange{4}, Pochange{5}, pchange_num);
                            end
                        case 'qstep'
                            inObj.qstep = argin{n+1};
                        case 'guard'
                            inObj.guard = argin{n+1};
                        case 'use_SOP'
                            inObj.use_SOP = argin{n+1};
                        case 'use_EPH'
                            inObj.use_EPH = argin{n+1};
                        case 'use_PPT'
                            inObj.PPT_tiles = argin{n+1};
                        case 'use_PLT'
                            inObj.PLT_tiles = argin{n+1};
                        case 'use_PPM'
                            inObj.use_PPM = argin{n+1};
                        case 'use_TLM'
                            inObj.use_TLM = argin{n+1};
                        case 'ROI'
                            inObj.ROI = argin{n+1};
                            assert(length(inObj.ROI) == 4);
                            assert(isempty(inObj.ROI(inObj.ROI<0)));
                            assert(isempty(inObj.ROI(inObj.ROI>1)));
                            assert(inObj.ROI(1) + inObj.ROI(3) <= 1.0 && inObj.ROI(2) + inObj.ROI(4) <= 1.0);
                        otherwise
                            pos0 = strfind(argin{n}, ':');
                            if isempty(pos0) == false || strcmp(argin{n},'tile') || strcmp(argin{n},'origin') || strcmp(argin{n},'tile_origin')
                            else
                                error('Unknown attribute ''%s''.\n', argin{n});
                            end
                    end
                    n = n + 2;
                end
                
                %% main header: COC, QCC
                n = 1;
                while n < n_arg
                    tnum = -1;
                    cnum = -1;
                    pos0 = strfind(argin{n}, ':');
                    if isempty(pos0) == false
                        pos_t = strfind(argin{n}(1:end), 'T');
                        pos_c = strfind(argin{n}(1:end), 'C');
                        if isempty(pos_t) == false
                            n = n + 2;
                            continue;
                        else
                            assert(isempty(cnum) == false);
                            cnum = str2double(argin{n}(pos_c+1:end));
                            assert(cnum >= 0);
                            obj = findobj(inObj.cParam, 'idx', cnum);
                            if isempty(obj)
                                inObj.cParam = [inObj.cParam component_parameters(cnum)]; 
                                obj = inObj.cParam(end);
                                obj.parent = inObj;
                            end
                        end
                        pname = argin{n}(1:pos0 - 1);
                        
                        assert(tnum < numTiles);
                        assert(cnum < inObj.numComponents);
                        
                        switch pname
                            case 'levels'
                                obj.levels = argin{n+1};
                            case 'reversible'
                                obj.reversible = argin{n+1};
                            case 'cmodes'
                                block_coding_mode = regexp(argin{n+1}, '\|', 'split');
                                modeFlag = 0;
                                if isempty(block_coding_mode) == false
                                    for i = 1:length(block_coding_mode)
                                        switch block_coding_mode{i}
                                            case ''
                                                % no mode specified.
                                            case 'BYPASS'
                                                modeFlag = modeFlag + 1;
                                            case 'RESET'
                                                modeFlag = modeFlag + 2;
                                            case 'RESTART'
                                                modeFlag = modeFlag + 4;
                                            case 'CAUSAL'
                                                modeFlag = modeFlag + 8;
                                            case 'ERTERM'
                                                modeFlag = modeFlag + 16;
                                            case 'SEGMARK'
                                                modeFlag = modeFlag + 32;
                                            case 'HT'
                                                modeFlag = modeFlag + 64;
                                            otherwise
                                                error('unknown block coding mode is specified.');
                                        end
                                    end
                                end
                                if bitand(bitshift(modeFlag, -6), 1) == true
                                    % 183 = 10110111
                                    assert(bitand(modeFlag, 183) == 0, 'When HT is present, only CAUSAL can be used together.');
                                end
                                obj.Cmodes = modeFlag;
                            case 'blk'
                                tmpblk = argin{n+1};
                                assert(log2(tmpblk(1)) == floor(log2(tmpblk(1))) && ...
                                    log2(tmpblk(2)) == floor(log2(tmpblk(2))), 'Codeblock size shall be power of two.')
                                assert(tmpblk(1) * tmpblk(2) <= 4096, ...
                                    'Each value in code block size [Cy Cx], Cy*Cx shall be equal to or less than 4096.');
                                obj.blk = tmpblk;
                            case 'use_precincts'
                                obj.use_precincts = argin{n+1};
                            case 'precincts'
                                tmpprecincts = argin{n+1};
                                for i = 1:size(tmpprecincts, 1)
                                    assert(log2(tmpprecincts(i,1)) == floor(log2(tmpprecincts(i,1))) && ...
                                        log2(tmpprecincts(i,2)) == floor(log2(tmpprecincts(i,2))), 'Precinct size shall be power of two.')
                                end
                                obj.precincts = tmpprecincts;
                                obj.use_precincts = 'yes';
                            case 'qstep'
                                obj.qstep = argin{n+1};
                            case 'guard'
                                obj.guard = argin{n+1};
                            otherwise
                                error('Unknown attribute for COC or QCC ''%s''.\n', argin{n});
                        end
                    end
                    n = n + 2;
                end
 
                %% tilepart: COD, QCD, POC, PPT
                n = 1;
                while n < n_arg
                    tnum = -1;
                    cnum = -1;
                    pos0 = strfind(argin{n}, ':');
                    if isempty(pos0) == false
                        pos_t = strfind(argin{n}(1:end), 'T');
                        pos_c = strfind(argin{n}(1:end), 'C');
                        if isempty(pos_t) == false
                            if isempty(pos_c) == false
                                n = n + 2;
                                continue;
                            else
                                tnum = str2double(argin{n}(pos_t+1:end));
                                assert(tnum >= 0);
                                obj = findobj(inObj.tParam, 'idx', tnum);
                                if isempty(obj)
                                    inObj.tParam = [inObj.tParam tile_parameters(tnum)];
                                    obj = inObj.tParam(end);
                                    obj.parent = inObj.cParam;
                                    if isempty(obj.parent)
                                        obj.parent = inObj;
                                    end
                                end
                            end
                        else
                            n = n + 2;
                            continue;
                        end
                        pname = argin{n}(1:pos0 - 1);
                        
                        assert(tnum < numTiles);
                        assert(cnum < inObj.numComponents);
                        
                        switch pname
                            case 'levels'
                                obj.levels = argin{n+1};
                            case 'reversible'
                                obj.reversible = argin{n+1};
                            case 'ycc'
                                obj.ycc = argin{n+1};
                            case 'cmodes'
                                block_coding_mode = regexp(argin{n+1}, '\|', 'split');
                                modeFlag = 0;
                                if isempty(block_coding_mode) == false
                                    for i = 1:length(block_coding_mode)
                                        switch block_coding_mode{i}
                                            case ''
                                                % no mode specified.
                                            case 'BYPASS'
                                                modeFlag = modeFlag + 1;
                                            case 'RESET'
                                                modeFlag = modeFlag + 2;
                                            case 'RESTART'
                                                modeFlag = modeFlag + 4;
                                            case 'CAUSAL'
                                                modeFlag = modeFlag + 8;
                                            case 'ERTERM'
                                                modeFlag = modeFlag + 16;
                                            case 'SEGMARK'
                                                modeFlag = modeFlag + 32;
                                            case 'HT'
                                                modeFlag = modeFlag + 64;
                                            otherwise
                                                error('unknown block coding mode is specified.');
                                        end
                                    end
                                end
                                if bitand(bitshift(modeFlag, -6), 1) == true
                                    % 183 = 10110111
                                    assert(bitand(modeFlag, 183) == 0, 'When HT is present, only CAUSAL can be used together.');
                                end
                                obj.Cmodes = modeFlag;
                            case 'layers'
                                obj.layers = argin{n+1};
                            case 'blk'
                                tmpblk = argin{n+1};
                                assert(log2(tmpblk(1)) == floor(log2(tmpblk(1))) && ...
                                    log2(tmpblk(2)) == floor(log2(tmpblk(2))), 'Codeblock size shall be power of two.')
                                assert(tmpblk(1) * tmpblk(2) <= 4096, ...
                                    'Each value in code block size [Cy Cx], Cy*Cx shall be equal to or less than 4096.');
                                obj.blk = tmpblk;
                            case 'use_precincts'
                                obj.use_precincts = argin{n+1};
                            case 'precincts'
                                tmpprecincts = argin{n+1};
                                for i = 1:size(tmpprecincts, 1)
                                    assert(log2(tmpprecincts(i,1)) == floor(log2(tmpprecincts(i,1))) && ...
                                        log2(tmpprecincts(i,2)) == floor(log2(tmpprecincts(i,2))), 'Precinct size shall be power of two.')
                                end
                                obj.precincts = tmpprecincts;
                                obj.use_precincts = 'yes';
                            case 'order'
                                assert(tnum >= 0 && cnum < 0, 'Progression order is not valid for COC or tilepart COC.');
                                obj = findobj(inObj.tParam, 'idx', tnum);
                                Porder = argin{n+1};
                                if strcmp(Porder, 'LRCP')
                                    obj.order = 0;
                                elseif strcmp(Porder, 'RLCP')
                                    obj.order = 1;
                                elseif strcmp(Porder, 'RPCL')
                                    obj.order = 2;
                                elseif strcmp(Porder, 'PCRL')
                                    obj.order = 3;
                                elseif strcmp(Porder, 'CPRL')
                                    obj.order = 4;
                                else
                                    error('Progression order shall be one of LRCP, RLCP, RPCL, PCRL, CPRL.');
                                end
                            case 'ochange'
                                Pochange = argin{n+1};
                                Porder = Pochange{6};
                                if strcmp(Porder, 'LRCP')
                                    pchange_num = 0;
                                elseif strcmp(Porder, 'RLCP')
                                    pchange_num = 1;
                                elseif strcmp(Porder, 'RPCL')
                                    pchange_num = 2;
                                elseif strcmp(Porder, 'PCRL')
                                    pchange_num = 3;
                                elseif strcmp(Porder, 'CPRL')
                                    pchange_num = 4;
                                else
                                    error('Progression order shall be one of LRCP, RLCP, RPCL, PCRL, CPRL.');
                                end
                                if isempty(obj.tilepart_POC) == true
                                   obj.tilepart_POC = POC_marker(Pochange{1}, Pochange{2}, Pochange{3}, Pochange{4}, Pochange{5}, pchange_num);
                                else
                                    obj.tilepart_POC.add_POC(Pochange{1}, Pochange{2}, Pochange{3}, Pochange{4}, Pochange{5}, pchange_num);
                                end
                            case 'qstep'
                                obj.qstep = argin{n+1};
                            case 'guard'
                                obj.guard = argin{n+1};
                            case 'use_SOP'
                                assert(tnum >= 0 && cnum < 0, 'use_SOP is not valid for COC or tilepart COC.');
                                obj = findobj(inObj.tParam, 'idx', tnum);
                                obj.use_SOP = argin{n+1};
                            case 'use_EPH'
                                assert(tnum >= 0 && cnum < 0, 'use_EPH is not valid for COC or tilepart COC.');
                                obj = findobj(inObj.tParam, 'idx', tnum);
                                obj.use_EPH = argin{n+1};
                            otherwise
                                error('Unknown attribute ''%s''.\n', argin{n});
                        end
                    end
                    n = n + 2;
                end
                
                %% tilepart: COC, QCC
                n = 1;
                while n < n_arg
                    tnum = -1;
                    cnum = -1;
                    pos0 = strfind(argin{n}, ':');
                    
                    if isempty(pos0) == false
                        pos_t = strfind(argin{n}(1:end), 'T');
                        pos_c = strfind(argin{n}(1:end), 'C');
                        if isempty(pos_t) == false
                            if isempty(pos_c) == false
                                tnum = str2double(argin{n}(pos_t+1:pos_c-1));
                                cnum = str2double(argin{n}(pos_c+1:end));
                                assert(cnum >= 0 && tnum >= 0);
                                obj = findobj(inObj.tcParam, 'idx_t', tnum, '-and', 'idx_c', cnum);
                                if isempty(obj)
                                    inObj.tcParam = [inObj.tcParam tile_component_parameters(tnum, cnum)];
                                    obj = inObj.tcParam(end);
                                    obj.parent = findobj(inObj.tParam, 'idx', tnum);
                                    if isempty(obj.parent)
                                        obj.parent = inObj.cParam;
                                    end
                                    if isempty(obj.parent)
                                        obj.parent = inObj;
                                    end
                                end
                            else
                                n = n + 2;
                                continue;
                            end
                        else
                            n = n + 2;
                            continue;
                        end
                        pname = argin{n}(1:pos0 - 1);
                        
                        assert(tnum < numTiles);
                        assert(cnum < inObj.numComponents);
                        
                        switch pname
                            case 'levels'
                                obj.levels = argin{n+1};
                                assert(obj.levels <= inObj.levels, 'Number of decomposition levels in any COC shall be equal to or less than main COD value.');
                            case 'reversible'
                                obj.reversible = argin{n+1};
                            case 'cmodes'
                                block_coding_mode = regexp(argin{n+1}, '\|', 'split');
                                modeFlag = 0;
                                if isempty(block_coding_mode) == false
                                    for i = 1:length(block_coding_mode)
                                        switch block_coding_mode{i}
                                            case ''
                                                % no mode specified.
                                            case 'BYPASS'
                                                modeFlag = modeFlag + 1;
                                            case 'RESET'
                                                modeFlag = modeFlag + 2;
                                            case 'RESTART'
                                                modeFlag = modeFlag + 4;
                                            case 'CAUSAL'
                                                modeFlag = modeFlag + 8;
                                            case 'ERTERM'
                                                modeFlag = modeFlag + 16;
                                            case 'SEGMARK'
                                                modeFlag = modeFlag + 32;
                                            case 'HT'
                                                modeFlag = modeFlag + 64;
                                            otherwise
                                                error('unknown block coding mode is specified.');
                                        end
                                    end
                                end
                                if bitand(bitshift(modeFlag, -6), 1) == true
                                    % 183 = 10110111
                                    assert(bitand(modeFlag, 183) == 0, 'When HT is present, only CAUSAL can be used together.');
                                end
                                obj.Cmodes = modeFlag;
                            case 'blk'
                                tmpblk = argin{n+1};
                                assert(log2(tmpblk(1)) == floor(log2(tmpblk(1))) && ...
                                    log2(tmpblk(2)) == floor(log2(tmpblk(2))), 'Codeblock size shall be power of two.')
                                assert(tmpblk(1) * tmpblk(2) <= 4096, ...
                                    'Each value in code block size [Cy Cx], Cy*Cx shall be equal to or less than 4096.');
                                obj.blk = tmpblk;
                            case 'use_precincts'
                                obj.use_precincts = argin{n+1};
                            case 'precincts'
                                tmpprecincts = argin{n+1};
                                for i = 1:size(tmpprecincts, 1)
                                    assert(log2(tmpprecincts(i,1)) == floor(log2(tmpprecincts(i,1))) && ...
                                        log2(tmpprecincts(i,2)) == floor(log2(tmpprecincts(i,2))), 'Precinct size shall be power of two.')
                                end
                                obj.precincts = tmpprecincts;
                                obj.use_precincts = 'yes';
                            case 'qstep'
                                obj.qstep = argin{n+1};
                            case 'guard'
                                obj.guard = argin{n+1};
                            otherwise
                                error('Unknown attribute ''%s'' for tilepart components.\n', argin{n});
                        end
                    end
                    n = n + 2;
                end
            end
            
            if inObj.numComponents < 3
                inObj.ycc = 'no';
            end
            main_header = j2k_main_header;
            [numTiles_x, numTiles_y, use_SOP, use_PPM, use_TLM, use_PPT, use_PLT] = main_header.create(inObj);
            for i = 0:length(tilepart_header) - 1
                tilepart_header(i + M_OFFSET).create_COD(inObj);
                tilepart_header(i + M_OFFSET).create_QCD(inObj);
                tilepart_header(i + M_OFFSET).create_COC(inObj, i, inObj.numComponents, main_header);
                tilepart_header(i + M_OFFSET).create_QCC(inObj, i, inObj.numComponents, main_header);
                tilepart_header(i + M_OFFSET).create_POC(inObj, main_header);
            end
        end
    end
end