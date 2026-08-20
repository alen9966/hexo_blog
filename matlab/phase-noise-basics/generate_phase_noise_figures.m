%% MATLAB figures for phase-noise definition / measurement-math article.
% All curves are theoretical models for teaching, not hardware measurements.

clear; close all; clc;
rng(7);

script_dir = fileparts(mfilename('fullpath'));
project_dir = fileparts(fileparts(script_dir));
output_dir = fullfile(project_dir, 'source', 'images', 'myimge', 'phase-noise-basics');
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

set(groot, 'defaultAxesFontName', 'Microsoft YaHei', ...
    'defaultTextFontName', 'Microsoft YaHei', ...
    'defaultAxesFontSize', 11, 'defaultLineLineWidth', 1.8);

f0 = 100e6; % 100 MHz carrier for examples

%% Shared power-law OCXO model: L(f) = sum h_a * f^a, a = -2..+2
% Coefficients chosen to look like a clean ULPN 100 MHz OCXO (illustrative).
h = containers.Map('KeyType','double','ValueType','double');
h(-2) = 1.0e-4;   % random-walk FM
h(-1) = 2.5e-8;   % flicker FM
h(0)  = 3.0e-15;  % white FM floor
h(1)  = 1.0e-18;  % flicker PM
h(2)  = 5.0e-23;  % white PM

f = logspace(0, 6, 1200); % 1 Hz .. 1 MHz offset
Lf = zeros(size(f));
for a = -2:2
    Lf = Lf + h(a) .* f.^a;
end
Lf_dBc = 10*log10(Lf);

save_png = @(fig, name) exportgraphics(fig, fullfile(output_dir, name), 'Resolution', 180);

%% Fig01 — ideal vs phase-perturbed sinusoid zero crossings
N = 4000;
fs = 20 * f0;                 % oversample for drawing only
t = (0:N-1)/fs;
% Slow random-walk-like phase (illustrative, not a calibrated process)
phi = 0.35 * cumsum(randn(1, N)) / sqrt(N);
phi = phi - mean(phi);
v_ideal = cos(2*pi*f0*t);
v_real  = cos(2*pi*f0*t + phi);

% Zoom around a few cycles for readability
n0 = round(0.35*N);
n1 = n0 + round(12/f0*fs);
idx = n0:n1;

fig = figure('Color','w','Position',[60 60 1100 520]);
tiledlayout(2,1,'TileSpacing','compact','Padding','compact');
ax1 = nexttile; hold(ax1,'on'); grid(ax1,'on');
plot(ax1, (t(idx)-t(idx(1)))*1e9, v_ideal(idx), 'Color',[0.20 0.45 0.85]);
plot(ax1, (t(idx)-t(idx(1)))*1e9, v_real(idx),  'Color',[0.88 0.30 0.34]);
yline(ax1, 0, ':', 'HandleVisibility','off');
ylabel(ax1, '幅度 / a.u.');
title(ax1, '理想载波 vs 带 \phi(t) 的实际波形（局部放大）');
legend(ax1, {'理想 100 MHz', '含相位抖动'}, 'Location','northeast');

ax2 = nexttile; hold(ax2,'on'); grid(ax2,'on');
plot(ax2, (t(idx)-t(idx(1)))*1e9, phi(idx)*1e3, 'Color',[0.10 0.62 0.46]);
xlabel(ax2, '时间 / ns'); ylabel(ax2, '\phi(t) / mrad');
title(ax2, '同一窗口内的随机相位过程（过零抖动来源）');
save_png(fig, 'fig01_phase_jitter_time_domain.png'); close(fig);

%% Fig02 — L(f) definition: carrier vs 1 Hz noise slice + spur
fig = figure('Color','w','Position',[60 60 1100 520]);
hold on; grid on;
% Synthetic spectrum sketch around carrier
f_plot = linspace(-30e3, 30e3, 4000);
% Carrier line + soft skirts + one CW spur
skirt = 10.^((-80 - 20*log10(1 + abs(f_plot)/300))/10);
carrier = zeros(size(f_plot));
[~, ic] = min(abs(f_plot));
carrier(ic) = 1;
spur_f = 12e3;
[~, is] = min(abs(f_plot - spur_f));
spur = zeros(size(f_plot)); spur(is) = 10^(-55/10);
P = carrier + skirt + spur;
semilogy(f_plot/1e3, P, 'Color',[0.15 0.35 0.75]);
set(gca,'YScale','log');
% Mark 1 Hz bin at +10 kHz
f_mark = 10e3;
yl = ylim;
patch([f_mark-0.5 f_mark+0.5 f_mark+0.5 f_mark-0.5]/1e3, ...
      [yl(1) yl(1) yl(2) yl(2)], [1 0.85 0.2], ...
      'FaceAlpha', 0.35, 'EdgeColor','none');
xline(0, '--', '载波 f_0', 'LabelVerticalAlignment','bottom');
xline(spur_f/1e3, ':', '杂散（dBc，无 /Hz）', 'LabelVerticalAlignment','top');
text(10.8, 3e-7, {'1 Hz ENBW', '→ dBc/Hz'}, 'Color',[0.55 0.35 0.05]);
xlabel('相对载波的频率偏移 / kHz');
ylabel('相对功率 / a.u.（对数）');
title('ℒ(f)：偏移处 1 Hz 噪声功率 ÷ 载波功率（杂散只写 dBc）');
xlim([-30 30]);
save_png(fig, 'fig02_Lf_definition_and_spurs.png'); close(fig);

%% Fig03 — slope regions + RMS integral window
fig = figure('Color','w','Position',[60 60 1100 560]);
semilogx(f, Lf_dBc, 'Color',[0.12 0.39 0.82]); hold on; grid on;
f_low = 12; f_high = 20e3;
yl = ylim;
patch([f_low f_high f_high f_low], [yl(1) yl(1) yl(2) yl(2)], ...
    [0.85 0.93 1.0], 'EdgeColor','none', 'FaceAlpha', 0.7);
semilogx(f, Lf_dBc, 'Color',[0.12 0.39 0.82], 'LineWidth', 2.2);
xline(f_low, '--', 'f_{low}', 'LabelVerticalAlignment','bottom');
xline(f_high, '--', 'f_{high}', 'LabelVerticalAlignment','bottom');
text(80, max(Lf_dBc)-8, {'RMS 抖动积分窗口', '\Delta\phi_{rms}^2 = 2 ∫ L(f) df'}, ...
    'BackgroundColor','w', 'EdgeColor',[0.7 0.7 0.7]);
% slope callouts
text(3, interp1(f,Lf_dBc,3)+3, '-40 dB/dec', 'Color',[0.5 0.2 0.2]);
text(200, interp1(f,Lf_dBc,200)+3, '-20 dB/dec', 'Color',[0.5 0.2 0.2]);
text(8e4, interp1(f,Lf_dBc,8e4)+3, '远端平台 / 白 PM', 'Color',[0.2 0.35 0.2]);
xlabel('偏移频率 f / Hz'); ylabel('ℒ(f) / dBc·Hz^{-1}');
title('典型 OCXO 相噪分区与 RMS 抖动积分带宽');
xlim([1 1e6]);
save_png(fig, 'fig03_slope_regions_and_rms_integral.png'); close(fig);

%% Fig04 — five power-law terms and sum
fig = figure('Color','w','Position',[60 60 1100 560]);
hold on; grid on;
cols = lines(5);
alphas = -2:2;
names = {'随机游走 FM (f^{-2})','闪烁 FM (f^{-1})','白 FM (f^{0})','闪烁 PM (f^{+1})','白 PM (f^{+2})'};
for k = 1:5
    a = alphas(k);
    term = 10*log10(h(a) .* f.^a);
    semilogx(f, term, '--', 'Color', cols(k,:), 'DisplayName', names{k});
end
semilogx(f, Lf_dBc, 'k', 'LineWidth', 2.4, 'DisplayName', '五段叠加 ℒ(f)');
xlabel('偏移频率 f / Hz'); ylabel('功率谱密度 / dBc·Hz^{-1}');
title('幂律五分区分解与合成曲线');
legend('Location','southwest');
xlim([1 1e6]); ylim([min(Lf_dBc)-15, max(Lf_dBc)+5]);
set(gca,'XScale','log');
save_png(fig, 'fig04_power_law_decomposition.png'); close(fig);

%% Fig05 — L(f) slopes vs Allan deviation slopes
tau = logspace(-4, 2, 400); % 0.1 ms .. 100 s
% Approximate asymptotic sigma_y for each pure power-law term (illustrative scale)
% Using textbook slope mapping with arbitrary absolute levels for teaching.
sig = struct();
sig.rwfm = 3e-11 * tau.^1;          % L ~ f^-2 → σ ~ τ^{+1}
sig.ffm  = 8e-12 * tau.^0;          % L ~ f^-1 → σ ~ τ^{0}
sig.wfm  = 2e-12 * tau.^(-0.5);     % L ~ f^0  → σ ~ τ^{-1/2}
sig.fpm  = 6e-13 * tau.^(-1);       % L ~ f^+1 → σ ~ τ^{-1}
sig.wpm  = 2e-13 * tau.^(-1.5);     % L ~ f^+2 → σ ~ τ^{-3/2}

fig = figure('Color','w','Position',[60 60 1180 560]);
tiledlayout(1,2,'TileSpacing','compact','Padding','compact');
ax1 = nexttile; hold(ax1,'on'); grid(ax1,'on'); set(ax1,'XScale','log');
semilogx(ax1, f, 10*log10(h(-2)*f.^(-2)), 'DisplayName','f^{-2}');
semilogx(ax1, f, 10*log10(h(-1)*f.^(-1)), 'DisplayName','f^{-1}');
semilogx(ax1, f, 10*log10(h(0)*f.^(0)),   'DisplayName','f^{0}');
semilogx(ax1, f, 10*log10(h(1)*f.^(1)),   'DisplayName','f^{+1}');
semilogx(ax1, f, 10*log10(h(2)*f.^(2)),   'DisplayName','f^{+2}');
xlabel(ax1,'f / Hz'); ylabel(ax1,'ℒ(f) / dBc·Hz^{-1}');
title(ax1,'各幂律项的 ℒ(f) 斜率'); legend(ax1,'Location','southwest');

ax2 = nexttile; hold(ax2,'on'); grid(ax2,'on'); set(ax2,'XScale','log','YScale','log');
loglog(ax2, tau, sig.rwfm, 'DisplayName','σ_y ∝ τ^{+1}');
loglog(ax2, tau, sig.ffm,  'DisplayName','σ_y ∝ τ^{0}（平台）');
loglog(ax2, tau, sig.wfm,  'DisplayName','σ_y ∝ τ^{-1/2}');
loglog(ax2, tau, sig.fpm,  'DisplayName','σ_y ∝ τ^{-1}');
loglog(ax2, tau, sig.wpm,  'DisplayName','σ_y ∝ τ^{-3/2}');
xlabel(ax2,'平均时间 τ / s'); ylabel(ax2,'σ_y(τ)');
title(ax2,'对应的阿伦偏差斜率'); legend(ax2,'Location','southwest');
save_png(fig, 'fig05_Lf_vs_allan_deviation.png'); close(fig);

%% Fig06 — direct spectrum method ceilings (LO / AM)
L_dut = Lf_dBc;
L_lo  = Lf_dBc + 8;                 % LO worse by ~8 dB (illustrative)
L_am  = -140 + 10*log10(1 + (f/3e3).^2); % rising AM floor sketch
L_meas = 10*log10(10.^(L_dut/10) + 10.^(L_lo/10) + 10.^(L_am/10));

fig = figure('Color','w','Position',[60 60 1100 560]);
semilogx(f, L_dut, 'Color',[0.12 0.39 0.82], 'DisplayName','DUT 真实 ℒ'); hold on; grid on;
semilogx(f, L_lo,  '--', 'Color',[0.85 0.45 0.10], 'DisplayName','仪器 LO 相噪');
semilogx(f, L_am,  ':',  'Color',[0.20 0.65 0.35], 'DisplayName','AM 噪声折合');
semilogx(f, L_meas,'k', 'LineWidth',2.2, 'DisplayName','直接频谱读数 ≈ max 合成');
xlabel('偏移频率 f / Hz'); ylabel('dBc·Hz^{-1}');
title('直接频谱法：被 LO 相噪与 AM 噪声抬高的测量天花板');
legend('Location','southwest'); xlim([1 1e6]);
save_png(fig, 'fig06_direct_spectrum_ceiling.png'); close(fig);

%% Fig07 — analog vs digital I/Q block diagram
fig = figure('Color','w','Position',[60 60 1180 620]);
axis off; xlim([0 1]); ylim([0 1]);
title('模拟 I/Q（FSWP 类）与数字 I/Q（53100A 类）架构对比', 'FontSize', 14);

% Left: analog
rectangle('Position',[0.03 0.12 0.44 0.78], 'Curvature',0.04, 'EdgeColor',[0.2 0.4 0.8], 'LineWidth',1.5);
text(0.25, 0.86, '模拟 I/Q 解调', 'HorizontalAlignment','center', 'FontWeight','bold', 'FontSize',13);
draw_box(0.08,0.68,0.14,0.10,'DUT RF');
draw_box(0.28,0.68,0.14,0.10,'LO');
draw_box(0.08,0.48,0.16,0.10,'混频 I');
draw_box(0.28,0.48,0.16,0.10,'混频 Q (90°)');
draw_box(0.08,0.30,0.16,0.10,'LPF + ADC');
draw_box(0.28,0.30,0.16,0.10,'LPF + ADC');
draw_box(0.16,0.14,0.18,0.10,'atan2 / |·|');
annotation('arrow',[0.15 0.15],[0.68 0.58]);
annotation('arrow',[0.35 0.35],[0.68 0.58]);
annotation('arrow',[0.16 0.16],[0.48 0.40]);
annotation('arrow',[0.36 0.36],[0.48 0.40]);
annotation('arrow',[0.16 0.22],[0.30 0.24]);
annotation('arrow',[0.36 0.30],[0.30 0.24]);
text(0.25, 0.05, '正交在模拟域完成', 'HorizontalAlignment','center', 'Color',[0.25 0.25 0.55]);

% Right: digital
rectangle('Position',[0.53 0.12 0.44 0.78], 'Curvature',0.04, 'EdgeColor',[0.8 0.35 0.25], 'LineWidth',1.5);
text(0.75, 0.86, '数字 I/Q 解调', 'HorizontalAlignment','center', 'FontWeight','bold', 'FontSize',13);
draw_box(0.58,0.68,0.14,0.10,'DUT RF');
draw_box(0.78,0.68,0.14,0.10,'本振/下变频');
draw_box(0.64,0.48,0.22,0.10,'固定 IF + ADC');
draw_box(0.58,0.30,0.16,0.10,'数字 0°');
draw_box(0.78,0.30,0.16,0.10,'数字 90°');
draw_box(0.66,0.14,0.18,0.10,'atan2 / |·|');
annotation('arrow',[0.65 0.72],[0.68 0.58]);
annotation('arrow',[0.85 0.78],[0.68 0.58]);
annotation('arrow',[0.72 0.66],[0.48 0.40]);
annotation('arrow',[0.78 0.86],[0.48 0.40]);
annotation('arrow',[0.66 0.72],[0.30 0.24]);
annotation('arrow',[0.86 0.78],[0.30 0.24]);
text(0.75, 0.05, '正交在数字域校准，幅相更稳', 'HorizontalAlignment','center', 'Color',[0.55 0.25 0.15]);
save_png(fig, 'fig07_analog_vs_digital_iq.png'); close(fig);

%% Fig08 — PLL + double-balanced mixer
fig = figure('Color','w','Position',[60 60 1100 560]);
axis off; xlim([0 1]); ylim([0 1]);
title('PLL + 双平衡混频鉴相测量链', 'FontSize', 14);
draw_box(0.06,0.62,0.16,0.12,'DUT');
draw_box(0.06,0.28,0.16,0.12,'REF（可调谐）');
draw_box(0.32,0.45,0.22,0.14,'双平衡混频器');
draw_box(0.62,0.62,0.16,0.12,'LPF');
draw_box(0.84,0.62,0.12,0.12,'FFT / ℒ(f)');
draw_box(0.62,0.28,0.16,0.12,'环路滤波');
draw_box(0.84,0.28,0.12,0.12,'调谐电压');
annotation('arrow',[0.22 0.32],[0.68 0.56]);
annotation('arrow',[0.22 0.32],[0.34 0.48]);
annotation('arrow',[0.54 0.62],[0.52 0.68]);
annotation('arrow',[0.78 0.84],[0.68 0.68]);
annotation('arrow',[0.54 0.62],[0.48 0.34]);
annotation('arrow',[0.78 0.84],[0.34 0.34]);
annotation('arrow',[0.90 0.14],[0.28 0.28]); % feedback to REF
text(0.48, 0.18, '锁定在 \Delta\phi ≈ \pi/2；基带 ∝ \Delta\phi；f_{BW} ≪ f_{low}', ...
    'HorizontalAlignment','center', 'BackgroundColor','w', 'EdgeColor',[0.7 0.7 0.7]);
text(0.48, 0.08, 'AM 在双平衡结构中被抑制，主要保留相位差信息', ...
    'HorizontalAlignment','center', 'Color',[0.35 0.35 0.35]);
save_png(fig, 'fig08_pll_double_balanced_mixer.png'); close(fig);

%% Fig09a — single-reference ceiling
L_ref = Lf_dBc + 18; % REF much worse near carrier
L_single = 10*log10(10.^(Lf_dBc/10) + 10.^(L_ref/10));
fig = figure('Color','w','Position',[60 60 1100 560]);
semilogx(f, Lf_dBc, 'Color',[0.12 0.39 0.82], 'DisplayName','DUT 真实 ℒ'); hold on; grid on;
semilogx(f, L_ref, '--', 'Color',[0.85 0.40 0.15], 'DisplayName','单参考源 REF');
semilogx(f, L_single, 'k', 'LineWidth',2.2, 'DisplayName','单参考读数');
yl = ylim;
mask = f <= 1e3;
patch([f(mask) fliplr(f(mask))], ...
      [L_ref(mask) fliplr(ones(size(f(mask)))*yl(1))], ...
      [1.0 0.90 0.85], 'EdgeColor','none', 'FaceAlpha',0.55, 'HandleVisibility','off');
semilogx(f, Lf_dBc, 'Color',[0.12 0.39 0.82]);
semilogx(f, L_ref, '--', 'Color',[0.85 0.40 0.15]);
semilogx(f, L_single, 'k', 'LineWidth',2.2);
text(20, max(L_ref)-6, {'阴影区：被 REF 盖住', '读不到更干净的 DUT'}, ...
    'BackgroundColor','w', 'EdgeColor',[0.7 0.7 0.7]);
xlabel('偏移频率 f / Hz'); ylabel('dBc·Hz^{-1}');
title('单参考测量的硬天花板');
legend('Location','southwest'); xlim([1 1e6]);
save_png(fig, 'fig09a_single_reference_ceiling.png'); close(fig);

%% Fig09b — dual-reference cross-correlation improvement with M
M_list = [1 10 100 1000];
fig = figure('Color','w','Position',[60 60 1100 560]);
semilogx(f, Lf_dBc, 'k', 'LineWidth',2.4, 'DisplayName','DUT 真实 ℒ'); hold on; grid on;
colsM = [0.80 0.25 0.25; 0.85 0.50 0.15; 0.20 0.55 0.75; 0.15 0.65 0.35];
for i = 1:numel(M_list)
    M = M_list(i);
    % Residual REF/channel noise falls ~ 1/sqrt(M) in power (illustrative)
    L_resid = 10*log10( (10.^(L_ref/10) + 10.^(L_ref/10)) / sqrt(M) );
    L_xc = 10*log10(10.^(Lf_dBc/10) + 10.^(L_resid/10));
    semilogx(f, L_xc, 'Color', colsM(i,:), 'DisplayName', sprintf('互相关 M=%d', M));
end
xlabel('偏移频率 f / Hz'); ylabel('dBc·Hz^{-1}');
title('双参考互相关：M×10，残余参考噪声约 ÷√10');
legend('Location','southwest'); xlim([1 1e6]);
save_png(fig, 'fig09b_dual_reference_cross_correlation.png'); close(fig);

%% Fig10 — four instruments vs same DUT (principle model, not lab data)
% Different internal REF levels + same M=100 cross-correlation residual
M = 100;
ref_off_db = [12 15 18 22]; % relative REF floors
names_inst = {'FSWP 类','53100A 类','HA7402B 类','E5052B 类（单参考偏高）'};
colsI = lines(4);
fig = figure('Color','w','Position',[60 60 1100 560]);
semilogx(f, Lf_dBc, 'k', 'LineWidth',2.6, 'DisplayName','DUT 真值（模型）'); hold on; grid on;
for i = 1:4
    L_r = Lf_dBc + ref_off_db(i);
    if i < 4
        L_resid = 10*log10(2*10.^(L_r/10)/sqrt(M));
    else
        % single-ref style: little cross-correlation benefit
        L_resid = L_r;
    end
    L_m = 10*log10(10.^(Lf_dBc/10) + 10.^(L_resid/10));
    semilogx(f, L_m, 'Color', colsI(i,:), 'DisplayName', names_inst{i});
end
xlabel('偏移频率 f / Hz'); ylabel('dBc·Hz^{-1}');
title('同一只 ULPN OCXO：四类仪器读数示意（原理建模，非实测）');
legend('Location','southwest'); xlim([1 1e6]);
text(2e3, max(Lf_dBc)+8, 'M 足够大时曲线趋近 DUT 真值', ...
    'BackgroundColor','w', 'EdgeColor',[0.7 0.7 0.7]);
save_png(fig, 'fig10_four_instrument_comparison.png'); close(fig);

fprintf('Generated phase-noise figures into:\n%s\n', output_dir);
d = dir(fullfile(output_dir, 'fig*.png'));
for k = 1:numel(d)
    fprintf('  %s  (%d bytes)\n', d(k).name, d(k).bytes);
end

function draw_box(x, y, w, h, label)
rectangle('Position',[x y w h], 'Curvature',0.08, ...
    'FaceColor',[0.96 0.97 1.0], 'EdgeColor',[0.25 0.35 0.55], 'LineWidth',1.2);
text(x+w/2, y+h/2, label, 'HorizontalAlignment','center', ...
    'VerticalAlignment','middle', 'FontSize',11);
end
