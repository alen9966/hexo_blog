% generate_am_blog_figures.m
% 为《从一段声音到无线电波：AM 调制与解调入门》生成理论示意图与 PDF 局部图。
% 理论参数：fm = 1 kHz，fc = 20 kHz，采样率 fs = 2 MHz。
% 输出图片均为软件生成或基于培训 PDF 的局部裁剪，不代表硬件实测。

clear; close all; clc;

scriptDir = fileparts(mfilename('fullpath'));
repoDir = fullfile(scriptDir, '..', '..');
outputDir = fullfile(repoDir, 'source', 'images', 'myimge', 'am-modulation');
pdfPageDir = fullfile(repoDir, 'tmp', 'pdfs', 'am-training');

if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

set(groot, 'defaultAxesFontName', 'Microsoft YaHei');
set(groot, 'defaultTextFontName', 'Microsoft YaHei');

% 统一教学模型：单音基带、20 倍载波频率、调制度 0.5。
fm = 1e3;             % Hz，基带频率
fc = 20e3;            % Hz，载波频率
fs = 2e6;             % Hz，离散仿真采样率
mu = 0.5;             % 无量纲，调制度
t = 0:1/fs:3/fm;      % s，显示 3 个基带周期
baseband = cos(2*pi*fm*t);
carrier = cos(2*pi*fc*t);
am = (1 + mu*baseband) .* carrier;
envelope = 1 + mu*baseband;

makeBasebandCarrier(outputDir, t, baseband, carrier, fm, fc);
makeAmWaveformSpectrum(outputDir, t, am, envelope, fm, fc, mu);
makeModulationIndexComparison(outputDir, t, baseband, carrier, mu);
makeCoherentDemodulation(outputDir, t, am, baseband, fm, fc, mu);
makeEnvelopeFigures(outputDir, t, fm, fc, fs, mu);
makePdfCrops(pdfPageDir, outputDir);

fprintf('AM 博客图片已生成到：%s\n', outputDir);

function makeBasebandCarrier(outputDir, t, baseband, carrier, fm, fc)
fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1400 760]);
tl = tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
title(tl, sprintf('理论示意：基带与载波（f_m = %.0f Hz，f_c = %.0f Hz）', fm, fc));

nexttile;
plot(t*1e3, baseband, 'LineWidth', 1.5, 'Color', [0.10 0.35 0.75]);
grid on; ylim([-1.15 1.15]);
xlabel('时间 / ms'); ylabel('归一化幅度'); title('基带信号 m(t)');

nexttile;
window = t <= 0.35e-3;
plot(t(window)*1e3, carrier(window), 'LineWidth', 1.2, 'Color', [0.85 0.25 0.10]);
grid on; ylim([-1.15 1.15]);
xlabel('时间 / ms'); ylabel('归一化幅度'); title('载波信号 c(t)（局部放大）');

exportgraphics(fig, fullfile(outputDir, 'am-baseband-carrier.png'), 'Resolution', 180);
close(fig);
end

function makeAmWaveformSpectrum(outputDir, t, am, envelope, fm, fc, mu)
fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1450 860]);
tl = tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
title(tl, sprintf('理论示意：单音 AM 波形与频谱（m_a = %.1f）', mu));

nexttile;
plot(t*1e3, am, 'Color', [0.15 0.35 0.75], 'LineWidth', 0.8); hold on;
plot(t*1e3, envelope, '--', 'Color', [0.85 0.15 0.12], 'LineWidth', 1.4);
plot(t*1e3, -envelope, '--', 'Color', [0.85 0.15 0.12], 'LineWidth', 1.4);
grid on; xlabel('时间 / ms'); ylabel('归一化幅度');
legend('AM 已调信号', '包络', 'Location', 'best');
title('时域：高频载波的幅度随基带变化');

nexttile;
freqs = [fc-fm, fc, fc+fm] / 1e3;
amps = [mu/2, 1, mu/2];
stem(freqs, amps, 'filled', 'LineWidth', 1.4, 'Color', [0.15 0.35 0.75]);
grid on; xlim([(fc-2.2*fm)/1e3, (fc+2.2*fm)/1e3]); ylim([0 1.15]);
xlabel('频率 / kHz'); ylabel('相对幅度');
xticks(freqs); xticklabels({'f_c-f_m', 'f_c', 'f_c+f_m'});
title('频域：下边带、载波与上边带');

exportgraphics(fig, fullfile(outputDir, 'am-waveform-spectrum.png'), 'Resolution', 180);
close(fig);
end

function makeModulationIndexComparison(outputDir, t, baseband, carrier, mu)
mus = [mu, 1, 1.2];
labels = {'m_a = 0.5：正常调幅', 'm_a = 1：包络触及零点', 'm_a = 1.2：过调'};
fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1450 980]);
tl = tiledlayout(3, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
title(tl, '理论示意：不同调制度下的 AM 波形');

for k = 1:numel(mus)
    currentMu = mus(k);
    signal = (1 + currentMu*baseband) .* carrier;
    env = 1 + currentMu*baseband;
    nexttile;
    plot(t*1e3, signal, 'Color', [0.15 0.35 0.75], 'LineWidth', 0.7); hold on;
    plot(t*1e3, env, '--', 'Color', [0.85 0.15 0.12], 'LineWidth', 1.2);
    plot(t*1e3, -env, '--', 'Color', [0.85 0.15 0.12], 'LineWidth', 1.2);
    grid on; ylim([-2.5 2.5]); xlabel('时间 / ms'); ylabel('归一化幅度');
    title(labels{k});
end

exportgraphics(fig, fullfile(outputDir, 'am-modulation-index-comparison.png'), 'Resolution', 180);
close(fig);
end

function makeCoherentDemodulation(outputDir, t, am, baseband, fm, fc, mu)
localCarrier = cos(2*pi*fc*t);
product = am .* localCarrier;
recovered = mu/2 * baseband;
fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1450 900]);
tl = tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
title(tl, '理论示意：相干解调中的乘法与低通恢复');

nexttile;
window = t <= 0.35e-3;
plot(t(window)*1e3, product(window), 'Color', [0.15 0.35 0.75], 'LineWidth', 0.9);
grid on; xlabel('时间 / ms'); ylabel('归一化幅度');
title('乘法器输出：同时包含低频基带、直流与 2f_c 附近高频分量');

nexttile;
plot(t*1e3, recovered, 'Color', [0.85 0.15 0.12], 'LineWidth', 1.6); hold on;
plot(t*1e3, mu/2*baseband, '--', 'Color', [0.10 0.10 0.10], 'LineWidth', 0.9);
grid on; xlabel('时间 / ms'); ylabel('归一化幅度');
legend('低通并去直流后的基带', '理论基带比例', 'Location', 'best');
title('低通后：保留与原基带同频的低频成分');

exportgraphics(fig, fullfile(outputDir, 'am-coherent-demodulation.png'), 'Resolution', 180);
close(fig);
end

function makeEnvelopeFigures(outputDir, t, fm, fc, fs, mu)
baseband = cos(2*pi*fm*t);
biased = 2 + baseband;
amBiased = biased .* cos(2*pi*fc*t);

fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1450 760]);
tl = tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
title(tl, '理论示意：加直流分量后的 AM 包络');
nexttile;
plot(t*1e3, baseband, 'LineWidth', 1.4, 'Color', [0.15 0.35 0.75]); hold on;
plot(t*1e3, biased, 'LineWidth', 1.4, 'Color', [0.85 0.15 0.12]);
grid on; xlabel('时间 / ms'); ylabel('幅度'); legend('m(t)', '2+m(t)', 'Location', 'best');
title('加直流分量后，调制信号始终为正');
nexttile;
plot(t*1e3, amBiased, 'Color', [0.15 0.35 0.75], 'LineWidth', 0.7); hold on;
plot(t*1e3, biased, '--', 'Color', [0.85 0.15 0.12], 'LineWidth', 1.3);
plot(t*1e3, -biased, '--', 'Color', [0.85 0.15 0.12], 'LineWidth', 1.3);
grid on; xlabel('时间 / ms'); ylabel('幅度'); title('已调信号的正包络就是 2+m(t)');
exportgraphics(fig, fullfile(outputDir, 'am-envelope-basics.png'), 'Resolution', 180);
close(fig);

time = 0:1/fs:3/fm;
inputAm = (1 + mu*cos(2*pi*fm*time)) .* cos(2*pi*fc*time);
trueEnvelope = 1 + mu*cos(2*pi*fm*time);
good = peakDetector(inputAm, 120e-6, 1/fs);
slow = peakDetector(inputAm, 900e-6, 1/fs);
fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1450 900]);
tl = tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
title(tl, '软件仿真：包络检波的 RC 跟随与惰性失真');
nexttile;
plot(time*1e3, inputAm, 'Color', [0.70 0.75 0.85], 'LineWidth', 0.5); hold on;
plot(time*1e3, trueEnvelope, '--', 'Color', [0.10 0.10 0.10], 'LineWidth', 1.1);
plot(time*1e3, good, 'Color', [0.15 0.55 0.25], 'LineWidth', 1.4);
grid on; xlabel('时间 / ms'); ylabel('归一化幅度');
legend('AM 输入', '理想包络', '检波电容电压', 'Location', 'best');
title('RC 合理时：快速充电、相邻峰值之间缓慢放电');
nexttile;
plot(time*1e3, inputAm, 'Color', [0.70 0.75 0.85], 'LineWidth', 0.5); hold on;
plot(time*1e3, trueEnvelope, '--', 'Color', [0.10 0.10 0.10], 'LineWidth', 1.1);
plot(time*1e3, slow, 'Color', [0.85 0.15 0.12], 'LineWidth', 1.4);
grid on; xlabel('时间 / ms'); ylabel('归一化幅度');
legend('AM 输入', '理想包络', '检波电容电压', 'Location', 'best');
title('RC 过大时：电容放电过慢，产生惰性失真');
exportgraphics(fig, fullfile(outputDir, 'am-envelope-rc-tracking.png'), 'Resolution', 180);
close(fig);
end

function out = peakDetector(inputSignal, tau, dt)
out = zeros(size(inputSignal));
for k = 2:numel(inputSignal)
    discharged = out(k-1) * exp(-dt/tau);
    out(k) = max(inputSignal(k), discharged);
end
end

function makePdfCrops(pdfPageDir, outputDir)
% 页面 PNG 由 PDF 栅格化得到，仅作为 MATLAB 裁剪的输入；以下数字均为像素坐标。
exportCrop(fullfile(pdfPageDir, 'page-05.png'), fullfile(outputDir, 'pdf-signal-spectrum.png'), [55 380 1130 910]);
exportCrop(fullfile(pdfPageDir, 'page-10.png'), fullfile(outputDir, 'pdf-communication-system.png'), [50 1010 1140 450]);
exportCrop(fullfile(pdfPageDir, 'page-11.png'), fullfile(outputDir, 'pdf-analog-rf-section.png'), [45 35 1140 320]);
exportCrop(fullfile(pdfPageDir, 'page-11.png'), fullfile(outputDir, 'pdf-digital-rf-section.png'), [45 430 1140 500]);
exportCrop(fullfile(pdfPageDir, 'page-28.png'), fullfile(outputDir, 'pdf-coherent-demodulation-model.png'), [45 900 1140 650]);
exportCrop(fullfile(pdfPageDir, 'page-33.png'), fullfile(outputDir, 'pdf-envelope-detector.png'), [45 150 520 820]);
exportCrop(fullfile(pdfPageDir, 'page-34.png'), fullfile(outputDir, 'pdf-envelope-inertia-distortion.png'), [45 45 1140 790]);
exportCrop(fullfile(pdfPageDir, 'page-34.png'), fullfile(outputDir, 'pdf-envelope-bottom-clipping.png'), [45 980 1140 640]);
end

function exportCrop(inputPath, outputPath, rect)
if ~exist(inputPath, 'file')
    error('缺少 PDF 页面输入：%s', inputPath);
end
imageData = imread(inputPath);
x1 = max(1, round(rect(1)));
y1 = max(1, round(rect(2)));
x2 = min(size(imageData, 2), x1 + round(rect(3)) - 1);
y2 = min(size(imageData, 1), y1 + round(rect(4)) - 1);
cropped = imageData(y1:y2, x1:x2, :);
imwrite(cropped, outputPath);
end
