#!/usr/bin/env python3
"""Regenerate scope schematics with fully English labels to avoid missing CJK glyphs
(DejaVu Sans has no CJK; blog keeps Chinese explanations in alt/caption text around the image).
"""
from pathlib import Path
import math
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, Circle
from matplotlib.lines import Line2D

HERE = Path(__file__).resolve().parent
OUT = (HERE / "../../source/images/myimge/scope-probe-loading").resolve()
OUT.mkdir(parents=True, exist_ok=True)

COLOR_BG = "#fbfbfb"
COLOR_LINE = "#2f2f2f"
COLOR_NODE = "#e23d50"
COLOR_TEXT = "#1f1f1f"
COLOR_BLUE = "#2d7ad4"
COLOR_TEAL = "#2ba38a"
COLOR_GRAY = "#7a7a7a"

matplotlib.rc("font", **{"family": "DejaVu Sans", "size": 11})

ZIG_ZAG = [
    (0.00, 0.0), (0.10, 0.0), (0.18, 0.30), (0.30, -0.30),
    (0.42, 0.30), (0.54, -0.30), (0.66, 0.30), (0.78, -0.30),
    (0.84, 0.0), (1.00, 0.0),
]


def figax(size=(13, 5.4), dpi=160, xlim=(0, 13), ylim=(0, 5.4)):
    fig, ax = plt.subplots(figsize=size, dpi=dpi)
    ax.set_facecolor(COLOR_BG)
    fig.patch.set_facecolor(COLOR_BG)
    ax.set_xlim(*xlim)
    ax.set_ylim(*ylim)
    ax.axis("off")
    return fig, ax


def txt(ax, x, y, s, color=COLOR_TEXT, size=11, ha="center", va="center", weight=None):
    ax.text(x, y, s, color=color, fontsize=size, ha=ha, va=va, fontweight=weight)


def ground(ax, x, y, w=0.6):
    ax.add_line(Line2D([x - w / 2, x + w / 2], [y, y], color=COLOR_LINE, lw=1.6))
    for i, r in enumerate((1.0, 0.72, 0.44)):
        ax.add_line(Line2D(
            [x - w * r / 2, x + w * r / 2],
            [y - 0.18 - i * 0.16, y - 0.18 - i * 0.16],
            color=COLOR_LINE, lw=1.4))


def dot(ax, x, y, color=COLOR_NODE):
    ax.add_patch(Circle((x, y), 0.08, color=color, zorder=3))


def zigzag_h(ax, x0, y, length, amp=0.30):
    xs = [x0 + length * t for t, _ in ZIG_ZAG]
    ys = [y + amp * dy for _, dy in ZIG_ZAG]
    ax.add_line(Line2D(xs, ys, color=COLOR_LINE, lw=1.7))


def zigzag_v(ax, x, y0, length, amp=0.28):
    xs = [x + amp * dy for _, dy in ZIG_ZAG]
    ys = [y0 - length * t for t, _ in ZIG_ZAG]
    ax.add_line(Line2D(xs, ys, color=COLOR_LINE, lw=1.7))


def cap_v(ax, x, y, label=None, length=0.95, gap=0.38, label_dx=0.85):
    ax.add_line(Line2D([x - length / 2, x + length / 2], [y + gap / 2, y + gap / 2], color=COLOR_LINE, lw=2.1))
    ax.add_line(Line2D([x - length / 2, x + length / 2], [y - gap / 2, y - gap / 2], color=COLOR_LINE, lw=2.1))
    if label:
        txt(ax, x + label_dx, y, label, color=COLOR_TEAL, size=11.5, weight="bold")


def ac_source(ax, x, y, r=0.34, label=None):
    ax.add_patch(Circle((x, y), r, facecolor="#ffffff", edgecolor=COLOR_LINE, lw=1.7))
    import numpy as np
    t = np.linspace(-r * 0.65, r * 0.65, 80)
    s = 0.45 * r * np.sin((t / (r * 0.65)) * 2 * math.pi)
    ax.add_line(Line2D(x + t, y + s, color=COLOR_LINE, lw=1.5))
    txt(ax, x - 0.72, y + 0.55, "+", color=COLOR_NODE, size=16, weight="bold")
    txt(ax, x - 0.72, y - 0.55, "-", color=COLOR_BLUE, size=18, weight="bold")
    if label:
        txt(ax, x, y + r + 0.5, label, color=COLOR_TEXT, size=11.5, weight="bold")


def meter(ax, xc, yc, r=0.5, left_x_top=None, left_x_bot=None, y_top=None, y_bot=None):
    ax.add_patch(Circle((xc, yc), r, facecolor="#fff", edgecolor=COLOR_TEAL, lw=1.8))
    txt(ax, xc, yc + 0.08, "V", color=COLOR_TEAL, size=13, weight="bold")
    txt(ax, xc, yc - 0.22, "scope", color=COLOR_TEAL, size=8.5, weight="bold")
    if left_x_top is not None:
        ax.add_line(Line2D([left_x_top, xc], [y_top, yc + 0.28 * r], color=COLOR_TEAL, lw=1.6))
        ax.add_line(Line2D([left_x_bot, xc], [y_bot, yc - 0.28 * r], color=COLOR_TEAL, lw=1.6))


# ---------- Figure 1: RC input model ----------
def rc_input_model():
    fig, ax = figax(size=(13, 5.4), xlim=(0, 13), ylim=(0, 5.4))

    dut = FancyBboxPatch((0.3, 0.85), 4.5, 3.8, boxstyle="round,pad=0.04,rounding_size=0.18",
                        linewidth=1.4, edgecolor=COLOR_GRAY, facecolor="#fff6f4", linestyle="--")
    ax.add_patch(dut)
    txt(ax, 2.55, 4.28, "DUT Thevenin source (Vs, Zout)", color=COLOR_TEXT, size=12, weight="bold")

    ac_source(ax, 1.8, 2.9, label="Vs")

    ax.add_line(Line2D([1.8, 1.8], [2.9 + 0.34, 4.15], color=COLOR_LINE, lw=1.7))
    ax.add_line(Line2D([1.8, 4.2], [4.15, 4.15], color=COLOR_LINE, lw=1.7))

    ax.add_line(Line2D([1.8, 1.8], [2.9 - 0.34, 1.5], color=COLOR_LINE, lw=1.7))
    zigzag_h(ax, 1.8, 1.5, 1.25, amp=0.22)
    ax.add_line(Line2D([3.05, 4.2], [1.5, 1.5], color=COLOR_LINE, lw=1.7))
    txt(ax, 2.42, 1.05, "Zout", color=COLOR_BLUE, size=11.5, weight="bold")

    dot(ax, 4.2, 4.15)
    dot(ax, 4.2, 1.5)
    dot(ax, 5.3, 4.15, color=COLOR_NODE)
    dot(ax, 5.3, 1.5, color=COLOR_BLUE)
    ax.add_line(Line2D([4.2, 5.3], [4.15, 4.15], color=COLOR_LINE, lw=1.7))
    ax.add_line(Line2D([4.2, 5.3], [1.5, 1.5], color=COLOR_LINE, lw=1.7))
    txt(ax, 4.75, 1.02, "SMA / coax", color=COLOR_NODE, size=11, weight="bold")

    scope = FancyBboxPatch((5.8, 0.85), 6.9, 3.8, boxstyle="round,pad=0.04,rounding_size=0.18",
                           linewidth=1.4, edgecolor=COLOR_BLUE, facecolor="#f4f8ff")
    ax.add_patch(scope)
    txt(ax, 9.25, 4.28, "Scope 1 MOhm input: Rin || Cin", color=COLOR_BLUE, size=12, weight="bold")

    ax.add_line(Line2D([5.3, 6.6], [4.15, 4.15], color=COLOR_LINE, lw=1.7))
    ax.add_line(Line2D([5.3, 6.6], [1.5, 1.5], color=COLOR_LINE, lw=1.7))
    dot(ax, 6.6, 4.15)
    dot(ax, 6.6, 1.5)

    # Rin vertical branch at x ~ 6.9
    ax.add_line(Line2D([6.6, 6.9], [4.15, 4.15], color=COLOR_LINE, lw=1.7))
    zigzag_v(ax, 6.9, 4.15, 2.15, amp=0.30)
    ax.add_line(Line2D([6.9, 6.6], [4.15 - 2.15, 1.5], color=COLOR_LINE, lw=1.7))
    txt(ax, 7.35, 3.08, "Rin = 1 M\u03A9", color=COLOR_BLUE, size=11.5, weight="bold", ha="left")

    # Cin parallel at x=10.2
    ax.add_line(Line2D([6.6, 10.2], [4.15, 4.15], color=COLOR_LINE, lw=1.7))
    dot(ax, 10.2, 4.15)
    ax.add_line(Line2D([10.2, 10.2], [4.15, 3.0], color=COLOR_LINE, lw=1.7))
    cap_v(ax, 10.2, 2.8, length=0.95, gap=0.38, label="Cin = 10 pF", label_dx=0.95)
    ax.add_line(Line2D([10.2, 10.2], [2.8 - 0.38 / 2, 1.5], color=COLOR_LINE, lw=1.7))
    dot(ax, 10.2, 1.5)
    ax.add_line(Line2D([6.6, 10.2], [1.5, 1.5], color=COLOR_LINE, lw=1.7))

    # Vscope meter on right side of input nodes (10.2)
    ax.add_line(Line2D([10.2, 11.8], [4.15, 4.15], color=COLOR_LINE, lw=1.7))
    ax.add_line(Line2D([10.2, 11.8], [1.5, 1.5], color=COLOR_LINE, lw=1.7))
    txt(ax, 11.65, 4.3, "+", color=COLOR_NODE, size=14, weight="bold")
    txt(ax, 11.65, 1.2, "-", color=COLOR_BLUE, size=16, weight="bold")
    meter(ax, 12.05, 2.82, r=0.52, left_x_top=11.8, left_x_bot=11.8, y_top=4.15, y_bot=1.5)

    # Equation callout
    eq = (r"$V_{\mathrm{scope}}(\omega)=V_s(\omega)\cdot\frac{R_{in}\,\|\,\frac{1}{j\omega C_{in}}}"
          r"{Z_{out}+R_{in}\,\|\,\frac{1}{j\omega C_{in}}}$")
    ax.text(6.7, 0.45, eq, ha="center", va="center", fontsize=12.2, color=COLOR_TEXT,
            bbox=dict(boxstyle="round,pad=0.45", fc="#fff8e7", ec="#e6c56d", lw=1.2))

    ground(ax, 1.8, 0.8, w=0.58)
    ground(ax, 10.2, 0.8, w=0.58)

    fig.tight_layout(pad=0.3)
    out = OUT / "scope-input-r-c-model.png"
    fig.savefig(out, facecolor=fig.get_facecolor(), bbox_inches="tight")
    plt.close(fig)
    print(f"wrote {out}")


# ---------- Figure 2: 10x probe compensation ----------
def probe_schematic():
    fig, ax = figax(size=(14, 5.4), xlim=(0, 14), ylim=(0, 5.4))

    tip_x, tip_y = 0.9, 4.1
    gnd_x, gnd_y = 0.9, 1.15
    dot(ax, tip_x, tip_y)
    txt(ax, tip_x, tip_y + 0.3, "Tip (DUT signal)", color=COLOR_NODE, size=10.5, weight="bold")
    dot(ax, gnd_x, gnd_y, color=COLOR_BLUE)
    txt(ax, gnd_x, gnd_y - 0.32, "Ground clip (return)", color=COLOR_BLUE, size=10.5, weight="bold")
    ground(ax, gnd_x, gnd_y - 0.55, w=0.58)

    probe = FancyBboxPatch((1.35, 0.75), 6.15, 4.05, boxstyle="round,pad=0.04,rounding_size=0.18",
                           linewidth=1.4, edgecolor=COLOR_GRAY, facecolor="#fff8f2", linestyle="--")
    ax.add_patch(probe)
    txt(ax, 4.42, 4.46, "Passive 10x probe tip", color=COLOR_TEXT, size=12, weight="bold")

    # Top rail from tip -> x=2.1
    ax.add_line(Line2D([tip_x, 2.1], [tip_y, tip_y], color=COLOR_LINE, lw=1.7))
    dot(ax, 2.1, tip_y)

    # Rtip vertical: x ~ 2.32 from tip_y down to 2.0
    ax.add_line(Line2D([2.1, 2.32], [tip_y, tip_y], color=COLOR_LINE, lw=1.7))
    zigzag_v(ax, 2.32, tip_y, 2.0, amp=0.30)
    rtip_bot = tip_y - 2.0  # 2.1
    ax.add_line(Line2D([2.32, 2.7], [rtip_bot, rtip_bot], color=COLOR_LINE, lw=1.7))
    txt(ax, 2.85, (tip_y + rtip_bot) / 2, "Rtip = 9 M\u03A9", color=COLOR_BLUE, size=11.5, weight="bold", ha="left")

    # Ctip parallel at x = 4.8
    ax.add_line(Line2D([2.1, 4.8], [tip_y, tip_y], color=COLOR_LINE, lw=1.7))
    dot(ax, 4.8, tip_y)
    ax.add_line(Line2D([4.8, 4.8], [tip_y, 2.38], color=COLOR_LINE, lw=1.7))
    cap_v(ax, 4.8, 2.18, length=1.0, gap=0.40, label="Ctip (trim compensation cap)", label_dx=1.3)
    ax.add_line(Line2D([4.8, 4.8], [2.18 - 0.40 / 2, rtip_bot], color=COLOR_LINE, lw=1.7))
    dot(ax, 4.8, rtip_bot)

    # BNC connectors between probe -> scope cable
    bnc_probe_x = 7.05
    bnc_scope_x = 8.25
    ax.add_line(Line2D([2.7, bnc_probe_x], [rtip_bot, rtip_bot], color=COLOR_LINE, lw=1.7))
    ax.add_line(Line2D([gnd_x, bnc_probe_x], [gnd_y, gnd_y], color=COLOR_LINE, lw=1.7))
    dot(ax, bnc_probe_x, rtip_bot)
    dot(ax, bnc_probe_x, gnd_y, color=COLOR_BLUE)

    ax.add_line(Line2D([bnc_probe_x, bnc_scope_x], [rtip_bot, 3.1], color=COLOR_LINE, lw=1.7))
    ax.add_line(Line2D([bnc_probe_x, bnc_scope_x], [gnd_y, 2.0], color=COLOR_LINE, lw=1.7))
    txt(ax, (bnc_probe_x + bnc_scope_x) / 2, 1.42, "BNC coax cable", color=COLOR_NODE, size=10.5, weight="bold")

    # Scope input block
    scope = FancyBboxPatch((bnc_scope_x, 0.85), 5.35, 3.9, boxstyle="round,pad=0.04,rounding_size=0.18",
                           linewidth=1.4, edgecolor=COLOR_BLUE, facecolor="#f4f8ff")
    ax.add_patch(scope)
    txt(ax, bnc_scope_x + 5.35 / 2, 4.46, "Scope 1 M\u03A9 input", color=COLOR_BLUE, size=12, weight="bold")

    dot(ax, bnc_scope_x, 3.1)
    dot(ax, bnc_scope_x, 2.0, color=COLOR_BLUE)

    junction_x = 9.3
    ax.add_line(Line2D([bnc_scope_x, junction_x], [3.1, 3.1], color=COLOR_LINE, lw=1.7))
    ax.add_line(Line2D([bnc_scope_x, junction_x], [2.0, 2.0], color=COLOR_LINE, lw=1.7))
    dot(ax, junction_x, 3.1)
    dot(ax, junction_x, 2.0, color=COLOR_BLUE)

    # Rin vertical at x=9.52
    ax.add_line(Line2D([junction_x, 9.52], [3.1, 3.1], color=COLOR_LINE, lw=1.7))
    zigzag_v(ax, 9.52, 3.1, 1.1, amp=0.28)
    ax.add_line(Line2D([9.52, 9.92], [2.0, 2.0], color=COLOR_LINE, lw=1.7))
    txt(ax, 10.08, 2.55, "Rin = 1 M\u03A9", color=COLOR_BLUE, size=11.5, weight="bold", ha="left")

    # Cin parallel at x=11.8
    ax.add_line(Line2D([junction_x, 11.8], [3.1, 3.1], color=COLOR_LINE, lw=1.7))
    dot(ax, 11.8, 3.1)
    ax.add_line(Line2D([11.8, 11.8], [3.1, 2.32], color=COLOR_LINE, lw=1.7))
    cap_v(ax, 11.8, 2.12, length=0.9, gap=0.40, label="Cin = 10 pF", label_dx=0.9)
    ax.add_line(Line2D([11.8, 11.8], [2.12 - 0.40 / 2, 2.0], color=COLOR_LINE, lw=1.7))
    dot(ax, 11.8, 2.0, color=COLOR_BLUE)
    ax.add_line(Line2D([9.92, 11.8], [2.0, 2.0], color=COLOR_LINE, lw=1.7))

    # Vscope meter
    ax.add_line(Line2D([11.8, 12.8], [3.1, 3.1], color=COLOR_LINE, lw=1.7))
    ax.add_line(Line2D([11.8, 12.8], [2.0, 2.0], color=COLOR_LINE, lw=1.7))
    meter(ax, 13.1, 2.55, r=0.48, left_x_top=12.8, left_x_bot=12.8, y_top=3.1, y_bot=2.0)

    eq = (r"Balanced compensation:$\;R_{tip}C_{tip}=R_{in}C_{in}$"
          r"$\;\Rightarrow\;$attenuation $\frac{R_{in}}{R_{tip}+R_{in}}=\frac{1}{10}$ and flat over frequency")
    ax.text(7.1, 0.42, eq, ha="center", va="center", fontsize=11.3, color=COLOR_TEXT,
            bbox=dict(boxstyle="round,pad=0.42", fc="#fff8e7", ec="#e6c56d", lw=1.2))

    fig.tight_layout(pad=0.3)
    out = OUT / "passive-10x-probe-schematic.png"
    fig.savefig(out, facecolor=fig.get_facecolor(), bbox_inches="tight")
    plt.close(fig)
    print(f"wrote {out}")


rc_input_model()
probe_schematic()
