function buf = construct_compressed_data(buf, hCodeblock, mq_reg_enc)

M_OFFSET = 1;

CB_BYPASS = bitand(hCodeblock.Cmodes, 1);
CB_RESTART = bitshift(bitand(hCodeblock.Cmodes, 4), -2);

mq_buf_pos = int32(0 + M_OFFSET);
out_buf_pos = int32(0);

if CB_BYPASS == true
    bypass_threshold = 10;
    if CB_RESTART == false
        for n = 1:bypass_threshold
            buf(out_buf_pos + M_OFFSET:out_buf_pos + hCodeblock.pass_length(n)) = mq_reg_enc.byte_stream(mq_buf_pos + M_OFFSET:mq_buf_pos + hCodeblock.pass_length(n));
            mq_buf_pos = mq_buf_pos + hCodeblock.pass_length(n);
            out_buf_pos = out_buf_pos + hCodeblock.pass_length(n);
        end
        mq_buf_pos = int32(sum(hCodeblock.pass_length(1:n)) + 1);
        for n = bypass_threshold + 1:hCodeblock.num_passes
            if mod(n - 10, 3) ~= 0 % raw
                buf(out_buf_pos + M_OFFSET:out_buf_pos + hCodeblock.pass_length(n)) = mq_reg_enc.byte_stream(mq_buf_pos + M_OFFSET:mq_buf_pos + hCodeblock.pass_length(n));
            else % ac
                mq_buf_pos = mq_buf_pos + 1;
                buf(out_buf_pos + M_OFFSET:out_buf_pos + hCodeblock.pass_length(n)) = mq_reg_enc.byte_stream(mq_buf_pos + M_OFFSET:mq_buf_pos + hCodeblock.pass_length(n));
            end
            mq_buf_pos = mq_buf_pos + hCodeblock.pass_length(n);
            out_buf_pos = out_buf_pos + hCodeblock.pass_length(n);
        end
    else
        for n = 1:bypass_threshold
            buf(out_buf_pos + M_OFFSET:out_buf_pos + hCodeblock.pass_length(n)) = mq_reg_enc.byte_stream(mq_buf_pos + M_OFFSET:mq_buf_pos + hCodeblock.pass_length(n));
            mq_buf_pos = mq_buf_pos + hCodeblock.pass_length(n) + 1;
            out_buf_pos = out_buf_pos + hCodeblock.pass_length(n);
        end
        mq_buf_pos = mq_buf_pos - 1;
        for n = bypass_threshold + 1:hCodeblock.num_passes
            if mod(n - 10, 3) ~= 0 % raw
                buf(out_buf_pos + M_OFFSET:out_buf_pos + hCodeblock.pass_length(n)) = mq_reg_enc.byte_stream(mq_buf_pos + M_OFFSET:mq_buf_pos + hCodeblock.pass_length(n));
            else % ac
                mq_buf_pos = mq_buf_pos + 1;
                buf(out_buf_pos + M_OFFSET:out_buf_pos + hCodeblock.pass_length(n)) = mq_reg_enc.byte_stream(mq_buf_pos + M_OFFSET:mq_buf_pos + hCodeblock.pass_length(n));
            end
            mq_buf_pos = mq_buf_pos + hCodeblock.pass_length(n);
            out_buf_pos = out_buf_pos + hCodeblock.pass_length(n);
        end
    end
elseif CB_RESTART == false
    buf = mq_reg_enc.byte_stream(mq_buf_pos + M_OFFSET:mq_buf_pos + sum(hCodeblock.pass_length)); % the first byte is always zero.
else
    for n = 1:hCodeblock.num_passes
        if hCodeblock.pass_length(n) > 0
            buf(out_buf_pos + M_OFFSET:out_buf_pos + hCodeblock.pass_length(n)) = mq_reg_enc.byte_stream(mq_buf_pos + M_OFFSET:mq_buf_pos + hCodeblock.pass_length(n));
        end
        mq_buf_pos = mq_buf_pos + hCodeblock.pass_length(n) + 1;
        out_buf_pos = out_buf_pos + hCodeblock.pass_length(n);
    end
end