%% LDO loop-stability figures for the blog
% This is an educational small-signal model, not a model of a specific IC.
% It is used to explain poles, zeros, crossover frequency and phase margin.

clear; close all; clc;

script_dir = fileparts(mfilename('fullpath'));
project_dir = fileparts(fileparts(script_dir));
output_dir = fullfile(project_dir, 'source', 'images', 'myimge', 'ldo-basics');
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

font_name = 'Microsoft YaHei';
set(groot, 'defaultAxesFontName', font_name, ...
    'defaultTextFontName', font_name, ...
    'defaultAxesFontSize', 11, ...
    'defaultLineLineWidth', 1.8);

%% 1. A single pole, an LHP zero and an RHP zero
s = tf('s');
w0 = 1;
systems = {1/(1+s/w0), 1+s/w0, 1-s/w0};
names = {'左半平面极点', '左半平面零点', '右半平面零点'};
colors = [0.16 0.39 0.82; 0.10 0.62 0.46; 0.88 0.30 0.34];
line_styles = {'-', '-', '--'};
w = logspace(-2, 2, 1000);

fig = figure('Color', 'w', 'Position', [80 80 1120 720]);
tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

ax1 = nexttile; hold(ax1, 'on'); grid(ax1, 'on');
ax2 = nexttile; hold(ax2, 'on'); grid(ax2, 'on');
set(ax1, 'XScale', 'log');
set(ax2, 'XScale', 'log');
for k = 1:numel(systems)
    response = squeeze(freqresp(systems{k}, w));
    semilogx(ax1, w/w0, 20*log10(abs(response)), 'Color', colors(k,:), ...
        'LineStyle', line_styles{k});
    semilogx(ax2, w/w0, unwrap(angle(response))*180/pi, 'Color', colors(k,:), ...
        'LineStyle', line_styles{k});
end
xline(ax1, 1, '--', '\omega=\omega_0', 'LabelVerticalAlignment', 'bottom', ...
    'HandleVisibility', 'off');
xline(ax2, 1, '--', '\omega=\omega_0', 'LabelVerticalAlignment', 'bottom', ...
    'HandleVisibility', 'off');
yline(ax1, 0, ':', 'HandleVisibility', 'off');
yline(ax2, 0, ':', 'HandleVisibility', 'off');
xlabel(ax2, '归一化频率  \omega / \omega_0');
ylabel(ax1, '幅值 / dB'); ylabel(ax2, '相位 / (°)');
title(ax1, '单个零点与极点的幅频特性');
title(ax2, '左半平面零点提供相位超前，右半平面零点产生相位滞后');
legend(ax1, names, 'Location', 'northwest');
xlim(ax1, [1e-2 1e2]); xlim(ax2, [1e-2 1e2]);
ylim(ax1, [-45 45]); ylim(ax2, [-100 100]);
exportgraphics(fig, fullfile(output_dir, 'matlab-pole-zero-bode.png'), 'Resolution', 180);
close(fig);

%% 2. ESR zero and loop phase margin
% Open-loop model:
% T(s) = A0(1+s/wz) / [(1+s/wp1)(1+s/wp2)(1+s/wp3)]
A0 = 3e4;
fp = [10, 2e3, 100e3];             % Hz
wp = 2*pi*fp;
Cout = 10e-6;                      % F
esr = [0.05, 1, 20];               % ohm
w = 2*pi*logspace(0, 7, 2400);     % 1 Hz to 10 MHz

loops = cell(size(esr));
phase_margin = zeros(size(esr));
crossover_hz = zeros(size(esr));
esr_zero_hz = 1./(2*pi*Cout*esr);

for k = 1:numel(esr)
    wz = 2*pi*esr_zero_hz(k);
    loops{k} = A0*(1+s/wz) / ...
        ((1+s/wp(1))*(1+s/wp(2))*(1+s/wp(3)));
    [~, phase_margin(k), ~, wc] = margin(loops{k});
    crossover_hz(k) = wc/(2*pi);
end

fig = figure('Color', 'w', 'Position', [80 80 1160 760]);
tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
ax1 = nexttile; hold(ax1, 'on'); grid(ax1, 'on');
ax2 = nexttile; hold(ax2, 'on'); grid(ax2, 'on');
set(ax1, 'XScale', 'log');
set(ax2, 'XScale', 'log');
legend_text = strings(size(esr));

for k = 1:numel(esr)
    response = squeeze(freqresp(loops{k}, w));
    magnitude_db = 20*log10(abs(response));
    phase_deg = unwrap(angle(response))*180/pi;
    semilogx(ax1, w/(2*pi), magnitude_db, 'Color', colors(k,:));
    semilogx(ax2, w/(2*pi), phase_deg, 'Color', colors(k,:));
    plot(ax1, crossover_hz(k), 0, 'o', 'Color', colors(k,:), ...
        'MarkerFaceColor', colors(k,:), 'HandleVisibility', 'off');
    plot(ax2, crossover_hz(k), -180+phase_margin(k), 'o', ...
        'Color', colors(k,:), 'MarkerFaceColor', colors(k,:), ...
        'HandleVisibility', 'off');
    legend_text(k) = sprintf('ESR = %.2g \\Omega,  f_z = %.3g Hz,  PM = %.1f°', ...
        esr(k), esr_zero_hz(k), phase_margin(k));
end

yline(ax1, 0, '--', '0 dB', 'LabelHorizontalAlignment', 'left', ...
    'HandleVisibility', 'off');
yline(ax2, -180, '--', '-180°', 'LabelHorizontalAlignment', 'left', ...
    'HandleVisibility', 'off');
xlabel(ax2, '频率 / Hz'); ylabel(ax1, '环路增益 / dB'); ylabel(ax2, '相位 / (°)');
title(ax1, '输出电容 ESR 改变零点位置，也会改变 0 dB 交越频率');
title(ax2, '相位裕量必须在各自的交越频率处读取');
legend(ax1, legend_text, 'Location', 'southwest');
xlim(ax1, [1 1e7]); xlim(ax2, [1 1e7]);
ylim(ax1, [-80 100]); ylim(ax2, [-280 20]);
exportgraphics(fig, fullfile(output_dir, 'matlab-esr-loop-margin.png'), 'Resolution', 180);
close(fig);

%% 3. Closed-loop pole locations for the three ESR values
fig = figure('Color', 'w', 'Position', [80 80 1120 700]);
ax = axes(fig); hold(ax, 'on'); grid(ax, 'on');
all_poles = [];
for k = 1:numel(loops)
    closed_loop = feedback(loops{k}, 1);
    poles_khz = pole(closed_loop)/(2*pi*1e3);
    all_poles = [all_poles; poles_khz]; %#ok<AGROW>
    scatter(ax, real(poles_khz), imag(poles_khz), 85, colors(k,:), 'x', ...
        'LineWidth', 2, 'DisplayName', sprintf('ESR = %.2g \\Omega, PM = %.1f°', ...
        esr(k), phase_margin(k)));
end
xline(ax, 0, '--', '虚轴：稳定边界', 'LabelVerticalAlignment', 'bottom', ...
    'HandleVisibility', 'off');
yline(ax, 0, ':', 'HandleVisibility', 'off');
xlabel(ax, '极点实部 / kHz'); ylabel(ax, '极点虚部 / kHz');
title(ax, '闭环极点位置：右半平面极点表示闭环不稳定');
legend(ax, 'Location', 'best');
max_abs_imag = max(abs(imag(all_poles)));
xlim(ax, [-1.1*max_abs_imag, 0.35*max_abs_imag]);
ylim(ax, [-1.1*max_abs_imag, 1.1*max_abs_imag]);
unstable_poles = pole(feedback(loops{1}, 1))/(2*pi*1e3);
unstable_pair = unstable_poles(imag(unstable_poles) > 0);
text(ax, 8, 38, sprintf('右半平面极点：%+.2f + j%.1f kHz', ...
    real(unstable_pair), imag(unstable_pair)), 'Color', colors(1,:), ...
    'FontWeight', 'bold');
exportgraphics(fig, fullfile(output_dir, 'matlab-esr-closed-loop-poles.png'), 'Resolution', 180);
close(fig);

%% Save exact numerical results beside the figures
result_file = fullfile(script_dir, 'ldo_stability_results.txt');
fid = fopen(result_file, 'w');
fprintf(fid, 'Educational LDO loop model (not a specific IC)\n');
fprintf(fid, 'A0 = %.6g\n', A0);
fprintf(fid, 'Poles = %.6g Hz, %.6g Hz, %.6g Hz\n', fp(1), fp(2), fp(3));
fprintf(fid, 'Cout = %.6g F\n\n', Cout);
fprintf(fid, 'ESR(ohm)\tESR zero(Hz)\tCrossover(Hz)\tPhase margin(deg)\tClosed-loop stable\n');
for k = 1:numel(esr)
    stable = isstable(feedback(loops{k}, 1));
    fprintf(fid, '%.6g\t%.6g\t%.6g\t%.6g\t%d\n', esr(k), esr_zero_hz(k), ...
        crossover_hz(k), phase_margin(k), stable);
end
fclose(fid);

disp('Generated LDO stability figures:');
disp(fullfile(output_dir, 'matlab-pole-zero-bode.png'));
disp(fullfile(output_dir, 'matlab-esr-loop-margin.png'));
disp(fullfile(output_dir, 'matlab-esr-closed-loop-poles.png'));
disp(result_file);
