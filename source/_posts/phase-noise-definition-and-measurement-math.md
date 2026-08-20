---
title: 相位噪声：从 ℒ(f) 的定义到四种测量方法的数学模型
slug: phase-noise-definition-and-measurement-math
date: 2026-08-18 19:30:00
tags:
  - 相位噪声
  - 信号与系统
  - 测试测量
  - 频谱分析
  - 阿伦方差
categories:
  - 学习记录
description: 从带 φ(t) 的正弦波开始，给出 ℒ(f)、Sφ(f)、阿伦偏差 σ_y(τ) 的定义与换算关系，推导幂律五分区斜率，并按直接频谱、I/Q 解调、PLL 鉴相、双通道互相关四种方法写出测量模型和适用边界。
author: Alen
authorLink: https://github.com/alen9966
authorAbout: 从原理图到实测波形，记录硬件设计中的选择、失误与验证。
---

> **关于图与数据**：文中 11 张图为 MATLAB 理论仿真，对应脚本
> `matlab/phase-noise-basics/generate_phase_noise_figures.m`。
> 当前本机没有 MATLAB 运行环境，正文先按目标路径引用图片，
> 在有 MATLAB 的机器上执行一次脚本即可把 11 张 PNG 导出到
> `source/images/myimge/phase-noise-basics/`。

这篇专注原理、公式和测量模型，**不讨论某一只具体 OCXO 的实测结果**——那些已经写在《[从近端噪声到远端噪声：用 53100A 测量 100 MHz OCXO 相位噪声](/2026/08/12/phase-noise-53100a-100mhz-ocxo/)》里。本文的目标是回答：看到一个 `-120 dBc/Hz @ 10 kHz`，它在数学上到底指什么；以及同一只晶振换一台仪器读数为什么不同，什么时候应该信谁。

我自己只用过 **PhaseStation 53100A**；文中涉及 R&S FSWP、Holzworth HA7402B、Noise XT DCNTS、Keysight E5052B、Anapico APPH6000 的架构描述均来自厂家公开资料整理，**不带有任何选型意见**。

## 一、从时域抖动到频域边带：带 φ(t) 的正弦波

理想 100 MHz 载波：

$$
v_{ideal}(t)=A\cos(2\pi f_0 t)
$$

真实振荡器的相位在随机游走，信号写成：

$$
v(t)=A\cos\bigl(2\pi f_0 t + \varphi(t)\bigr)
$$

瞬时频率与分数频率波动按相位的时间导数定义：

$$
f_i(t)=f_0+\frac{1}{2\pi}\frac{d\varphi}{dt},\qquad
y(t)\equiv\frac{f_i(t)-f_0}{f_0}=\frac{1}{2\pi f_0}\frac{d\varphi}{dt}
$$

| 符号 | 含义 | 常用单位 |
|---|---|---|
| $\varphi(t)$ | 随机相位过程 | rad |
| $y(t)$ | 分数频率波动 | 无量纲 |
| $\Delta t(N)$ | 第 $N$ 个过零点相对理想位置的时间偏差 | s |

把这三者放到同一个时间窗里，过零点抖动就是 $\varphi(t)$ 在时域最直观的表现：

![图1  理想与实际正弦波的过零抖动差异（MATLAB 理论仿真）](/images/myimge/phase-noise-basics/fig01_phase_jitter_time_domain.png)

## 二、ℒ(f) 的数学定义 + 什么是 dBc/Hz @ f_offset

### 2.1 单边带相位噪声 ℒ(f)

NIST 的定义：**距离载波 $f_{offset}$ 处，取 1 Hz 等效噪声带宽内的单边带噪声功率，除以载波总功率**。

$$
\mathcal{L}(f_{offset}) \equiv \frac{P_{SSB}(f_0\pm f_{offset},\,1\,\text{Hz})}{P_{carrier}}
$$

写成分贝：

$$
\mathcal{L}_{dB}(f)=10\log_{10}\mathcal{L}(f)
$$

**单位是 dBc/Hz**。三个部分缺一不可：

- **dBc** = $10\log_{10}(P/P_{carrier})$，表示"相对于载波的功率比"。杂散也用 dBc，但杂散不带 `/Hz`。
- **/Hz** = 已归一化到 1 Hz 等效噪声带宽。这使读数与频谱仪的 RBW 解耦。
- **@ $f_{offset}$ + $f_0$** = 指定了在频率轴的位置。只写 `-120 dBc/Hz` 而不写 offset 和载波频率，信息量不完整。

**工程上的正确写法示例**：

> `-150 dBc/Hz @ 1 kHz offset from 100 MHz carrier`

### 2.2 小相位调制近似与 Sφ(f) 的关系

把 $v(t)$ 用 Jacobi–Anger 展开。当 $|\varphi(t)|\ll 1\ \text{rad}$ 时（对大多数相位噪声工程问题成立，典型 $\varphi_{rms}$ 仅为 mrad 级）：

$$
\cos(2\pi f_0 t+\varphi)\approx \cos(2\pi f_0 t) - \varphi(t)\sin(2\pi f_0 t)
$$

右边第一项仍是纯载波；第二项把 $\varphi(t)$ 调制到了载波的正交边上，**边带幅度 = $(\Delta\varphi/2)A$**。两边取功率比：

$$
\mathcal{L}(f)=\tfrac{1}{2}S_\varphi(f)
$$

这里 $S_\varphi(f)$ 是 $\varphi(t)$ 的**单边功率谱密度**，单位 $\text{rad}^2/\text{Hz}$。因此只要在小相位条件下，测到的边带功率就能直接还原出相位本身的 PSD，这是所有后续公式推导的桥梁。

![图2  ℒ(f) 的含义：某偏移处 1Hz 带宽功率 ÷ 载波总功率（理论仿真）](/images/myimge/phase-noise-basics/fig02_Lf_definition_and_spurs.png)

## 三、Sφ(f)、残余相位抖动与 RMS 时间抖动的换算

### 3.1 指定带宽内的 RMS 相位抖动

相位本身的方差是把 $S_\varphi(f)$ 在感兴趣的带宽内积分（双侧 → 乘 2）：

$$
\Delta\varphi_{rms}^{2}
= \bigl\langle \varphi(t)^2 \bigr\rangle
= 2\int_{f_{low}}^{f_{high}} \mathcal{L}(f)\, df
$$

代回 $\mathcal{L}=S_\varphi/2$ 就回到最朴素的 PSD 积分。$f_{low}$、$f_{high}$ 是应用关心的抖动带宽边界，**任何 RMS 抖动数字都必须连带指定这两个频率**。

### 3.2 时间抖动 J_rms

把弧度除以 $2\pi f_0$，得到单位为秒的时间抖动：

$$
J_{rms}=\frac{\Delta\varphi_{rms}}{2\pi f_0}
$$

### 3.3 频率/时间稳定性的另一种度量：S_y(f)

分数频率波动 $y(t)$ 的 PSD 与 $\varphi(t)$ 的关系，由 $y=\dot\varphi/(2\pi f_0)$ 做傅里叶变换得到：

$$
S_y(f)=\frac{f^2}{f_0^{2}}\,S_\varphi(f)=2\frac{f^2}{f_0^{2}}\,\mathcal{L}(f)
$$

这一节的三个公式把相位噪声、时域抖动和分数频率稳定度连成了一条可互推的链。

![图3  典型 OCXO 相噪分区斜率与 RMS 抖动积分示意（理论仿真）](/images/myimge/phase-noise-basics/fig03_slope_regions_and_rms_integral.png)

## 四、幂律模型与 1/f⁻²～f² 的五个相噪分区

用幂律近似把 ℒ(f) 写成五段之和：

$$
\mathcal{L}(f)=\sum_{\alpha=-2}^{2}h_{\alpha}\,f^{\alpha}
= h_{-2}f^{-2} + h_{-1}f^{-1} + h_0 + h_{+1}f + h_{+2}f^{2}
$$

| 指数 α | ℒ(f) 斜率 | Sφ(f) 斜率 | 常用名称 | 物理来源 |
|---:|---|---|---|---|
| −2 | −40 dB/dec | −40 dB/dec | 随机游走 FM | 环境扰动/机械振动/老化的漂移在频域的积累 |
| −1 | −20 dB/dec | −20 dB/dec | 闪烁 FM | 器件 1/f 噪声通过振荡过程转成近载频率噪声，决定 10 Hz～1 kHz 段 |
| 0 | 0 dB/dec | 0 dB/dec | 白 FM | 热噪声，形成相噪曲线的平台 |
| +1 | +20 dB/dec | +20 dB/dec | 闪烁 PM | 输出缓冲级 1/f 相位噪声 |
| +2 | +40 dB/dec | +40 dB/dec | 白 PM | 宽带 ADC 量化、热噪声相位底 |

相邻两项的交叉点就是大家常说的"近端/中间/远端"的分界线，具体位置由 $h_i$ 决定，不是固定的 1 kHz。

![图4  五段幂律叠加合成一条完整相噪曲线（理论仿真）](/images/myimge/phase-noise-basics/fig04_power_law_decomposition.png)

## 五、阿伦偏差 σ_y(τ) 与 ℒ(f) 的斜率对应

### 5.1 σ_y(τ) 的定义

对一段等间隔的平均分数频率序列 $\bar y_i$（平均时间 τ，共 M 段），非重叠阿伦偏差：

$$
\sigma_y(\tau)=\sqrt{\frac{1}{2(M-1)}\sum_{i=1}^{M-1}\bigl(\bar y_{i+1}-\bar y_i\bigr)^2}
$$

### 5.2 与 S_y(f)、ℒ(f) 的积分关系

$$
\sigma_y^2(\tau)=2\int_{0}^{\infty} S_y(f)\;\frac{\sin^4(\pi f\tau)}{(\pi f\tau)^2}\;df
$$

$[\sin^4 x / x^2]$ 这个传递函数就是阿伦偏差对不同傅里叶频率的加权。把第四节幂律模型的 $S_y(f)$ 代进去，得到下表——这张表最常用：

| ℒ(f) ∝ f^α | S_y(f) ∝ f^{α+2} | σ_y(τ) ∝ τ^{k} | k 的值 |
|---|---|---|---|
| f⁻²（随机游走 FM） | f⁰ | τ¹ | +1 |
| f⁻¹（闪烁 FM） | f¹ | τ⁰ | **0（平台）** |
| f⁰（白 FM） | f² | τ⁻¹⁄² | −0.5 |
| f⁺¹（闪烁 PM） | f³ | τ⁻¹ | −1 |
| f⁺²（白 PM） | f⁴ | τ⁻³⁄² | −1.5 |

工程口诀：**ℒ 多一条 −20 dB/dec 斜率，σ_y 就多半个 τ 的斜率**。对照图 5 看更直接：

![图5  同一信号的 ℒ(f) 与 σ_y(τ) 的斜率一一对应（理论仿真）](/images/myimge/phase-noise-basics/fig05_Lf_vs_allan_deviation.png)

## 六、测量方法 I：直接频谱（频谱仪直接测）

按 ℒ(f) 的定义，在频谱仪上直接把载波和 1 Hz bin 处的噪声功率比一比：

$$
\mathcal{L}_{marker}(f)=P_{noise,1\,Hz}(dBm)-P_{carrier}(dBm)
$$

实际测量时 RBW > 1 Hz，需要换算到等效噪声带宽（ENBW）：

$$
\mathcal{L}(f) =
\bigl[P_{noise,\,RBW}(dBm) - P_{carrier}(dBm)\bigr]
-10\log_{10}\!\left(\frac{ENBW}{1\,Hz}\right)
$$

高斯形状的中频滤波器典型 $ENBW \approx 1.05\sim 1.20 \times RBW_{标称}$，具体值查仪器手册。

直接频谱法有两个硬前提：

1. **仪器 LO 相噪 ≪ DUT 相噪**（经验差值 ≥ 10 dB）。否则测到的是 LO，不是 DUT。
2. **DUT 的 AM 噪声 ≪ DUT 的 PM 噪声**（≥ 10 dB）。直接法只看功率，两者没法区分，直接相加后取较大者。

因此直接法仅适合：快速估算近端很差的振荡器，或者测 DUT 较远载的杂散/底噪。**近载波高精度测量必须交给 II/III/IV 类方法。**

![图6  直接频谱法受限于 LO 相噪和 AM 噪声（理论示意）](/images/myimge/phase-noise-basics/fig06_direct_spectrum_ceiling.png)

## 七、测量方法 II：模拟/数字 I/Q 解调（FSWP / 53100A 类方案）

把 DUT RF 与本振 LO 送入一对正交混频器，LO 信号彼此相差 90°：

$$
\begin{aligned}
I(t) &= \text{LPF}\{\,v_{DUT}(t)\cdot LO_I(t)\,\} \propto \cos\Delta\varphi(t) \\
Q(t) &= \text{LPF}\{\,v_{DUT}(t)\cdot LO_Q(t)\,\} \propto \sin\Delta\varphi(t)
\end{aligned}
$$

然后：

$$
\varphi(t)=\text{atan2}(Q,I),\qquad A(t)=\sqrt{I^2+Q^2}
$$

I 和 Q 被严格拆到两条通道上，**幅度和相位自然分离**，方法六的第二个前提（AM ≪ PM）就不再需要了。

FSWP 和 53100A 的差别只在于正交解调发生在模拟域还是数字域：

- **FSWP 类：模拟 I/Q**。RF 直接送入模拟正交混频，LPF 后 ADC 采 I、Q 两路基带；
- **53100A 类：数字 I/Q**。先把 DUT RF 下变频到一个数字化的固定中频 IF，再在 FPGA/DS P 里做 90° 数字相移得到复数 I/Q。数字正交的好处是 90° 准确度与幅相平衡可以用校准保证，不随模拟器件温度漂移。

![图7  模拟 I/Q 与数字 I/Q 解调的架构差异（原理示意）](/images/myimge/phase-noise-basics/fig07_analog_vs_digital_iq.png)

## 八、测量方法 III：PLL + 双平衡混频鉴相（HA7402B / DCNTS / E5052B 类方案）

把双平衡混频器当作鉴相器：DUT 送入 RF 口，参考源送入 LO 口，**用一个 PLL 把两者锁定在正交点 Δφ ≈ π/2**。在该点附近，混频器输出的基带信号近似正比于Δφ：

$$
v_{BM}(t) \approx K_{pd}\cdot\Delta\varphi(t) = K_{pd}\bigl[\varphi_{DUT}(t)-\varphi_{REF}(t)\bigr]
$$

LPF 之后分成两条路：

- 一条送入基带频谱仪/FFT → 得到基带 $S_v(f)$ → 除以 $K_{pd}^2$ → $S_\varphi(f)$ → $\mathcal{L}(f)$；
- 另一条送入 PLL 环路滤波器/控制器，输出调谐电压反馈到 REF，**保持 π/2 正交锁定**。

两个关键条件：

1. **PLL 环路带宽 $f_{BW} \ll f_{low}$**（我们想测的最低偏移频率）。否则 PLL 会把 DUT 的低频相噪也"纠正掉"，近端被环路整形变形；
2. **小角度近似 Δφ ≪ 1 rad** 必须成立。如果正交点飘了、DUT 跳频或失锁，混频输出会进入非线性区，比例关系失效。

由于双平衡结构天然抵消载波和 AM 项，这种方法天然能把 AM/PM 分离。

![图8  PLL + 双平衡混频器鉴相（HA7402B / DCNTS / E5052B 类方案）](/images/myimge/phase-noise-basics/fig08_pll_double_balanced_mixer.png)

## 九、参考源天花板与互相关：单参考 vs 双参考

### 9.1 单参考源的硬天花板（我的一手经历）

我在用 PhaseStation 53100A 之前，曾临时用一台内部参考一般、单参考架构的仪器测过同一只 100 MHz OCXO：读出的 10 Hz / 100 Hz 近端明显比预期差了 20 dB 以上。后来换 53100A 的双参考 + 互相关复测，近端立刻恢复到 OCXO 应有的水平。**前一次测到的不是晶振本身，而是那台仪器内部参考源的相噪天花板。**

对单参考 + PLL 鉴相法，数学上写得很清楚：

$$
\varphi_{meas}(t)=\varphi_{DUT}(t)-\varphi_{REF}(t)
$$

两边取 PSD，两者不相关时直接相加：

$$
\mathcal{L}_{meas}(f)\;\geq\;\max\bigl(\mathcal{L}_{DUT}(f),\;\mathcal{L}_{REF}(f)\bigr)
$$

当 DUT 明显好于 REF 时，等号近似成立，**测出来就是 REF**。下图的阴影区已经被 REF 压住，DUT 近端再好也读不到：

![图9a  单参考源的相噪测量天花板（原理示意）](/images/myimge/phase-noise-basics/fig09a_single_reference_ceiling.png)

### 9.2 双参考 + 双通道互相关：突破天花板

把 DUT 的信号通过功分器分成两路，每一路各自接一台独立的参考源/接收机：

$$
\begin{aligned}
x_1(t) &= \varphi_D(t) - \varphi_{R1}(t) + n_1(t) \\
x_2(t) &= \varphi_D(t) - \varphi_{R2}(t) + n_2(t)
\end{aligned}
$$

信号成分在两路中完全相干，R1/R2 噪声和通道噪声彼此非相干。对两路基带数据做互相关并累计 $M$ 次平均：

- 相干的 DUT 项：互相关后幅度不变；
- 非相干的 R1、R2、n1、n2：互相关平均 $M$ 次后幅度按 $1/\sqrt{M}$ 衰减。

因此：

$$
\mathcal{L}_{meas}(f) = \mathcal{L}_{DUT}(f)
    +\frac{\mathcal{L}_{R1}(f)+\mathcal{L}_{R2}(f)+\mathcal{L}_{n1}(f)+\mathcal{L}_{n2}(f)}{\sqrt{M}}
$$

**即使两台参考源比 DUT 差 20 dB，只要把互相关平均次数 M 取到 10⁴（对应改善量 ≈ 20 dB），残余 REF 噪声仍然可以被压下去。** 代价是时间成本：

- 灵敏度改善 $\Delta L\approx 5\log_{10}M$ dB；
- 测量时间 $T_{meas}\propto M$。

工程上常取 $M=100\sim1000$。$M=1000$ 只比 $M=100$ 多改善 5 dB，但耗时 10 倍；再往上收益更差。

![图9b  双参考互相关：M→×10，残余 REF 噪声→÷√10（理论示意）](/images/myimge/phase-noise-basics/fig09b_dual_reference_cross_correlation.png)

## 十、主流仪器对照表 + 四机对比示意曲线

### 10.1 六款主流相噪仪器的架构对照

（注：本人只实际操作过 PhaseStation 53100A。其它型号根据厂家公开资料整理，细节以最新手册为准。）

| 型号 | AM/PM 分离方法 | 参考源结构 | 是否内置双通道互相关 |
|---|---|---|---|
| R&S FSWP | 模拟 I/Q 解调 | 双独立内部参考 | 是 |
| Microchip PhaseStation 53100A | 数字 I/Q 解调 | 双独立内部参考 | 是 |
| Holzworth HA7402B | PLL + 双平衡混频鉴相 | 双独立内部参考 | 是 |
| Noise XT DCNTS | PLL + 双平衡混频鉴相 | 双独立内部参考 | 是 |
| Keysight E5052B | PLL + 双平衡混频鉴相 | 单参考（标准） | 可选 |
| Anapico APPH6000 | PLL + 双平衡混频鉴相 | 双独立内部参考 | 是 |

### 10.2 四机对比示意曲线（原理建模）

下面这张图里：DUT 曲线按"一只典型 ULPN 100 MHz OCXO"的幂律参数构造；四台仪器的残余本底按"互相关 $M=100$、且各自内参考噪声水平略有差异"的原理模型画出来。**仪器曲线并非 KVG 公众号原文的实测数据**，只是帮助理解"同一 DUT 为什么不同仪器会给出不同但渐近一致的读数"：当 $M$ 足够大、DUT 足够好时，四条曲线都会收敛到最上方的那条 DUT 真实 ℒ(f)。

![图10  四台主流仪器对同一只 ULPN OCXO 的测量曲线示意（原理建模，非 KVG 原文实测）——差异来自内部参考源噪声 + 互相关次数 + 校准；DUT 足够好时曲线都趋于 DUT 真值。](/images/myimge/phase-noise-basics/fig10_four_instrument_comparison.png)

> 以上为经验梳理，不带有任何选型意见。仪器架构以各厂家最新手册为准。

---

## 小结

1. 写相位噪声数字：**必须写 `dBc/Hz @ f_offset from f0`**。三个字段少任何一个都缺信息。
2. 换算链：$\mathcal{L}(f)=S_\varphi/2$；抖动用带宽积分；$\sigma_y(\tau)$ 用幂律斜率查表即可判断一个"阿伦平台"到底对应 ℒ 曲线的哪一段。
3. 选测量方法：
   - 快速粗估 + 看杂散：直接频谱；
   - 数字解调、校准容易、相位/幅度同时看：I/Q 解调（53100A = 数字 I/Q，FSWP = 模拟 I/Q）；
   - 追求传统鉴相精度，且能容忍 PLL 闭环：PLL + 双平衡混频；
   - **只要 DUT 可能好于内部参考（几乎所有 ULPN OCXO / 超高稳振荡器都这样），就必须开双参考 + 互相关。**
4. 同样 DUT、不同仪器读数不同，首先看三件事：**互相关平均次数 M 是否一致、内参考源谁更干净、校准有没有做过。** 不是"谁的仪器更好"，而是"哪条曲线已经越过了参考源的天花板、真正读到 DUT 本身"。

正式操作、参数、连接和一次 100 MHz OCXO 的完整实测记录见姊妹篇：《[从近端噪声到远端噪声：用 53100A 测量 100 MHz OCXO 相位噪声](/2026/08/12/phase-noise-53100a-100mhz-ocxo/)》。
