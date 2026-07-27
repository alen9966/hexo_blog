%% MATLAB figures for the transfer-function learning article.
% Every figure is a theoretical simulation, not hardware measurement.

clear; close all; clc;

script_dir = fileparts(mfilename('fullpath'));
project_dir = fileparts(fileparts(script_dir));
output_dir = fullfile(project_dir, 'source', 'images', 'myimge', 'transfer-function');
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

set(groot, 'defaultAxesFontName', 'Microsoft YaHei', ...
    'defaultTextFontName', 'Microsoft YaHei', ...
    'defaultAxesFontSize', 11, 'defaultLineLineWidth', 1.8);

% RL series circuit: voltage input, current output.
R = 10;
L = 10e-3;
tau = L / R;
s = tf('s');
G_RL = 1 / (L*s + R);
t = linspace(0, 6*tau, 1200);
[i, t] = step(G_RL, t);

fig = figure('Color', 'w', 'Position', [80 80 1040 540]);
plot(t*1e3, i, 'Color', [0.12 0.39 0.82]); hold on; grid on;
yline(1/R, '--', '稳态电流  U/R = 0.1 A', 'LabelHorizontalAlignment', 'left');
xline(tau*1e3, '--', '时间常数  τ=L/R=1 ms', 'LabelVerticalAlignment', 'bottom');
xlabel('时间 / ms'); ylabel('电流 i(t) / A');
title('RL 串联电路对 1 V 阶跃输入的电流响应（MATLAB 理论仿真）');
text(3.8, 0.035, 'R = 10 Ω ； L = 10 mH ； G(s) = 1/(Ls+R)', ...
    'BackgroundColor', 'w', 'EdgeColor', [0.7 0.7 0.7]);
exportgraphics(fig, fullfile(output_dir, 'rl-step-response.png'), 'Resolution', 180);
close(fig);

% Bode diagram for G_RL(s).
w = 2*pi*logspace(0, 5, 1600);
response = squeeze(freqresp(G_RL, w));
f0 = R/(2*pi*L);
fig = figure('Color', 'w', 'Position', [80 80 1040 720]);
tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
ax1 = nexttile; hold(ax1, 'on'); grid(ax1, 'on'); set(ax1, 'XScale', 'log');
semilogx(ax1, w/(2*pi), 20*log10(abs(response)), 'Color', [0.12 0.39 0.82]);
xline(ax1, f0, '--', 'f0 = R/(2πL) = 159.2 Hz', 'LabelVerticalAlignment', 'bottom');
ylabel(ax1, '幅值 / dB'); title(ax1, 'RL 电流传递函数的幅频特性');
ax2 = nexttile; hold(ax2, 'on'); grid(ax2, 'on'); set(ax2, 'XScale', 'log');
semilogx(ax2, w/(2*pi), unwrap(angle(response))*180/pi, 'Color', [0.88 0.30 0.34]);
xline(ax2, f0, '--', 'f0 = 159.2 Hz', 'LabelVerticalAlignment', 'bottom');
xlabel(ax2, '频率 / Hz'); ylabel(ax2, '相位 / (°)'); title(ax2, 'RL 电流传递函数的相频特性');
exportgraphics(fig, fullfile(output_dir, 'rl-bode-response.png'), 'Resolution', 180);
close(fig);

% Same stable closed-loop structure, different damping and pole locations.
Gp = 1/(s*(s+2));
K = [0.25, 1, 9];
labels = {'K = 0.25：过阻尼', 'K = 1：临界阻尼', 'K = 9：欠阻尼'};
colors = [0.12 0.39 0.82; 0.10 0.62 0.46; 0.88 0.30 0.34];
t = linspace(0, 8, 1600);
fig = figure('Color', 'w', 'Position', [80 80 1080 700]);
tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
ax1 = nexttile; hold(ax1, 'on'); grid(ax1, 'on');
ax2 = nexttile; hold(ax2, 'on'); grid(ax2, 'on');
for k = 1:numel(K)
    Tcl = feedback(K(k)*Gp, 1);
    [y, tt] = step(Tcl, t);
    plot(ax1, tt, y, 'Color', colors(k,:), 'DisplayName', labels{k});
    p = pole(Tcl);
    scatter(ax2, real(p), imag(p), 80, colors(k,:), 'x', 'LineWidth', 2, 'DisplayName', labels{k});
end
yline(ax1, 1, ':', '目标值', 'HandleVisibility', 'off');
xlabel(ax1, '时间 / s'); ylabel(ax1, '输出');
title(ax1, '单位负反馈下，不同闭环极点对应不同阶跃响应');
legend(ax1, 'Location', 'southeast');
xline(ax2, 0, '--', '虚轴：稳定边界', 'HandleVisibility', 'off');
yline(ax2, 0, ':', 'HandleVisibility', 'off');
xlabel(ax2, '极点实部'); ylabel(ax2, '极点虚部');
title(ax2, '三个例子的闭环极点都位于左半平面');
legend(ax2, 'Location', 'southwest');
axis(ax2, 'equal'); xlim(ax2, [-3.5, 0.6]); ylim(ax2, [-3.5, 3.5]);
exportgraphics(fig, fullfile(output_dir, 'feedback-poles-and-step-response.png'), 'Resolution', 180);
close(fig);

fid = fopen(fullfile(script_dir, 'transfer_function_results.txt'), 'w');
fprintf(fid, 'RL series theoretical model\nR = 10 ohm\nL = 0.01 H\ntau = 0.001 s\n');
fprintf(fid, 'G_RL(s) = I(s)/U(s) = 1/(L*s+R)\n');
fprintf(fid, 'pole = -R/L = -1000 rad/s\ncorner frequency = 159.1549 Hz\n');
fclose(fid);
