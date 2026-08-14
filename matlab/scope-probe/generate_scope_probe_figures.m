%% MATLAB figures for the scope-probe / 1 MΩ vs 50 Ω loading article.
% All traces here are educational theoretical simulations, not hardware measurements.
% They are used to explain probe compensation, loading effects and transfer functions.

clear; close all; clc;

script_dir = fileparts(mfilename('fullpath'));
project_dir = fileparts(fileparts(script_dir));
output_dir = fullfile(project_dir, 'source', 'images', 'myimge', 'scope-probe-loading');
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

font_name = 'Microsoft YaHei';
set(groot, 'defaultAxesFontName', font_name, ...
    'defaultTextFontName', font_name, ...
    'defaultAxesFontSize', 11, ...
    'defaultLineLineWidth', 1.8);

colors = [0.12 0.39 0.82;   % 蓝：正确补偿 / 50Ω 端接
          0.10 0.62 0.46;   % 绿：欠补偿 / 1 MΩ 直接
          0.88 0.30 0.34];  % 红：过补偿 / 10× 探头

% -------------------------------------------------------------------------
%% 1. Passive 10x probe compensation: step responses (time domain)
% Circuit:
%   Tip:    R_tip = 9 MΩ  ||  C_tip (variable: under / correct / over)
%   Scope:  R_in  = 1 MΩ  ||  C_in  = 10 pF
%   Time-constant match condition: R_tip * C_tip = R_in * C_in
% -------------------------------------------------------------------------
s = tf('s');

R_tip = 9e6;
R_in  = 1e6;
C_in  = 10e-12;

C_tip_correct = (R_in / R_tip) * C_in;          % ~1.11 pF
C_tip_under   = 0.55 * C_tip_correct;           % 欠补偿：电容偏小 -> 数值上=低通->缓升
C_tip_over    = 2.20 * C_tip_correct;           % 过补偿：电容偏大 -> 数值上=高通->振铃

Z_tip_correct = 1 / (1/R_tip + s*C_tip_correct);
Z_in_correct  = 1 / (1/R_in  + s*C_in);
H_correct     = Z_in_correct / (Z_tip_correct + Z_in_correct);

Z_tip_under = 1 / (1/R_tip + s*C_tip_under);
H_under     = (1 / (1/R_in + s*C_in)) / (Z_tip_under + 1/(1/R_in + s*C_in));

Z_tip_over  = 1 / (1/R_tip + s*C_tip_over);
H_over      = (1 / (1/R_in + s*C_in)) / (Z_tip_over  + 1/(1/R_in + s*C_in));

% Simulate a 1 kHz 1 V square wave over ~4 periods, 1200 samples.
f_sq  = 1000;
T_sq  = 1 / f_sq;
t_end = 4 * T_sq;
dt    = t_end / 1200;
tt    = 0 : dt : t_end;
u_sq  = 0.5 * square(2*pi*f_sq*tt, 50) + 0.5;   % 0 -> 1 V square

y_correct = lsim(H_correct, u_sq, tt);
y_under   = lsim(H_under,   u_sq, tt);
y_over    = lsim(H_over,    u_sq, tt);

fig = figure('Color', 'w', 'Position', [80 80 1160 740]);
tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
ax1 = nexttile; hold(ax1, 'on'); grid(ax1, 'on');
ax2 = nexttile; hold(ax2, 'on'); grid(ax2, 'on');

plot(ax1, tt*1e3, u_sq, 'Color', 0.6*[1 1 1], 'LineStyle', ':', 'LineWidth', 1.4, ...
    'DisplayName', '输入 1 V 方波');
plot(ax1, tt*1e3, y_correct, 'Color', colors(1,:), 'DisplayName', '正确补偿：顶部平坦');
yline(ax1, 0.1, '--', '10× 探头 0.1 V 输出刻度（对应输入 1 V）', ...
    'LabelHorizontalAlignment', 'left', 'HandleVisibility', 'off');
xlabel(ax1, '时间 / ms'); ylabel(ax1, '屏显电压 / V');
title(ax1, '10× 无源探头接 1 kHz 方波：三种补偿状态的时域响应（MATLAB 理论仿真）');
legend(ax1, 'Location', 'southeast');
ylim(ax1, [-0.05 0.2]);

% Show a zoomed rising edge window (0..0.1 ms) for clarity.
zoom_mask = tt <= 0.25e-3;
plot(ax2, tt(zoom_mask)*1e6, u_sq(zoom_mask),  'Color', 0.6*[1 1 1], 'LineStyle', ':', 'LineWidth', 1.4, ...
    'DisplayName', '输入 1 V 方波');
plot(ax2, tt(zoom_mask)*1e6, y_correct(zoom_mask), 'Color', colors(1,:), ...
    'DisplayName', sprintf('正确补偿：C_{tip}=%.2g pF', C_tip_correct*1e12));
plot(ax2, tt(zoom_mask)*1e6, y_under(zoom_mask),   'Color', colors(2,:), ...
    'DisplayName', sprintf('欠补偿：C_{tip}=%.2g pF，顶部缓慢上翘', C_tip_under*1e12));
plot(ax2, tt(zoom_mask)*1e6, y_over(zoom_mask),    'Color', colors(3,:), ...
    'DisplayName', sprintf('过补偿：C_{tip}=%.2g pF，上升后过冲',  C_tip_over*1e12));
yline(ax2, 0.1, '--', '0.1 V 标称输出', 'LabelHorizontalAlignment', 'left', 'HandleVisibility', 'off');
xlabel(ax2, '时间 / μs（上升沿局部放大）'); ylabel(ax2, '屏显电压 / V');
title(ax2, '放大上升沿：欠补偿形成 RC 尾巴，过补偿形成 LC 式振铃过冲');
legend(ax2, 'Location', 'southeast');
xlim(ax2, [0 250]);

exportgraphics(fig, fullfile(output_dir, 'matlab-probe-compensation-step.png'), 'Resolution', 180);
close(fig);

% -------------------------------------------------------------------------
%% 2. Bode diagram: three different scope input paths vs a 100 MHz clock
% DUT output impedance  Z_out = 39 - j*0  Ω  (approx resistive for simplicity)
% Path A: SMA direct -> 50 Ω termination
% Path B: SMA direct -> 1 MΩ || 10 pF
% Path C: 10× compensated probe -> input
% -------------------------------------------------------------------------
Z_out_val = 39;    % Ω, from the dual-load measurement example

% A: 50 Ω termination (pure resistive)
Z_in_50R = 50;
H_50R   = tf(Z_in_50R, [Z_in_50R + Z_out_val]);   % real constant

% B: 1 MΩ || 10 pF
% Z_in_1M(s) = 1 / (1/R_in + s*C_in)
R1 = 1e6;
C1 = 10e-12;
% H = Z_in / (Z_out + Z_in),  multiply by (R_in C_in s + 1):
% num = R_in;  den = (Z_out + R_in) + Z_out R_in C_in * s
H_1M = tf(R1, [Z_out_val*R1*C1,  (Z_out_val + R1)]);

% C: 10x probe (correctly compensated) -> probe-side transfer function.
% Overall tip-to-scope H = Z_in / (Z_tip + Z_in) = 1/10 with constant.
% But DUT sees an equivalent input of ~ Z_tip_parallel + scope_input_parallel
% For correctly compensated probe, we can build equivalent tip impedance
% from the "10x" side:  R_tip_eq = 10 MΩ,  C_tip_eq = 1.0 pF
R_tip_eq = 10e6;
C_tip_eq = 1e-12;
% H_probe_tip_to_scope = equivalent divider through equivalent parallel.
Z_tip_eq_s = 1 / (1/R_tip_eq + s*C_tip_eq);
% Actual display = V(tip) scaled by 1/10. To compare Vs -> scope-display
% amplitude on same scale, return just the transfer function from Vs to
% display voltage (= 10x attenuation * correct-divider factor,  10x * 1/10 = 1)
% when |Z_tip_eq| >> Z_out. So H = [Z_tip_eq / (Z_out + Z_tip_eq)] * 1
% because probe display has already been multiplied by 10.
H_probe = Z_tip_eq_s / (Z_out_val + Z_tip_eq_s);

labels = {'SMA 直通 + 50 Ω 端接', ...
          'SMA 直通 + 1 MΩ 档（含 10 pF）', ...
          '10× 无源探头 + 1 MΩ 档（正确补偿）'};

w = 2*pi*logspace(4, 9, 2400);     % 10 kHz .. 1 GHz
f = w / (2*pi);

resp_50R   = squeeze(freqresp(H_50R,   w));
resp_1M    = squeeze(freqresp(H_1M,    w));
resp_probe = squeeze(freqresp(H_probe, w));

fig = figure('Color', 'w', 'Position', [80 80 1180 780]);
tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
ax1 = nexttile; hold(ax1, 'on'); grid(ax1, 'on'); set(ax1, 'XScale', 'log');
ax2 = nexttile; hold(ax2, 'on'); grid(ax2, 'on'); set(ax2, 'XScale', 'log');

semilogx(ax1, f, 20*log10(abs(resp_50R)),   'Color', colors(1,:), 'DisplayName', labels{1});
semilogx(ax1, f, 20*log10(abs(resp_1M)),    'Color', colors(2,:), 'DisplayName', labels{2});
semilogx(ax1, f, 20*log10(abs(resp_probe)), 'Color', colors(3,:), 'DisplayName', labels{3});
xline(ax1, 100e6, '--', '100 MHz（本次测试频点）', 'LabelVerticalAlignment', 'bottom', ...
    'HandleVisibility', 'off');
yline(ax1, -20*log10(2), ':', '3 dB 衰减线', 'LabelHorizontalAlignment', 'left', ...
    'HandleVisibility', 'off');
xlabel(ax1, '频率 / Hz'); ylabel(ax1, '屏显电压 vs 戴维南 Vs / dB');
title(ax1, '三种示波器接入方式的幅频特性：DUT Zout ≈ 39 Ω');
legend(ax1, 'Location', 'southwest');
xlim(ax1, [1e4 1e9]); ylim(ax1, [-16 2]);

semilogx(ax2, f, unwrap(angle(resp_50R))*180/pi,   'Color', colors(1,:), 'DisplayName', labels{1});
semilogx(ax2, f, unwrap(angle(resp_1M))*180/pi,    'Color', colors(2,:), 'DisplayName', labels{2});
semilogx(ax2, f, unwrap(angle(resp_probe))*180/pi, 'Color', colors(3,:), 'DisplayName', labels{3});
xline(ax2, 100e6, '--', '100 MHz（本次测试频点）', 'LabelVerticalAlignment', 'bottom', ...
    'HandleVisibility', 'off');
yline(ax2, 0, ':', 'HandleVisibility', 'off');
xlabel(ax2, '频率 / Hz'); ylabel(ax2, '相位 / (°)');
title(ax2, '相频特性：1 MΩ 直接档在 ~200 kHz 以后引入明显的容性相位滞后');
legend(ax2, 'Location', 'southwest');
xlim(ax2, [1e4 1e9]); ylim(ax2, [-90 10]);

exportgraphics(fig, fullfile(output_dir, 'matlab-three-input-paths-bode.png'), 'Resolution', 180);
close(fig);

% -------------------------------------------------------------------------
%% 3. Transfer function: error of simplified dual-load Zout estimation
%
% True reading  V_1M_true  = Vs * Z_in_1M / (Zout + Z_in_1M)
% Approximation V_1M_ideal = Vs
% So the "1 MΩ as open-circuit" approximation introduces an error:
%   error_magnitude = | V_1M_ideal / V_1M_true - 1 |
%   Zout_appx       = 50 * (V_1M_ideal/V_50 - 1)   % simplified dual-load
%   Zout_true       = 50 * (V_1M_true /V_50 - 1)   % corrected dual-load
% -------------------------------------------------------------------------
% Simulate over 10 kHz .. 1 GHz.
f_ex = logspace(4, 9, 800);
w_ex = 2*pi*f_ex;

Z_in_1M_s = 1 ./ (1/R1 + 1j*w_ex*C1);

% Assume Zout is a fixed 39 Ω (the "true" value we want to recover).
% The true 50Ω reading is independent of frequency in this simple model.
V_50 = (50 ./ (Z_out_val + 50)) * ones(size(f_ex));

V_1M_true_abs = abs(Z_in_1M_s ./ (Z_out_val + Z_in_1M_s));
V_1M_ideal_abs = ones(size(f_ex));

Zout_approx = 50 .* (V_1M_ideal_abs ./ abs(V_50) - 1);
Zout_true   = 50 .* (V_1M_true_abs  ./ abs(V_50) - 1);

err_pct = 100 * abs((Zout_approx - Zout_true) ./ Zout_true);

% Magnitude of effective input impedance in 1 MΩ mode.
abs_Zin = abs(Z_in_1M_s);

fig = figure('Color', 'w', 'Position', [80 80 1180 760]);
tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
ax1 = nexttile; hold(ax1, 'on'); grid(ax1, 'on'); set(ax1, 'XScale', 'log');
yyaxis(ax1, 'left');
semilogx(ax1, f_ex, Zout_true,   'Color', colors(1,:), 'LineWidth', 2.2, ...
    'DisplayName', '计入 C_{in}=10 pF 修正后的 Z_{out,true}（真值）');
semilogx(ax1, f_ex, Zout_approx, 'Color', colors(3,:), 'LineWidth', 2.0, 'LineStyle', '--', ...
    'DisplayName', '简化双负载法 Z_{out,appx}（把 1 MΩ 当理想开路）');
yline(ax1, 39, ':', '真实 Z_{out} = 39 Ω', 'LabelHorizontalAlignment', 'left', ...
    'HandleVisibility', 'off');
xline(ax1, 100e6, '--', '100 MHz（本次测试频点）', 'LabelVerticalAlignment', 'bottom', ...
    'HandleVisibility', 'off');
ylabel(ax1, '反推得到的输出阻抗 / Ω');
yyaxis(ax1, 'right');
semilogx(ax1, f_ex, abs_Zin/1e3, 'Color', colors(2,:), 'LineStyle', '-.', ...
    'DisplayName', '1 MΩ 档的等效输入阻抗模长 |Z_{in,1M}|（右轴）');
ylabel(ax1, '|Z_{in,1M}| / kΩ');
xlabel(ax1, '频率 / Hz');
title(ax1, '1 MΩ 输入电容如何让「简化双负载法」随频率逐渐失效');
legend(ax1, 'Location', 'southwest');
xlim(ax1, [1e4 1e9]);

ax2 = nexttile; hold(ax2, 'on'); grid(ax2, 'on'); set(ax2, 'XScale', 'log');
semilogx(ax2, f_ex, err_pct, 'Color', colors(3,:), 'LineWidth', 2.0);
xline(ax2, 100e6, '--', '100 MHz（本次测试频点）', 'LabelVerticalAlignment', 'bottom', ...
    'HandleVisibility', 'off');
yline(ax2, 5,  ':', '5 % 误差线',  'LabelHorizontalAlignment', 'left', 'HandleVisibility', 'off');
yline(ax2, 20, ':', '20 % 误差线', 'LabelHorizontalAlignment', 'left', 'HandleVisibility', 'off');
% Mark 100 MHz numerically
f_mark = 100e6;
err_mark = interp1(f_ex, err_pct, f_mark, 'linear');
plot(ax2, f_mark, err_mark, 'o', 'Color', colors(3,:), 'MarkerFaceColor', colors(3,:), ...
    'HandleVisibility', 'off');
text(ax2, 1.2e8, err_mark + 3, ...
    sprintf('100 MHz 处相对误差 ≈ %.1f %%', err_mark), ...
    'Color', colors(3,:), 'FontWeight', 'bold', 'BackgroundColor', 'w');
xlabel(ax2, '频率 / Hz'); ylabel(ax2, '| Z_{out,appx} - Z_{out,true} | / Z_{out,true}  (×100%)');
title(ax2, '简化双负载法随频率升高的相对误差曲线：Cin 导致误差随频率单调上升');
xlim(ax2, [1e4 1e9]);

exportgraphics(fig, fullfile(output_dir, 'matlab-dual-load-zout-error.png'), 'Resolution', 180);
close(fig);

% -------------------------------------------------------------------------
%% 4. Time-domain 100 MHz sine: what three setups show on screen
%  Superimpose a 100 MHz sine through the same three paths.
% -------------------------------------------------------------------------
f_sig = 100e6;
t_cycles = 5 / f_sig;          % 5 cycles
t_vec    = linspace(0, t_cycles, 1500);
vs_vec   = 2.00 * sin(2*pi*f_sig*t_vec);   % Vs = 2.00 Vpp open-circuit

y50   = lsim(H_50R,   vs_vec, t_vec);
y1M   = lsim(H_1M,    vs_vec, t_vec);
yprob = lsim(H_probe, vs_vec, t_vec);

fig = figure('Color', 'w', 'Position', [80 80 1160 720]);
tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
ax1 = nexttile; hold(ax1, 'on'); grid(ax1, 'on');
ax2 = nexttile; hold(ax2, 'on'); grid(ax2, 'on');

plot(ax1, t_vec*1e9, vs_vec, 'Color', 0.55*[1 1 1], 'LineStyle', ':', 'LineWidth', 1.4, ...
    'DisplayName', '理想戴维南开路电压 V_s（参考）');
plot(ax1, t_vec*1e9, y50,   'Color', colors(1,:), 'DisplayName', sprintf('50 Ω 端接：%.2f Vpp', 2*max(abs(y50))));
plot(ax1, t_vec*1e9, y1M,   'Color', colors(2,:), 'DisplayName', sprintf('1 MΩ 档：%.2f Vpp',   2*max(abs(y1M))));
plot(ax1, t_vec*1e9, yprob, 'Color', colors(3,:), 'DisplayName', sprintf('10× 探头：%.2f Vpp（等效至探头端）', 2*max(abs(yprob))));
xlabel(ax1, '时间 / ns'); ylabel(ax1, '屏显电压 / V');
title(ax1, '100 MHz 正弦：三种接入方式示波器屏显的 5 个周期波形对比（MATLAB 理论仿真）');
legend(ax1, 'Location', 'southeast');
xlim(ax1, [0 t_cycles*1e9]);

% Peak-to-peak bar chart
setups      = {'SMA+50 Ω', 'SMA+1 MΩ', '10× 探头'};
vpp_vals    = [2*max(abs(y50)), 2*max(abs(y1M)), 2*max(abs(yprob))];
theoretical = [1.12,           1.86,            1.92];

bh = bar(ax2, vpp_vals, 0.5, 'FaceColor', 'flat');
bh.CData = colors;
hold(ax2, 'on');
bh2 = bar(ax2, theoretical, 0.55, 'FaceColor', 'none', 'EdgeColor', 0.3*[1 1 1], ...
    'LineStyle', '--', 'LineWidth', 1.6, 'DisplayName', '文章中实测/推算值');
for k = 1:numel(vpp_vals)
    text(ax2, k, vpp_vals(k)+0.04, sprintf('%.2f V', vpp_vals(k)), ...
        'HorizontalAlignment', 'center', 'FontWeight', 'bold');
end
xticklabels(ax2, setups);
ylabel(ax2, '峰峰值 V_{pp} / V');
title(ax2, '三种方法 V_{pp} 数值对比：仿真结果与文中实测值（虚线）一致');
legend(ax2, bh2, '文章中实测/推算值', 'Location', 'northwest');
ylim(ax2, [0 2.3]);

exportgraphics(fig, fullfile(output_dir, 'matlab-100mhz-time-domain-three-setups.png'), 'Resolution', 180);
close(fig);

% -------------------------------------------------------------------------
%% Save numerical results
% -------------------------------------------------------------------------
result_file = fullfile(script_dir, 'scope_probe_loading_results.txt');
fid = fopen(result_file, 'w');
fprintf(fid, 'Educational scope probe / input-loading theoretical model\n');
fprintf(fid, 'R_in   = %.6g ohm\n', R1);
fprintf(fid, 'C_in   = %.6g F\n', C1);
fprintf(fid, 'R_tip  = %.6g ohm\n', R_tip);
fprintf(fid, 'C_tip  = correct=%.6g F   under=%.6g F   over=%.6g F\n', ...
    C_tip_correct, C_tip_under, C_tip_over);
fprintf(fid, 'Z_out  = %.6g ohm\n', Z_out_val);
fprintf(fid, '50R    = %.6g ohm\n\n', Z_in_50R);
fprintf(fid, 'f(Hz)\t|H_50R|(dB)\t|H_1M|(dB)\t|H_probe|(dB)\tphase_1M(deg)\tZout_err(%%)\n');
for f_idx = [10e3 100e3 1e6 10e6 100e6 500e6 1e9]
    mag_50  = 20*log10(interp1(f, abs(resp_50R),   f_idx, 'linear'));
    mag_1m  = 20*log10(interp1(f, abs(resp_1M),    f_idx, 'linear'));
    mag_p   = 20*log10(interp1(f, abs(resp_probe), f_idx, 'linear'));
    ph_1m   = interp1(f, unwrap(angle(resp_1M))*180/pi, f_idx, 'linear');
    err_pct_f = interp1(f_ex, err_pct, f_idx, 'linear');
    fprintf(fid, '%.6g\t%.6g\t%.6g\t%.6g\t%.6g\t%.6g\n', ...
        f_idx, mag_50, mag_1m, mag_p, ph_1m, err_pct_f);
end
fclose(fid);

disp('Generated scope probe loading figures:');
disp(fullfile(output_dir, 'matlab-probe-compensation-step.png'));
disp(fullfile(output_dir, 'matlab-three-input-paths-bode.png'));
disp(fullfile(output_dir, 'matlab-dual-load-zout-error.png'));
disp(fullfile(output_dir, 'matlab-100mhz-time-domain-three-setups.png'));
disp(result_file);
