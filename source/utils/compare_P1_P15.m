clear;
clc;
load barbara;
%P = imread('kodim23.png');
base_stepsize = [1, 1 / 2, 1 / 4, 1 / 8, 1 / 16, 1 / 32, 1 / 64, 1 / 128, 1 / 256];
time_eP1 = zeros(length(base_stepsize) + 1, 2);
time_eP15 = zeros(length(base_stepsize) + 1, 2);
time_dP1 = zeros(length(base_stepsize) + 1, 2);
time_dP15 = zeros(length(base_stepsize) + 1, 2);

PSNR_P1 = zeros(length(base_stepsize) + 1, 1);
PSNR_P15 = zeros(length(base_stepsize) + 1, 1);

target_rate = 24; %
test_image = imresize(img_barbara, 1);

P1_cmodes = '';
P15_cmodes = 'HT';

N_trial = 10;

fprintf('================ Encoding ====\n');

for n = 1:N_trial
    fprintf('Trial number = %d/%d\n', n, N_trial);
    fprintf('==== Part 1 ====\n');
    for i = 1:length(base_stepsize)
        fname = sprintf('p1_%f.j2c', base_stepsize(i));
        [time_eP1(i, 1, n), time_eP1(i, 2, n)] = encode_HTJ2K(fname, test_image, 'levels', 5, 'reversible', 'no', 'cmodes', P1_cmodes, 'qstep', base_stepsize(i), 'blk', [64, 64], 'guard', 1);
    end
    [time_eP1(i + 1, 1, n), time_eP1(i + 1, 2, n)] = encode_HTJ2K('p1_lossless.j2c', test_image, 'levels', 5, 'reversible', 'yes', 'cmodes', P1_cmodes, 'qstep', base_stepsize(i), 'blk', [64, 64], 'guard', 1);
    is_HT = true;
    fprintf('==== Part 15 ====\n');
    for i = 1:length(base_stepsize)
        fname = sprintf('p15_%f.j2c', base_stepsize(i));
        [time_eP15(i, 1, n), time_eP15(i, 2, n)] = encode_HTJ2K(fname, test_image, 'levels', 5, 'reversible', 'no', 'cmodes', P15_cmodes, 'qstep', base_stepsize(i), 'blk', [64, 64], 'guard', 1);
    end
    [time_eP15(i + 1, 1, n), time_eP15(i + 1, 2, n)] = encode_HTJ2K('p15_lossless.j2c', test_image, 'levels', 5, 'reversible', 'yes', 'cmodes', P15_cmodes, 'qstep', base_stepsize(i), 'blk', [64, 64], 'guard', 1);
end
time_enc_P1_ave = mean(time_eP1, 3);
time_enc_P15_ave = mean(time_eP15, 3);

hold off;
figure(1);
plot([1:10], time_enc_P1_ave(:, 2) ./ time_enc_P15_ave(:, 2), 'Color', [0.85, 0.33, 0.10], 'LineStyle', '--', 'LineWidth', 2, 'Marker', '*', 'MarkerSize', 8);
%pbaspect([2 1 1]);
% ax = gca;
% outerpos = ax.OuterPosition;
% ti = ax.TightInset;
% left = outerpos(1) + ti(1);
% bottom = outerpos(2) + ti(2);
% ax_width = outerpos(3) - ti(1) - ti(3);
% ax_height = outerpos(4) - ti(2) - ti(4);
% ax.Position = [left bottom ax_width ax_height];
hold on;
plot([1:10], time_enc_P1_ave(:, 1) ./ time_enc_P15_ave(:, 1), 'Color', [0.00, 0.45, 0.74], 'LineStyle', '-.', 'LineWidth', 2, 'Marker', 'o', 'MarkerSize', 8);
xlabel('Base step size (\Delta_b is multiplied by this value)', 'FontName', 'Helvetica', 'FontWeight', 'bold');
ylabel('Speedup factor', 'FontName', 'Helvetica', 'FontWeight', 'bold');
xticks([1:10]);
xticklabels({'1', '1/2', '1/4', '1/8', '1/16', '1/32', '1/64', '1/128', '1/256', 'Lossless'});
legend('Block encoder only', 'Whole encoding', 'Location', 'best');


for n = 1:N_trial
    fprintf('Trial number = %d/%d\n', n, N_trial);
    fprintf('================ Decoding ====\n');
    fprintf('==== Part 1 ====\n');
    for i = 1:length(base_stepsize)
        fname = sprintf('p1_%f.j2c', base_stepsize(i));
        [~, p1_output{i}, time_dP1(i, 1), time_dP1(i, 2)] = decode_HTJ2K(fname, true);
    end
    [~, p1_output{i + 1}, time_dP1(i + 1, 1), time_dP1(i + 1, 2)] = decode_HTJ2K('p1_lossless.j2c', true);

    fprintf('==== Part 15 ====\n');
    for i = 1:length(base_stepsize)
        fname = sprintf('p15_%f.j2c', base_stepsize(i));
        [~, p15_output{i}, time_dP15(i, 1), time_dP15(i, 2)] = decode_HTJ2K(fname, true);
    end
    [~, p15_output{i + 1}, time_dP15(i + 1, 1), time_dP15(i + 1, 2)] = decode_HTJ2K('p15_lossless.j2c', true);


end

time_dec_P1_ave = mean(time_dP1, 3);
time_dec_P15_ave = mean(time_dP15, 3);

for i = 1:length(base_stepsize) + 1
    PSNR_P1(i) = psnr(uint8(p1_output{i}), test_image);
    PSNR_P15(i) = psnr(uint8(p15_output{i}), test_image);
end
hold off;
figure(2);
plot([1:10], time_dec_P1_ave(:, 2) ./ time_dec_P15_ave(:, 2), 'Color', [0.85, 0.33, 0.10], 'LineStyle', '--', 'LineWidth', 2, 'Marker', '*', 'MarkerSize', 8);
hold on;
plot([1:10], time_dec_P1_ave(:, 1) ./ time_dec_P15_ave(:, 1), 'Color', [0.00, 0.45, 0.74], 'LineStyle', '-.', 'LineWidth', 2, 'Marker', 'o', 'MarkerSize', 8);
hold off;
xlabel('Base step size (\Delta_b is multiplied by this value)', 'FontName', 'Helvetica', 'FontWeight', 'bold');
ylabel('Speedup factor', 'FontName', 'Helvetica', 'FontWeight', 'bold');
xticks([1:10]);
xticklabels({'1', '1/2', '1/4', '1/8', '1/16', '1/32', '1/64', '1/128', '1/256', 'Lossless'});
legend('Block decoder only', 'Whole decoding', 'Location', 'best');

%
% plot([1:5], 100*(bpp_p15./bpp_p1-1), 'Color', [0.00 0.45 0.74], 'LineStyle', '-.', 'LineWidth', 2, 'Marker', 'o', 'MarkerSize', 8);
% xlabel('Bit-rate of J2K codestreams (bit/pixel)', 'FontName', 'Helvetica', 'FontWeight', 'bold');
% ylabel('Efficiency loss in HTJ2K codestreams(%)', 'FontName', 'Helvetica', 'FontWeight', 'bold');
% xticks([1:10]);
% xticklabels({'0.25', '0.5', '1.0', '2.0', 'Lossless'});
