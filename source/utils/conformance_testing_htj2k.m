function [out_dec, out_ref] = conformance_testing_htj2k(p, n_codestream, ht_or_hm, fid)
if nargin < 4
    fid = 1; %stdout
end
reduce = 0;
if n_codestream == 8 && p == 0
    reduce = 1;
end

magb = {
    {
    [11],
    [11 12],
    [11 14],
    [11 12],
    [11 12],
    [11 15 18],
    [11 15 16],
    [11 15 16],
    [11],
    [11],
    [10],
    [11],
    [11],
    [11],
    [11 14],
    [11]},
    {
    [11 12],
    [11 12],
    [11 12],
    [9],
    [11],
    [11],
    [11]
    }
    };

nimg = [16,7];
if strcmp(ht_or_hm, 'ht') == true
    for i = 1:length(magb{p+1}{n_codestream})
        if p == 1 && n_codestream == 2
            spath = sprintf('~/Documents/Clone/WG1/htj2k-codestreams/htj2k_bsets_profile%d/p%d_%02d_bset/', p, p, n_codestream);
            fname{i} = sprintf('ds%d_ht_%02d_b%d_mod.j2k', p, n_codestream, magb{p+1}{n_codestream}(i));
        else
            spath = sprintf('~/Documents/Clone/WG1/htj2k-codestreams/htj2k_bsets_profile%d/p%d_%02d_bset/', p, p, n_codestream);
            fname{i} = sprintf('ds%d_ht_%02d_b%d.j2k', p, n_codestream, magb{p+1}{n_codestream}(i));
        end
        fprintf('File: %s\n', fname{i});
        [ht_out{p+1,n_codestream,i}, ht_c_out{p+1,n_codestream,i}] = decode_HTJ2K(sprintf('%s%s',spath, fname{i}), true, reduce);
    end
else
    assert(p == 0 && n_codestream == 6 || n_codestream == 15);
    if n_codestream == 6
        mixed_magb = {[11 18]};
    else
        mixed_magb = {[8]};
    end
    for i = 1:length(mixed_magb{1})
        spath = sprintf('~/Documents/Clone/WG1/htj2k-codestreams/htj2k_bsets_profile%d/p%d_%02d_bset/', p, p, n_codestream);
        fname{i} = sprintf('ds%d_hm_%02d_b%d.j2k', p, n_codestream,mixed_magb{1}(i));
        fprintf('File: %s\n', fname{i});
        [ht_out{p+1,n_codestream,i}, ht_c_out{p+1,n_codestream,i}] = decode_HTJ2K(sprintf('%s%s',spath, fname{i}), true, reduce);
    end
end

read_conformance_data;

n_magb = {[1 2 2 2 2 3 3 3 1 1 1 1 1 1 2 1],[2 2 2 1 1 1 1]};
nc     = {[0 0 0 2 3 3 2 2 0 2 0 0 3 2 0 0],[0 2 3 0 2 2 1]};
rev    = {[1 1 1 0 2 2 1 1 0 1 1 1 1 1 1 1],[2 0 2 0 0 0 1]};
ycc    = {[0 0 0 1 0 0 0 0 0 1 0 0 1 1 0 0],[0 1 0 0 1 1 0]};
% 0: uint8, 1:4bit signed, 2:12 bit unsigned, 3:12bit signed
img_type = {[0 0 1 0 0 2 3 3 0 0 0 0 0 0 1 0],[0 0 0 2 0 0 0]};
fprintf(fid, 'Profile %d\n', p);

if strcmp(ht_or_hm, 'ht') == true
    m_stop = n_magb{p+1}(n_codestream);
else
    m_stop = length(mixed_magb{1});
end
for m = 1:m_stop
    fprintf(fid, '\tcodestream # %2d MAGB = %2d\n', n_codestream, magb{p+1}{n_codestream}(m));
    for c = 0:nc{p+1}(n_codestream)
        if img_type{p+1}(n_codestream) == 0
            fun = @uint8;
            mul = 1;
            offset = 0;
            dc_offset = 2^7;
            MAXVAL = 255;
            MINVAL = 0;
        elseif img_type{p+1}(n_codestream) == 1
            fun = @uint8;
            mul = 16;
            offset = 2^7;
            dc_offset = 0;
            MAXVAL = 7;
            MINVAL = -8;
        elseif img_type{p+1}(n_codestream) == 2
            fun = @uint16;
            mul = 1;
            offset = 0;
            dc_offset = 2^11;
            MAXVAL = 4095;
            MINVAL = 0;
        else
            fun = @uint16;
            mul = 1;
            offset = 2^11;
            dc_offset = 0;
            MAXVAL = 2047;
            MINVAL = -2048;
        end
        
        tmp_ref{c+1} = test_imgs{p+1, n_codestream,c+1};
    end
    
    if ycc{p+1}(n_codestream) == 1
        for i = 0:nc{p+1}(n_codestream)
            tmp_d(:,:,i+1) = ht_out{p+1, n_codestream, m}{i+1};
            tmp_r(:,:,i+1) = tmp_ref{i+1};
        end
        if rev{p+1}(n_codestream) == 1
            tmp_d(:,:,1:3) = myycbcr2rgb(tmp_d(:,:,1:3), 1);
        else
            tmp_d(:,:,1:3) = myycbcr2rgb(tmp_d(:,:,1:3), 0);
        end
        for i = 0:nc{p+1}(n_codestream)
            dec{i+1} = tmp_d(:,:,i+1);
            ref{i+1} = tmp_r(:,:,i+1);
        end
    else
        for i = 0:nc{p+1}(n_codestream)
            dec{i+1} = ht_out{p+1, n_codestream, m}{i+1};
            ref{i+1} = tmp_ref{i+1};
        end
    end
    
    
    for i = 0:nc{p+1}(n_codestream)
        tmp = dec{i+1};
        tmp = round(tmp);
        tmp = tmp + dc_offset;
        tmp(tmp>MAXVAL) = MAXVAL;
        tmp(tmp<MINVAL) = MINVAL;
        dec{i+1} = tmp;
%         dec{i+1} = fun(dec{i+1}*mul+offset);
%         ref{i+1} = fun(ref{i+1}*mul+offset);
    end
    
    for i = 0:nc{p+1}(n_codestream)
        d = ref{i+1} - dec{i+1};
        MSE = mean2(d.^2);%/length(ref{i+1}(:));
        PEAK = max(max(abs(d)));
        fprintf(fid, '\t\tc#%d, PEAK = %-4d, MSE = %-9.4f\n', i, PEAK, MSE);
        out_ref{m,i+1} = ref{i+1};
        out_dec{m,i+1} = dec{i+1};
    end
    
    fprintf('\n');
    clear ref dec tmp_d tmp_r;
end

