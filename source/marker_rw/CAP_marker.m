classdef CAP_marker < handle
    properties
        Lcap uint16
        Pcap uint32
        Ccap uint16
        is_part15 logical
        is_read logical
    end
    methods
        function outObj = CAP_marker(Pcap, Ccap)
            if nargin == 0
                outObj.is_part15 = false;
                outObj.is_read = false;
            else
                outObj.Pcap = Pcap;
                outObj.Ccap = Ccap;
                n = 0;
                for i = 1:32
                    if bitand(Pcap, 2^(32 - i)) ~= 0
                        if i == 15
                            outObj.is_part15 = true;
                        end
                        n = n + 1;
                    end
                end
                outObj.Lcap = 6 + 2 * n;
            end
        end
        function output = get_num_parts_used(inObj)
            n = (inObj.Lcap - 6) / 2;
            output = zeros(1, n);
            if n ~= 0
                for i = 1:n
                    for j = 1:32
                        if bitand(inObj.Pcap, 2^(32 - j)) ~= 0
                            output(i) = j;
                        end
                    end
                end
            else
                output = [];
            end
        end
        function output = get_Ccap(inObj, PartNo)
            usedParts = get_num_parts_used(inObj);
            assert(ismember(PartNo, usedParts));
            output = inObj.Ccap(1); % for future, Ccap(n) may appear
        end
        function [Bits14_15, Bit13, Bit12, Bit11, Bit5, Bits0_4, MAGB] = parse_Ccap15(inObj)
            Ccap15 = get_Ccap(inObj, 15);
            Bits14_15 = bitshift(Ccap15, -14); % 0: HTONLY, 2:HTDECLARED, 3:MIXED
            Bit13 = bitand(bitshift(Ccap15, -13), 1); % 0: SINGLEHT, 1:MULTIHT
            Bit12 = bitand(bitshift(Ccap15, -12), 1); % 0: RGNFREE, 1:RGN
            Bit11 = bitand(bitshift(Ccap15, -11), 1); % 0: HOMOGENEOUS, 1:HETEROGENEOUS
            Bit5 = bitand(bitshift(Ccap15, -5), 1); % 0:HTREV, 1:HTIRV
            Bits0_4 = bitand(Ccap15, hex2dec('F'));

            P = Bits0_4;
            B = 8;
            if P == 31
                B = 74;
            elseif P >= 20
                B = 4 * (P - 19) + 27;
            elseif P > 0
                B = P + 8;
            end % P == 0 then B = 8
            MAGB = uint16(B);
        end
        function read_CAP(inObj, hDsrc)
            assert(isa(hDsrc, 'jp2_data_source'));
            assert(isa(inObj, 'CAP_marker'), 'input for read_CAP() shall be CAP_marker class.');
            inObj.Lcap = get_word(hDsrc);
            inObj.Pcap = get_dword(hDsrc);
            for i = 1:32
                if bitand(inObj.Pcap, 2^(32 - i)) ~= 0
                    inObj.Ccap(i) = get_word(hDsrc);
                    if i == 15
                        inObj.is_part15 = true;
                    end
                else
                    inObj.Ccap(i) = 0;
                end
            end
            %            n = (inObj.Lcap - 6)/2;
            %             for i=1:n
            %                 inObj.Ccap(i) = get_word(hDsrc);
            %             end
            inObj.is_read = true;
        end
        function write_CAP(inObj, m, hDdst)
            assert(isa(inObj, 'CAP_marker'), 'input for CAPmarker.write() shall be CAP_marker class.');
            put_word(hDdst, m.CAP);
            put_word(hDdst, inObj.Lcap);
            put_dword(hDdst, inObj.Pcap);
            n = (inObj.Lcap - 6) / 2;
            for i = 1:n
                put_word(hDdst, inObj.Ccap(i));
            end
        end
    end
end
