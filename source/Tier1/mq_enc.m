classdef mq_enc < handle %#codegen
    properties
        C(1, 1) uint32
        A(1, 1) uint16
        t(1, 1) int16
        T(1, 1) uint8
        L(1, 1) int32
        buf_start(1, 1) int32
        buf_next(1, 1) int32
        byte_stream(1, :) uint8
        dynamic_table(19, 2) uint16
        static_table(47, 4) uint16
        %scan v_mq_enc
    end
    methods
        function outObj = mq_enc
            outObj.C = 0;
            outObj.A = 0;
            outObj.t = 0;
            outObj.T = 0;
            outObj.L = 0;
            outObj.buf_start = 0;
            outObj.buf_next = 0;
            outObj.byte_stream = zeros(1, 32768, 'uint8');
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
            inObj.static_table(:, 4) = uint16(hex2dec(['5601'; '3401'; '1801'; '0AC1'; '0521'; '0221'; '5601'; ...
                '5401'; '4801'; '3801'; '3001'; '2401'; '1C01'; '1601'; ...
                '5601'; '5401'; '5101'; '4801'; '3801'; '3401'; '3001'; ...
                '2801'; '2401'; '2201'; '1C01'; '1801'; '1601'; '1401'; ...
                '1201'; '1101'; '0AC1'; '09C1'; '08A1'; '0521'; '0441'; ...
                '02A1'; '0221'; '0141'; '0111'; '0085'; '0049'; '0025'; ...
                '0015'; '0009'; '0005'; '0001'; '5601']));
        end
        function init_coder(inObj)
            inObj.A = hex2dec('8000');
            inObj.C = 0;
            inObj.t = 12;
            inObj.T = 0;
            inObj.buf_next = -1;
            inObj.buf_start = 0;
        end
        function init_raw(inObj)
            inObj.t = 8;
            inObj.T = 0;
            inObj.buf_next = 0;
            inObj.buf_start = 0;
        end
        function init_states_for_all_context(inObj)
            % for RESET mode
            inObj.dynamic_table(:, 1) = 1;
            inObj.dynamic_table(:, 2) = 0;
            inObj.dynamic_table(0 + 1, :) = [4 + 1, 0];
            inObj.dynamic_table(17 + 1, :) = [3 + 1, 0];
            inObj.dynamic_table(18 + 1, :) = [46 + 1, 0];
        end
        function mq_put_byte(inObj)
            % the first byte in a segment is always discarded.
            inObj.byte_stream(inObj.L + 1) = inObj.T;
            inObj.L = inObj.L + 1;
            inObj.buf_next = inObj.buf_next + 1;
        end
        function mq_transfer_byte(inObj)
            % C subsets indexes
            %C_partial  bit 19 - 26;
            %C_msbs     bit 20 -27;
            %C_carry    bit 27;

            % C Subsets Masks
            C_partial_mask = 133693440; % = bitshift(255, 19) % uint32(sum(2.^(C_partial)));
            C_partial_zero = 4161273855; %1111100000000111111111111111111
            C_msbs_mask = 267386880; % = bitshift(255, 20) % uint32(sum(2.^(C_msbs)));
            C_msbs_zero = 4027580415; %1111000000001111111111111111111
            C_carry_mask = 134217728; % = 2^27
            C_carry_zero = 4160749567; %1111011111111111111111111111111

            if inObj.T == 255 % can't propagate any carry past T; need bit stuff
                mq_put_byte(inObj);
                inObj.T = uint8(bitshift(bitand(inObj.C, C_msbs_mask), -20));
                inObj.C = bitand(inObj.C, C_msbs_zero);
                inObj.t = 7;
            else
                inObj.T = inObj.T + uint8(bitshift(bitand(inObj.C, C_carry_mask), -27));
                inObj.C = bitand(inObj.C, C_carry_zero);
                mq_put_byte(inObj);
                if inObj.T == 255 % decoder will see this as a bit stuff; need to act accordingly
                    inObj.T = uint8(bitshift(bitand(inObj.C, C_msbs_mask), -20));
                    inObj.C = bitand(inObj.C, C_msbs_zero);
                    inObj.t = 7;
                else
                    inObj.T = uint8(bitshift(bitand(inObj.C, C_partial_mask), -19));
                    inObj.C = bitand(inObj.C, C_partial_zero);
                    inObj.t = 8;
                end
            end
        end
        function mq_encoder(inObj, x, label)
            M_OFFSET = 1;
            p_bar = inObj.static_table(inObj.dynamic_table(label + M_OFFSET, 1), 4); % set p_bar = p_bar(\Sigma_k)
            s_k = inObj.dynamic_table(label + M_OFFSET, 2);
            inObj.A = inObj.A - p_bar;
            if x == s_k % coding an MPS
                if inObj.A >= 2^15 % no renormalization and hence no conditional exchange
                    inObj.C = inObj.C + uint32(p_bar);
                else
                    if inObj.A < p_bar % conditional exchange
                        inObj.A = p_bar;
                    else
                        inObj.C = inObj.C + uint32(p_bar);
                    end
                    inObj.dynamic_table(label + M_OFFSET, 1) = inObj.static_table(inObj.dynamic_table(label + M_OFFSET, 1), 1);
                    while 1
                        inObj.A = 2 * inObj.A;
                        inObj.C = 2 * inObj.C;
                        inObj.t = inObj.t - 1;
                        if inObj.t == 0
                            mq_transfer_byte(inObj);
                        end
                        if inObj.A >= 2^15
                            break;
                        end
                    end
                end
            else % coding an LPS; renormalization is inevitable
                if inObj.A < p_bar % conditional exchange
                    inObj.C = inObj.C + uint32(p_bar);
                else
                    inObj.A = p_bar;
                end
                inObj.dynamic_table(label + M_OFFSET, 2) = bitxor(inObj.dynamic_table(label + M_OFFSET, 2), ...
                    inObj.static_table(inObj.dynamic_table(label + M_OFFSET, 1), 3));
                inObj.dynamic_table(label + M_OFFSET, 1) = inObj.static_table(inObj.dynamic_table(label + M_OFFSET, 1), 2);
                while 1
                    inObj.A = 2 * inObj.A;
                    inObj.C = 2 * inObj.C;
                    inObj.t = inObj.t - 1;
                    if inObj.t == 0
                        mq_transfer_byte(inObj);
                    end
                    if inObj.A >= 2^15
                        break;
                    end
                end
            end
        end

        function emit_raw_symbol(inObj, x)
            if inObj.t == 0
                inObj.mq_put_byte();
                if inObj.T == 255
                    inObj.t = 7;
                else
                    inObj.t = 8;
                end
                inObj.T = 0;
            end
            inObj.T = 2 * inObj.T + uint8(x);
            inObj.t = inObj.t - 1;
        end

        function mq_encoder_end(inObj)
            save_C = inObj.C;
            save_A = inObj.A;
            save_T = inObj.T;
            save_t = inObj.t;
            save_L = inObj.L;
            nbits = int32(27 - 15 - inObj.t); % The number of bits we need to flush out of C
            inObj.C = inObj.C * uint32(2^inObj.t); % Move the next 8 available bits into the partial byte
            while nbits > 0
                mq_transfer_byte(inObj);
                % New value of inObj.t is the number of bits just transferred
                nbits = nbits - int32(inObj.t);
                % Move bits into available position for next transfer
                inObj.C = inObj.C * uint32(2^inObj.t);
            end
            mq_transfer_byte(inObj);
            Lrec0 = inObj.L;
            inObj.C = save_C;
            inObj.A = save_A;
            inObj.T = save_T;
            inObj.t = save_t;
            inObj.L = save_L;
            F_min = inObj.get_incremental_optimal_length();

            inObj.L = inObj.L + F_min;
            Lrec1 = inObj.L;
            d = Lrec1 - Lrec0;
            inObj.buf_next = inObj.buf_next + d; %Lrec1 - Lrec0;
            M_OFFSET = 1;
            if inObj.buf_next > 0
                if inObj.byte_stream(inObj.L - 1 + M_OFFSET) == 255
                    inObj.L = inObj.L - 1;
                    inObj.buf_next = inObj.buf_next - 1;
                    if inObj.buf_next - inObj.buf_start > 0 %inObj.L > 0
                        if inObj.byte_stream(inObj.L - 1 + M_OFFSET) == 255
                            inObj.L = inObj.L - 1;
                            inObj.buf_next = inObj.buf_next - 1;
                        end
                    end
                end
            end
        end
        function raw_termination(inObj)
            save_T = inObj.T;
            save_t = inObj.t;
            save_L = inObj.L;
            save_buf_next = inObj.buf_next;
            if inObj.t ~= 8
                while inObj.t > 0
                    inObj.T = 2 * inObj.T + 1;
                    inObj.t = inObj.t - 1;
                end
                inObj.mq_put_byte();
            end
            inObj.t = save_t;
            inObj.T = save_T;
            inObj.L = save_L;
            inObj.buf_next = save_buf_next;
            if inObj.t ~= 8
                inObj.L = inObj.L + 1;
                inObj.buf_next = inObj.buf_next + 1;
            end
            if inObj.buf_next > inObj.buf_start && inObj.byte_stream(inObj.L) == 255
                inObj.L = inObj.L - 1;
                inObj.buf_next = inObj.buf_next - 1;
            end
        end
        function take_reg_snap_shot(inObj, hCodeblock)
            hCodeblock.mq_C(hCodeblock.pass_idx) = inObj.C;
            hCodeblock.mq_A(hCodeblock.pass_idx) = inObj.A;
            hCodeblock.mq_t(hCodeblock.pass_idx) = inObj.t;
            hCodeblock.mq_T(hCodeblock.pass_idx) = inObj.T;
            hCodeblock.mq_L(hCodeblock.pass_idx) = inObj.L;
        end

        function go_reg_snap_shot(inObj, hCodeblock, pass_idx)
            inObj.C = hCodeblock.mq_C(pass_idx);
            inObj.A = hCodeblock.mq_A(pass_idx);
            inObj.t = hCodeblock.mq_t(pass_idx);
            inObj.T = hCodeblock.mq_T(pass_idx);
            inObj.L = hCodeblock.mq_L(pass_idx);
        end
        function F_max = lazy_length_computation(inObj, hCodeblock, pass_idx)
            go_reg_snap_shot(inObj, hCodeblock, pass_idx);

            val = 27 - int32(inObj.t);
            if val <= 22
                F_max = 4;
            else
                F_max = 5;
            end
        end
        function F_min = get_optimal_length(inObj, hCodeblock, pass_idx)
            C_carry_mask = 134217728; % = 2^27

            go_reg_snap_shot(inObj, hCodeblock, pass_idx);
            Tnz = int32(inObj.T);
            tnz = int32(inObj.t);
            Anz = int32(inObj.A);
            Cnz = int32(inObj.C);
            Lnz = int32(inObj.L);

            C_low = bitshift(Cnz, tnz);
            CplusA_low = bitshift(Cnz + Anz, tnz);
            C_high = Tnz;
            CplusA_high = Tnz;

            if bitand(C_low, C_carry_mask) ~= 0
                C_high = C_high + 1;
                C_low = C_low - C_carry_mask;
            end
            if bitand(CplusA_low, C_carry_mask) ~= 0
                CplusA_high = CplusA_high + 1;
                CplusA_low = CplusA_low - C_carry_mask;
            end
            s = int32(8);
            F_min = int32(0);
            while (C_high > 255) || (CplusA_high <= 255)
                F_min = F_min + 1;

                Lnz = Lnz + 1;
                if Lnz > 0
                    Tnz = int32(inObj.byte_stream(Lnz));
                else
                    Tnz = int32(0);
                end


                C_high = C_high - bitshift(Tnz, (8 - s));
                CplusA_high = CplusA_high - bitshift(Tnz, (8 - s));

                C_high = bitshift(C_high, s);
                C_high = C_high + bitshift(C_low, -(27 - s));
                C_low = bitshift(C_low, s);
                C_low = bitand(C_low, 2^27 - 1);

                CplusA_high = bitshift(CplusA_high, s);
                CplusA_high = CplusA_high + bitshift(CplusA_low, -(27 - s));
                CplusA_low = bitshift(CplusA_low, s);
                CplusA_low = bitand(CplusA_low, 2^27 - 1);

                if Tnz == 255
                    s = int32(7);
                else
                    s = int32(8);
                end
            end

        end
        function F_min = get_incremental_optimal_length(inObj)
            C_carry_mask = 134217728; % = 2^27

            Tnz = int32(inObj.T);
            tnz = int32(inObj.t);
            Anz = int32(inObj.A);
            Cnz = int32(inObj.C);
            Lnz = int32(inObj.L);

            C_low = bitshift(Cnz, tnz);
            CplusA_low = bitshift(Cnz + Anz, tnz);
            C_high = Tnz;
            CplusA_high = Tnz;

            if bitand(C_low, C_carry_mask) ~= 0
                C_high = C_high + 1;
                C_low = C_low - C_carry_mask;
            end
            if bitand(CplusA_low, C_carry_mask) ~= 0
                CplusA_high = CplusA_high + 1;
                CplusA_low = CplusA_low - C_carry_mask;
            end
            s = int32(8);
            F_min = int32(0);
            while (C_high > 255) || (CplusA_high <= 255)
                F_min = F_min + 1;

                Lnz = Lnz + 1;
                if Lnz > 0
                    Tnz = int32(inObj.byte_stream(Lnz));
                else
                    Tnz = int32(0);
                end


                C_high = C_high - bitshift(Tnz, (8 - s));
                CplusA_high = CplusA_high - bitshift(Tnz, (8 - s));

                C_high = bitshift(C_high, s);
                C_high = C_high + bitshift(C_low, -(27 - s));
                C_low = bitshift(C_low, s);
                C_low = bitand(C_low, 2^27 - 1);

                CplusA_high = bitshift(CplusA_high, s);
                CplusA_high = CplusA_high + bitshift(CplusA_low, -(27 - s));
                CplusA_low = bitshift(CplusA_low, s);
                CplusA_low = bitand(CplusA_low, 2^27 - 1);

                if Tnz == 255
                    s = int32(7);
                else
                    s = int32(8);
                end
            end
        end
        function terminate_segment(inObj, hCodeblock, N)
            inObj.mq_encoder_end();
            previous_F_min = int32(0);
            for n = 1:N
                F_min = inObj.get_optimal_length(hCodeblock, n);
                hCodeblock.pass_length(n) = hCodeblock.pass_length(n) + F_min - previous_F_min;
                previous_F_min = F_min;
            end
        end
    end
end
