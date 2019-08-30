classdef POC_marker < handle
    properties
        Lpoc   (1,1) uint16
        RSpoc  (1,:) uint8
        CSpoc  (1,:) uint16
        LYEpoc (1,:) uint16
        REpoc  (1,:) uint8
        CEpoc  (1,:) uint16
        Ppoc   (1,:) uint8
        number_progression_order_change (1,1) uint16
    end
    methods
        function outObj = POC_marker(RS, CS, LYE, RE, CE, P)
            if nargin == 0
                outObj.number_progression_order_change = 1;
            else
                outObj.number_progression_order_change = 1;
                n = outObj.number_progression_order_change;
                outObj.RSpoc(n) = RS;
                outObj.CSpoc(n) = CS;
                outObj.LYEpoc(n) = LYE;
                outObj.REpoc(n) = RE;
                outObj.CEpoc(n) = CE;
                outObj.Ppoc(n) = P;
            end
        end
        function add_POC(inObj, RS, CS, LYE, RE, CE, P)
            inObj.number_progression_order_change = inObj.number_progression_order_change + 1;
            n = inObj.number_progression_order_change;
            inObj.RSpoc(n) = RS;
            inObj.CSpoc(n) = CS;
            inObj.LYEpoc(n) = LYE;
            inObj.REpoc(n) = RE;
            inObj.CEpoc(n) = CE;
            inObj.Ppoc(n) = P;
        end
        function out = check(inObj, header, main_header)
            Csiz = main_header.SIZ.Csiz;
            if isempty(header.COD) == false
                NL = header.COD.get_number_of_decomposition_levels();
            else
                NL = main_header.COD.get_number_of_decomposition_levels();
            end
            max_NL = NL;
            for c = 0:Csiz - 1
                obj = findobj(header.COC, 'Ccoc', c);
                if isempty(obj) == false
                    max_NL = max(max_NL, obj.get_number_of_decomposition_levels());
                else
                    obj = findobj(main_header.COC, 'Ccoc', c);
                    if isempty(obj) == false
                        max_NL = max(max_NL, obj.get_number_of_decomposition_levels());
                    end
                end
            end
            if isempty(header.COD) == false
                nlayers = header.COD.get_number_of_layers();
            else
                nlayers = main_header.COD.get_number_of_layers();
            end
            
            pSpace = ones(max_NL+1, Csiz, nlayers); 
            for c = 0:Csiz - 1
                obj = findobj(header.COC, 'Ccoc', c);
                if isempty(obj) == true
                    obj = findobj(main_header.COC, 'Ccoc', c);
                    if isempty(obj) == true
                        c_NL = NL;
                        if c_NL < max_NL
                            pSpace(end-(max_NL-c_NL)+1, c+1, :) = 0;
                        end
                    end
                end
            end
            
            for n = 1:inObj.number_progression_order_change
                pSpace(inObj.RSpoc(n)+1:inObj.REpoc(n), ...
                    inObj.CSpoc(n)+1:inObj.CEpoc(n), ...
                    1:inObj.LYEpoc(n)) = 0;
            end
            out = true;
            if nnz(pSpace) ~= 0
                out = false;
            end
        end
        function write_POC(inObj, m, hDdst, Csiz)
            assert(isa(hDdst,'jp2_data_destination'));
            assert(isa(inObj,'POC_marker'), 'input for write_POC() shall be POC_marker class.');
            hDdst.put_word(m.POC);
            n = inObj.number_progression_order_change;
            if Csiz < 257
                inObj.Lpoc = 2 + 7*n;
            else
                inObj.Lpoc = 2 + 9*n;
            end
            hDdst.put_word(inObj.Lpoc);
            for i = 1:n
                hDdst.put_byte(inObj.RSpoc(i));
                if Csiz < 257
                    hDdst.put_byte(inObj.CSpoc(i));
                else
                    hDdst.put_word(inObj.CSpoc(i));
                end
                hDdst.put_word(inObj.LYEpoc(i));
                hDdst.put_byte(inObj.REpoc(i));
                if Csiz < 257
                    hDdst.put_byte(inObj.CEpoc(i));
                else
                    hDdst.put_word(inObj.CEpoc(i));
                end
                hDdst.put_byte(inObj.Ppoc(i));
            end
        end
        function read_POC(inObj, hDsrc, Csiz)
            assert(isa(hDsrc,'jp2_data_source'));
            assert(isa(inObj,'POC_marker'), 'input for read_POC() shall be POC_marker class.');
            % Lpoc
            inObj.Lpoc = get_word(hDsrc);
            assert(inObj.Lpoc >= 9 && inObj.Lpoc <= 65535);
            if Csiz < 257
                inObj.number_progression_order_change =(inObj.Lpoc - 2)/7;
            else
                inObj.number_progression_order_change =(inObj.Lpoc - 2)/9;
            end
            
            for i = 1:inObj.number_progression_order_change
                inObj.RSpoc(i) = get_byte(hDsrc);
                assert(inObj.RSpoc(i) >= 0 && inObj.RSpoc(i) <= 32);
                if Csiz < 257
                    inObj.CSpoc(i) = get_byte(hDsrc);
                    assert(inObj.CSpoc(i) >= 0 && inObj.CSpoc(i) <= 255);
                else
                    inObj.CSpoc(i) = get_word(hDsrc);
                    assert(inObj.CSpoc(i) >= 0 && inObj.CSpoc(i) <= 16383);
                end
                inObj.LYEpoc(i) = get_word(hDsrc);
                assert(inObj.LYEpoc(i) >= 0 && inObj.LYEpoc(i) <= 65535);
                inObj.REpoc(i) = get_byte(hDsrc);
                assert(inObj.REpoc(i) >= inObj.RSpoc(i)+1 && inObj.REpoc(i) <= 33);
                if Csiz < 257
                    inObj.CEpoc(i) = get_byte(hDsrc);
                    if inObj.CEpoc(i) == 0
                        inObj.CEpoc(i) = 256;
                    end
                    assert(inObj.CEpoc(i) >= inObj.CSpoc(i)+1 && inObj.CEpoc(i) <= 256);
                else
                    inObj.CEpoc(i) = get_word(hDsrc);
                    if inObj.CEpoc(i) == 0
                        inObj.CEpoc(i) = 16384;
                    end
                    assert(inObj.CEpoc(i) >= inObj.CSpoc(i)+1 && inObj.CEpoc(i) <= 16384);
                end
                inObj.Ppoc(i) = get_byte(hDsrc);
                assert(inObj.Ppoc(i) >= 0 && inObj.Ppoc(i) <= 4);
            end
        end
    end
end