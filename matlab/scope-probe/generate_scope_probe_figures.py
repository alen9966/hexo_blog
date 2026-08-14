# -*- coding: utf-8 -*-
"""Python equivalent of the scope-probe loading MATLAB figures script.

Produces 4 figures (PNG, 180 dpi, English labels so the renderings work
without a CJK-capable Matplotlib font):

1. Probe compensation step responses (time domain)
2. Bode of three input paths (50R / 1M / 10x-probe)
3. Dual-load Zout estimation error vs frequency + transfer function plot
4. 100 MHz sine three-setup time-domain + Vpp comparison

Runs with numpy, scipy and matplotlib (no MATLAB / Octave required).
"""
from __future__ import annotations

import os
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib import rcParams
from scipy import signal

# -------------------------------------------------------------------------
# Paths & style
# -------------------------------------------------------------------------
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(os.path.dirname(SCRIPT_DIR))
OUTPUT_DIR = os.path.join(
    PROJECT_DIR, "source", "images", "myimge", "scope-probe-loading"
)
os.makedirs(OUTPUT_DIR, exist_ok=True)

rcParams["font.family"] = "DejaVu Sans"
rcParams["axes.unicode_minus"] = False
rcParams["axes.labelsize"] = 11
rcParams["axes.titlesize"] = 12
rcParams["legend.fontsize"] = 9
rcParams["lines.linewidth"] = 1.8

BLUE  = (0.12, 0.39, 0.82)
GREEN = (0.10, 0.62, 0.46)
RED   = (0.88, 0.30, 0.34)
GRAY  = (0.60, 0.60, 0.60)
DARK  = (0.30, 0.30, 0.30)
COLORS = [BLUE, GREEN, RED]


def save(fig, name):
    out = os.path.join(OUTPUT_DIR, name)
    fig.savefig(out, dpi=180, bbox_inches="tight", facecolor="white")
    plt.close(fig)
    print(f"Wrote {out}")


# -------------------------------------------------------------------------
# 1. Probe compensation step responses (time domain)
# -------------------------------------------------------------------------
R_tip = 9e6
R_in  = 1e6
C_in  = 10e-12

C_tip_correct = (R_in / R_tip) * C_in     # ~ 1.11 pF
C_tip_under   = 0.55 * C_tip_correct
C_tip_over    = 2.20 * C_tip_correct


def probe_tf(C_tip):
    """Return scipy TransferFunction for Zin / (Ztip + Zin)."""
    # H(s) = (Rin + Rin*Rtip*Ctip*s) / ((Rin+Rtip) + Rin*Rtip*(Cin+Ctip)*s)
    num = np.array([R_in * R_tip * C_tip, R_in])
    den = np.array([R_in * R_tip * (C_in + C_tip), R_in + R_tip])
    return signal.TransferFunction(num, den)


H_correct = probe_tf(C_tip_correct)
H_under   = probe_tf(C_tip_under)
H_over    = probe_tf(C_tip_over)

# 1 kHz 1 V square-wave, 4 periods
f_sq  = 1000.0
T_sq  = 1.0 / f_sq
t_end = 4.0 * T_sq
N = 1200
tt = np.linspace(0.0, t_end, N, endpoint=False)
u_sq = (np.mod(tt, T_sq) < T_sq / 2.0).astype(float)  # 0 -> 1 V square

_, y_correct, _ = signal.lsim(H_correct, u_sq, tt)
_, y_under,   _ = signal.lsim(H_under,   u_sq, tt)
_, y_over,    _ = signal.lsim(H_over,    u_sq, tt)

fig, (ax1, ax2) = plt.subplots(
    2, 1, figsize=(11.6, 7.4), constrained_layout=True
)
ax1.plot(tt * 1e3, u_sq, color=GRAY, linestyle=":", linewidth=1.4,
         label="Input 1 V square-wave")
ax1.plot(tt * 1e3, y_correct, color=BLUE,
         label="Correctly compensated: flat top")
ax1.axhline(0.1, color=DARK, linestyle="--",
            label="10x probe 0.1 V output (1 V input)")
ax1.set_xlabel("Time / ms")
ax1.set_ylabel("Displayed voltage / V")
ax1.set_title("10x passive probe + 1 kHz square-wave: "
              "three compensation states (time-domain simulation)")
ax1.set_ylim(-0.05, 0.20)
ax1.grid(True)
ax1.legend(loc="lower right")

zoom_mask = tt <= 0.25e-3
ax2.plot(tt[zoom_mask] * 1e6, u_sq[zoom_mask], color=GRAY, linestyle=":",
         linewidth=1.4, label="Input 1 V square-wave")
ax2.plot(tt[zoom_mask] * 1e6, y_correct[zoom_mask], color=BLUE,
         label=f"Correct:   Ctip = {C_tip_correct * 1e12:.2f} pF")
ax2.plot(tt[zoom_mask] * 1e6, y_under[zoom_mask], color=GREEN,
         label=f"Under-comp: Ctip = {C_tip_under * 1e12:.2f} pF (slow RC rise)")
ax2.plot(tt[zoom_mask] * 1e6, y_over[zoom_mask], color=RED,
         label=f"Over-comp:  Ctip = {C_tip_over * 1e12:.2f} pF (overshoot)")
ax2.axhline(0.1, color=DARK, linestyle="--", label="0.1 V nominal output")
ax2.set_xlabel("Time / us (rising-edge zoom)")
ax2.set_ylabel("Displayed voltage / V")
ax2.set_title("Rising-edge zoom: under-compensation = RC tail; "
              "over-compensation = ringing-like overshoot")
ax2.set_xlim(0, 250)
ax2.grid(True)
ax2.legend(loc="lower right", fontsize=8.5)

save(fig, "matlab-probe-compensation-step.png")

# -------------------------------------------------------------------------
# 2. Bode diagram: three input paths, Zout = 39 Ohm
# -------------------------------------------------------------------------
Zout_val = 39.0

# A: 50 Ohm termination  ->  H = 50 / (Zout + 50),  pure real constant
H_50R = signal.TransferFunction([50.0], [Zout_val + 50.0])

# B: 1 MOhm || 10 pF
# H(s) = R1 / ((Zout*R1*C1)*s + (Zout + R1))
R1, C1 = R_in, C_in
H_1M = signal.TransferFunction([R1], [Zout_val * R1 * C1, Zout_val + R1])

# C: 10x probe (correctly compensated): tip sees 10 MOhm || 1 pF
R_tip_eq = 10e6
C_tip_eq = 1e-12
H_probe = signal.TransferFunction(
    [R_tip_eq], [Zout_val * R_tip_eq * C_tip_eq, Zout_val + R_tip_eq]
)

f = np.logspace(4, 9, 2400)
w = 2 * np.pi * f
w, mag_50,   ph_50   = signal.bode(H_50R,   w)
_, mag_1m,    ph_1m    = signal.bode(H_1M,    w)
_, mag_probe, ph_probe = signal.bode(H_probe, w)

labels = [
    "SMA direct + 50 Ohm termination",
    "SMA direct + 1 MOhm (with 10 pF input C)",
    "10x passive probe + 1 MOhm (correctly compensated)",
]

fig, (ax1, ax2) = plt.subplots(
    2, 1, figsize=(11.8, 7.8), constrained_layout=True
)
for k, (mag, ph) in enumerate(
    [(mag_50, ph_50), (mag_1m, ph_1m), (mag_probe, ph_probe)]
):
    ax1.semilogx(f, mag, color=COLORS[k], label=labels[k])
    ax2.semilogx(f, ph,  color=COLORS[k], label=labels[k])

ax1.axvline(100e6, color=DARK, linestyle="--",
            label="100 MHz (test frequency)")
ax1.axhline(-20 * np.log10(2), color=DARK, linestyle=":",
            label="-3 dB attenuation")
ax1.set_xlabel("Frequency / Hz")
ax1.set_ylabel("| Vscope / Vs (Thevenin) | / dB")
ax1.set_title("Magnitude response: three scope input paths, DUT Zout ~ 39 Ohm")
ax1.legend(loc="lower left", fontsize=8.5)
ax1.set_xlim(1e4, 1e9)
ax1.set_ylim(-16, 2)
ax1.grid(True)

ax2.axvline(100e6, color=DARK, linestyle="--",
            label="100 MHz (test frequency)")
ax2.axhline(0, color=DARK, linestyle=":")
ax2.set_xlabel("Frequency / Hz")
ax2.set_ylabel("Phase / deg")
ax2.set_title("Phase response: 1 MOhm direct mode introduces significant "
              "capacitive lag above ~200 kHz")
ax2.legend(loc="lower left", fontsize=8.5)
ax2.set_xlim(1e4, 1e9)
ax2.set_ylim(-90, 10)
ax2.grid(True)

save(fig, "matlab-three-input-paths-bode.png")

# -------------------------------------------------------------------------
# 3. Transfer-function & error of simplified dual-load Zout estimation
# -------------------------------------------------------------------------
f_ex = np.logspace(4, 9, 800)
w_ex = 2 * np.pi * f_ex
Z_in_1M_s = 1.0 / (1.0 / R1 + 1j * w_ex * C1)

V_50            = np.full_like(f_ex, 50.0 / (Zout_val + 50.0))
V_1M_true_abs   = np.abs(Z_in_1M_s / (Zout_val + Z_in_1M_s))
V_1M_ideal_abs  = np.ones_like(f_ex)

Zout_approx = 50.0 * (V_1M_ideal_abs / V_50 - 1.0)
Zout_true   = 50.0 * (V_1M_true_abs  / V_50 - 1.0)
err_pct     = 100.0 * np.abs((Zout_approx - Zout_true) / Zout_true)
abs_Zin     = np.abs(Z_in_1M_s)

fig, (ax1, ax2) = plt.subplots(
    2, 1, figsize=(11.8, 7.6), constrained_layout=True
)

ax1.semilogx(f_ex, Zout_true, color=BLUE, linewidth=2.2,
             label="Zout,true (with Cin = 10 pF correction)")
ax1.semilogx(f_ex, Zout_approx, color=RED, linewidth=2.0, linestyle="--",
             label="Zout,appx (simplified dual-load: 1 MOhm treated as ideal open)")
ax1.axhline(39.0, color=DARK, linestyle=":", label="True Zout = 39 Ohm")
ax1.axvline(100e6, color=DARK, linestyle="--", label="100 MHz (test frequency)")
ax1.set_ylabel("Back-calculated Zout / Ohm")
ax1.set_ylim(38, 68)

ax1r = ax1.twinx()
ax1r.semilogx(f_ex, abs_Zin / 1e3, color=GREEN, linestyle="-.",
              label="Effective |Zin,1M| (right axis)")
ax1r.set_ylabel("|Zin,1M| / kOhm")
ax1r.set_ylim(0, 1100)

h1, l1 = ax1.get_legend_handles_labels()
h2, l2 = ax1r.get_legend_handles_labels()
ax1.legend(h1 + h2, l1 + l2, loc="lower left", fontsize=8.5)
ax1.set_xlabel("Frequency / Hz")
ax1.set_title("How the 1 MOhm input capacitance makes the "
              "simplified dual-load formula break down with frequency")
ax1.grid(True)
ax1.set_xlim(1e4, 1e9)

ax2.semilogx(f_ex, err_pct, color=RED, linewidth=2.0)
ax2.axvline(100e6, color=DARK, linestyle="--",
            label="100 MHz (test frequency)")
ax2.axhline(5,  color=DARK, linestyle=":", label="5 % error")
ax2.axhline(20, color=DARK, linestyle=":", label="20 % error")
f_mark   = 100e6
err_mark = float(np.interp(np.log10(f_mark), np.log10(f_ex), err_pct))
ax2.plot(f_mark, err_mark, "o", color=RED, markersize=7,
         markerfacecolor=RED)
ax2.text(1.2e8, err_mark + 3,
         f"At 100 MHz, relative error ~ {err_mark:.1f} %",
         color=RED, fontweight="bold", backgroundcolor="white")
ax2.set_xlabel("Frequency / Hz")
ax2.set_ylabel("|Zout,appx - Zout,true| / Zout,true  (x 100%)")
ax2.set_title("Relative error of the simplified dual-load formula "
              "grows monotonically with frequency (Cin driven)")
ax2.legend(loc="lower right", fontsize=8.5)
ax2.grid(True)
ax2.set_xlim(1e4, 1e9)

save(fig, "matlab-dual-load-zout-error.png")

# -------------------------------------------------------------------------
# 4. 100 MHz sine five cycles: three setups + Vpp bar chart
# -------------------------------------------------------------------------
f_sig    = 100e6
t_cycles = 5.0 / f_sig
N = 1501
t_vec  = np.linspace(0.0, t_cycles, N, endpoint=False)
vs_vec = 2.00 * np.sin(2 * np.pi * f_sig * t_vec)   # Vs = 2.00 Vpp open

_, y50,   _ = signal.lsim(H_50R,   vs_vec, t_vec)
_, y1m,   _ = signal.lsim(H_1M,    vs_vec, t_vec)
_, yprob, _ = signal.lsim(H_probe, vs_vec, t_vec)

vpp_50   = float(2.0 * np.max(np.abs(y50)))
vpp_1m   = float(2.0 * np.max(np.abs(y1m)))
vpp_prob = float(2.0 * np.max(np.abs(yprob)))
vpp_vals    = [vpp_50, vpp_1m, vpp_prob]
article_vpp = [1.12,    1.86,    1.92]

fig, (ax1, ax2) = plt.subplots(
    2, 1, figsize=(11.6, 7.2), constrained_layout=True
)
ax1.plot(t_vec * 1e9, vs_vec, color=GRAY, linestyle=":", linewidth=1.4,
         label="Ideal Thevenin open-circuit Vs (reference)")
ax1.plot(t_vec * 1e9, y50,  color=BLUE,
         label=f"50 Ohm term. : {vpp_50:.2f} Vpp")
ax1.plot(t_vec * 1e9, y1m,  color=GREEN,
         label=f"1 MOhm input : {vpp_1m:.2f} Vpp")
ax1.plot(t_vec * 1e9, yprob, color=RED,
         label=f"10x probe    : {vpp_prob:.2f} Vpp (tip-side)")
ax1.set_xlabel("Time / ns")
ax1.set_ylabel("Displayed voltage / V")
ax1.set_title("100 MHz sine: 5 cycles displayed by the scope "
              "under three setups (time-domain simulation)")
ax1.legend(loc="lower right", fontsize=8.5)
ax1.set_xlim(0, t_cycles * 1e9)
ax1.grid(True)

setups = ["SMA + 50R", "SMA + 1M", "10x probe"]
x = np.arange(len(setups))
width = 0.35
bh = ax2.bar(x - width / 2, vpp_vals, width, label="Simulated Vpp")
for patch, c in zip(bh, COLORS):
    patch.set_facecolor(c)
ax2.bar(x + width / 2, article_vpp, width,
        label="Measured / derived in the article",
        facecolor="none", edgecolor=DARK, linestyle="--", linewidth=1.6)
for i, v in enumerate(vpp_vals):
    ax2.text(i - width / 2, v + 0.04, f"{v:.2f} V",
             ha="center", fontweight="bold")
ax2.set_xticks(x)
ax2.set_xticklabels(setups)
ax2.set_ylabel("Peak-to-peak Vpp / V")
ax2.set_title("Vpp comparison: simulated values (solid bars) vs "
              "article measurements / derivations (dashed bars)")
ax2.set_ylim(0, 2.3)
ax2.legend(loc="upper left", fontsize=8.5)
ax2.grid(axis="y", alpha=0.4)

save(fig, "matlab-100mhz-time-domain-three-setups.png")

# -------------------------------------------------------------------------
# Numerical results text file (mirrors the .m script's output)
# -------------------------------------------------------------------------
result_file = os.path.join(SCRIPT_DIR, "scope_probe_loading_results.txt")
with open(result_file, "w", encoding="utf-8") as fh:
    fh.write(
        "Educational scope probe / input-loading theoretical model "
        "(Python + scipy re-derivation)\n"
    )
    fh.write(f"R_in   = {R_in:.6g} ohm\n")
    fh.write(f"C_in   = {C_in:.6g} F\n")
    fh.write(f"R_tip  = {R_tip:.6g} ohm\n")
    fh.write(
        f"C_tip  = correct={C_tip_correct:.6g} F   "
        f"under={C_tip_under:.6g} F   over={C_tip_over:.6g} F\n"
    )
    fh.write(f"Z_out  = {Zout_val:.6g} ohm\n")
    fh.write("50R    = 50 ohm\n\n")
    fh.write(
        "f(Hz)\t|H_50R|(dB)\t|H_1M|(dB)\t|H_probe|(dB)\t"
        "phase_1M(deg)\tZout_err(%)\n"
    )
    for freq in [10e3, 100e3, 1e6, 10e6, 100e6, 500e6, 1e9]:
        m50 = float(np.interp(np.log10(freq), np.log10(f), mag_50))
        m1m = float(np.interp(np.log10(freq), np.log10(f), mag_1m))
        mp  = float(np.interp(np.log10(freq), np.log10(f), mag_probe))
        p1m = float(np.interp(np.log10(freq), np.log10(f), ph_1m))
        ep  = float(np.interp(np.log10(freq), np.log10(f_ex), err_pct))
        fh.write(
            f"{freq:.6g}\t{m50:.6g}\t{m1m:.6g}\t{mp:.6g}"
            f"\t{p1m:.6g}\t{ep:.6g}\n"
        )
print(f"Wrote {result_file}")
