classdef mq_dec < handle
    properties
        A(1, 1) uint16
        t(1, 1) uint8
        C(1, 1) uint32 % Lower-bound interval
        T(1, 1) uint8 % Temporary byte register
        L(1, 1) int32 % position in byte-stream
        L_start(1, 1) int32 % position in byte-stream
        Lmax(1, 1) int32 % position of current codeword segment boundary
        byte_buffer(1, :) uint8 % Byte-stream buffer
        dynamic_table(19, 2) uint16
        static_table(47, 4) uint16
    end
    methods
        function outObj = mq_dec(buf)
            outObj.byte_buffer = buf;
            % initialization for MATLAB coder
            outObj.A = 0;
            outObj.t = 0;
            outObj.C = 0;
            outObj.T = 0;
            outObj.L = 0;
            outObj.Lmax = 0;
            outObj.L_start = 0;
        end
        function set_tables(inObj)
            M_OFFSET = 1;
            % Those values are found in Table C.2 of the ISO/IEC 15444-1
            inObj.dynamic_table = zeros(19, 2, 'uint16');
            inObj.static_table = zeros(47, 4, 'uint16');

            % NMPS
            inObj.static_table(:, 1) = [1, 2, 3, 4, 5, 38, 7, 8, 9, 10, 11, 12, 13, 29, 15, 16, 17, ...
                18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, ...
                35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 45, 46];
            inObj.static_table(:, 1) = inObj.static_table(:, 1) + M_OFFSET;

            % NLPS
            inObj.static_table(:, 2) = [1, 6, 9, 12, 29, 33, 6, 14, 14, 14, 17, 18, 20, 21, 14, 14, 15, ...
                16, 17, 18, 19, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, ...
                32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 46];
            inObj.static_table(:, 2) = inObj.static_table(:, 2) + M_OFFSET;

            % SWTICH
            inObj.static_table(:, 3) = zeros(47, 1, 'uint16');
            inObj.static_table([1, 7, 15], 3) = 1;

            % Qe_value
            inObj.static_table(:, 4) = uint16(hex2dec([ ...
                '5601'; '3401'; '1801'; '0AC1'; '0521'; '0221'; '5601'; ...
                '5401'; '4801'; '3801'; '3001'; '2401'; '1C01'; '1601'; ...
                '5601'; '5401'; '5101'; '4801'; '3801'; '3401'; '3001'; ...
                '2801'; '2401'; '2201'; '1C01'; '1801'; '1601'; '1401'; ...
                '1201'; '1101'; '0AC1'; '09C1'; '08A1'; '0521'; '0441'; ...
                '02A1'; '0221'; '0141'; '0111'; '0085'; '0049'; '0025'; ...
                '0015'; '0009'; '0005'; '0001'; '5601']));
        end
        function init_coder(inObj, buf_pos, segment_length, is_bypass)
            inObj.L_start = buf_pos;
            inObj.Lmax = buf_pos + segment_length;
            inObj.L = buf_pos; % this means L points the begning of a codeword segment (L=0)
            if is_bypass == false
                inObj.T = 0;
                inObj.C = 0;
                inObj.mq_fill_lsbs();
                inObj.C = bitshift(inObj.C, inObj.t);
                inObj.mq_fill_lsbs();
                inObj.C = bitshift(inObj.C, 7);
                inObj.t = inObj.t - 7;
                inObj.A = uint16(hex2dec('8000'));
            else
                inObj.T = 0;
                inObj.t = 0;
            end
        end
        function finish(inObj)
            % maybe ERTERM
        end
        function init_states_for_all_context(inObj)
            % for RESET mode
            inObj.dynamic_table(:, 1) = 1;
            inObj.dynamic_table(:, 2) = 0;
            inObj.dynamic_table(0 + 1, :) = [4 + 1, 0];
            inObj.dynamic_table(17 + 1, :) = [3 + 1, 0];
            inObj.dynamic_table(18 + 1, :) = [46 + 1, 0];
        end
        function mq_fill_lsbs(inObj)
            inObj.t = uint8(8);
            if (inObj.L == inObj.Lmax) || ...
                    (inObj.T == 255 && inObj.byte_buffer(inObj.L + 1) > 143)
                % Codeword exhausted; fill C with 1's from now on
                inObj.C = inObj.C + uint32(255);
            else
                if inObj.T == uint8(255)
                    inObj.t = uint8(7);
                end
                inObj.T = uint8(inObj.byte_buffer(inObj.L + 1));
                inObj.L = inObj.L + 1;
                inObj.C = inObj.C + bitshift(uint32(inObj.T), 8 - inObj.t);
            end
        end
        function mq_renormalize_once(inObj)
            if inObj.t == 0
                inObj.mq_fill_lsbs();
            end
            inObj.A = 2 * inObj.A;
            inObj.C = 2 * inObj.C;
            inObj.t = inObj.t - 1;
        end
        function symbol = mq_decoder(inObj, label)
            M_OFFSET = 1;
            % C subsets indexes
            C_active = 9:24;
            C_active_mask = uint32(16776960); %uint32(sum(2.^(C_active-1)));

            % Get information related to the label
            expected_symbol = inObj.dynamic_table(label + M_OFFSET, 2); % s = s_k
            probability = inObj.static_table(inObj.dynamic_table(label + M_OFFSET, 1), 4); % p = p(sigma_k)

            if expected_symbol > 1
                error('pstlasdkldf'); % osamu: originally, it is 'disp'
            end
            inObj.A = inObj.A - uint16(probability);

            if inObj.A < uint16(probability)
                % Conditional exchange of MPS and LPS
                expected_symbol = 1 - expected_symbol;
            end

            % Compare active region of C
            if bitshift(bitand(inObj.C, C_active_mask), -8) < probability
                symbol = 1 - expected_symbol;
                inObj.A = uint16(probability);
            else
                symbol = expected_symbol;
                Temp = bitshift(bitand(inObj.C, C_active_mask), -(min(C_active) - 1)) - uint32(probability);
                inObj.C = bitand(inObj.C, bitcmp(C_active_mask));
                inObj.C = inObj.C + bitand(uint32(bitshift(Temp, min(C_active) - 1)), C_active_mask);
            end

            if inObj.A < 2^15
                % The symbol was a real MPS
                if symbol == inObj.dynamic_table(label + M_OFFSET, 2)
                    inObj.dynamic_table(label + M_OFFSET, 1) = inObj.static_table(inObj.dynamic_table(label + M_OFFSET, 1), 1);
                    % The symbol was a real LPS
                else
                    inObj.dynamic_table(label + M_OFFSET, 2) = bitxor(inObj.dynamic_table(label + M_OFFSET, 2), ...
                        inObj.static_table(inObj.dynamic_table(label + M_OFFSET, 1), 3));
                    inObj.dynamic_table(label + M_OFFSET, 1) = inObj.static_table(inObj.dynamic_table(label + M_OFFSET, 1), 2);
                end
            end
            % Perform quantization shift
            while inObj.A < 2^15
                inObj.mq_renormalize_once();
            end
        end
        function symbol = get_raw_symbol(inObj)
            if inObj.t == 0
                inObj.t = uint8(8);
                if inObj.L == inObj.Lmax
                    inObj.T = uint8(255);
                else
                    if inObj.T == 255
                        inObj.t = uint8(7);
                    end
                    inObj.T = uint8(inObj.byte_buffer(inObj.L + 1));
                    inObj.L = inObj.L + 1;
                end
            end
            inObj.t = inObj.t - 1;
            symbol = bitand(bitshift(int32(inObj.T), -int32(inObj.t)), 1);
        end
    end
end
