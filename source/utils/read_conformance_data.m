%test_imgs = cell(16,4);
cn = [0, 0, 0, 2, 3, 3, 2, 2, 0, 2, 0, 0, 3, 2, 0, 0];
for n = 1:16
    for c = 0:cn(n)
        fbase = sprintf('~/Documents/Clone/WG1/htj2k-codestreams/reference_class1_profile0/c1p0_%02d-%d.pgx', n, c);
        test_imgs{1, n, c+1} = read_pgx(fbase);
    end
end

cn = [0, 2, 3, 0, 2, 2, 1];
for n = 1:7
    for c = 0:cn(n)
        fbase = sprintf('~/Documents/Clone/WG1/htj2k-codestreams/reference_class1_profile1/c1p1_%02d-%d.pgx', n, c);
        test_imgs{2, n, c+1} = read_pgx(fbase);
    end
end
