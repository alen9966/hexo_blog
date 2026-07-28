---
title: 开关电源拓扑怎么选：从 Buck、Boost 到移相全桥
slug: power-topologies-selection-from-buck-to-psfb
date: 2026-07-28 14:00:00
tags:
  - 开关电源
  - 电源拓扑
  - Buck
  - Boost
  - 隔离电源
categories:
  - 学习记录
description: 结合电路结构、理想 CCM 变换关系和关键节点波形，系统梳理 Buck、Boost、Buck-Boost、SEPIC、Cuk、Zeta、Flyback、Forward、Push-Pull、Half-Bridge、Full-Bridge 与 PSFB。
banner: /images/myimge/power-topologies/power-topologies-handbook-cover.jpg
cover: /images/myimge/power-topologies/power-topologies-handbook-card.jpg
author: Alen
authorLink: https://github.com/alen9966
authorAbout: 从原理图到实测波形，记录硬件设计中的选择、失误与验证。
---

刚开始接触开关电源时，我很容易把拓扑选择理解成“降压用 Buck，升压用 Boost”。真正开始看器件应力和关键节点波形后才发现，升降压关系只是第一层：输入会不会跨过输出、是否隔离、能量在哪个开关状态送到负载、磁芯怎样复位、功率器件承受多大的峰值和 RMS 电流，都会改变最终选择。

这篇文章以 TI《Power Topologies Handbook》为主线，把文中出现的拓扑逐一展开。重点不是罗列名称，而是把每一种电路的功率路径、关键公式和电压电流波形对应起来。文中的波形来自手册，是理想化的理论波形，不是硬件实测；公式默认理想器件、稳态和连续导通模式（CCM），实际设计还要加入器件压降、死区、漏感、寄生参数和损耗。

## 一、先统一符号和读波形的方法

- $D$：占空比；除桥式拓扑另作说明外，表示一个周期内主开关导通时间占比。
- $f_s$：开关频率，周期 $T_s=1/f_s$。
- $n=N_s/N_p$：变压器次级对初级匝比。
- 红线：关键节点或磁性器件电压；蓝线：对应电流。
- $t_1$：主开关导通或正向传能区间；$t_2$：关断、续流或反向复位区间；$t_3$：DCM 中电流已经降为零的区间。

CCM 表示周期末电感电流仍大于零，DCM 表示电感电流会降到零，临界模式位于两者边界。对三角纹波叠加直流分量的 CCM 电流，常用近似为：

$$
I_{L,\mathrm{RMS}}=\sqrt{I_{L,\mathrm{avg}}^2+\frac{\Delta I_L^2}{12}},\qquad
I_{L,\mathrm{pk}}=I_{L,\mathrm{avg}}+\frac{\Delta I_L}{2}
$$

这两个量分别联系发热和饱和：铜损及导通损耗更关心 RMS，电感饱和和逐周期限流更关心峰值。

## 二、非隔离拓扑

### 1. Buck：导通时直接向输出传能

![异步 Buck 与同步 Buck 的功率级（TI《Power Topologies Handbook》SLYU036A，第 13 页局部）](/images/myimge/power-topologies/buck-asynchronous-and-synchronous.png)

Buck 只降压。Q1 导通时，电感两端为 $V_{in}-V_o$，电流线性上升；Q1 关断时，电感通过 D1 或同步下管续流，电感电压约为 $-V_o$，电流线性下降。对电感做一周期伏秒平衡：

$$
V_o=D V_{in}
$$

$$
\Delta I_L=\frac{(V_{in}-V_o)D}{L f_s}
=\frac{V_o(1-D)}{L f_s}
$$

![Buck 电感电压、电流在 CCM、DCM 和强制 PWM 下的理论波形（TI 手册第 14～15 页局部）](/images/myimge/power-topologies/buck-inductor-waveforms.png)

上半部分红色电压在 $t_1$ 为正、在 $t_2$ 为负，因此蓝色电感电流先升后降。CCM 波形有正的谷值；DCM 在 $t_3$ 贴近零；同步强制 PWM 允许电流穿过零点变为负值，轻载时可能把能量送回输入。异步 Buck 结构简单，同步 Buck 用 MOSFET 替代续流二极管，低压大电流时效率更高，但必须处理死区、体二极管导通和反向电流。

### 2. Boost：导通储能，关断升压

![Boost 功率级（TI 手册第 21 页局部）](/images/myimge/power-topologies/boost-converter-schematic.png)

Q1 导通时，D1 截止，电感承受 $V_{in}$ 并储能，输出暂时由 $C_o$ 供电；Q1 关断后，电感电压翻转，与输入串联向输出送能。理想 CCM 关系为：

$$
V_o=\frac{V_{in}}{1-D},\qquad
\Delta I_L=\frac{V_{in}D}{L f_s}
$$

![Boost 电感电压与电流的 CCM、DCM 理论波形（TI 手册第 22 页局部）](/images/myimge/power-topologies/boost-inductor-waveforms.png)

CCM 中，电感电流在整个周期连续，但输出只在关断区间接收电感电流。占空比突然增大时，当前周期的关断传能时间反而先缩短，所以 CCM Boost 存在右半平面零点（RHPZ）：

$$
f_{\mathrm{RHPZ}}\approx\frac{V_o(1-D)^2}{2\pi L I_o}
$$

控制环路交越频率要明显低于它。Boost 还没有天然的输入输出隔断：即使 Q1 永久关断，输入仍可能经 L1、D1 到达输出。

### 3. 反相 Buck-Boost：一只电感完成升降压

![反相 Buck-Boost 功率级（TI 手册第 28 页局部）](/images/myimge/power-topologies/inverting-buck-boost-schematic.png)

Q1 导通时，输入给 L1 储能，D1 截止；Q1 关断时，L1 通过 D1 向输出释放能量。由于输出参考方向与输入相反，理想关系带负号：

$$
V_o=-\frac{D}{1-D}V_{in},\qquad
\Delta I_L=\frac{V_{in}D}{L f_s}
$$

![反相 Buck-Boost 电感电压与电流的 CCM、DCM 理论波形（TI 手册第 29 页局部）](/images/myimge/power-topologies/inverting-buck-boost-inductor-waveforms.png)

红色电感电压在导通时为 $+V_{in}$，关断时约为 $V_o$，所以蓝色电流按两段线性斜率变化。开关和二极管关断电压均接近 $V_{in}+|V_o|$，不是只承受输入或输出。CCM 同样存在 RHPZ，按输出幅值写成：

$$
f_{\mathrm{RHPZ}}\approx\frac{|V_o|(1-D)^2}{2\pi D L I_o}
$$

它的优势是器件少，代价是反相输出、脉冲输出电流和较高器件应力。

### 4. SEPIC：同相升降压，输入电流连续

![SEPIC 功率级（TI 手册第 35 页局部）](/images/myimge/power-topologies/sepic-converter-schematic.png)

SEPIC 用 L1、L2 和串联耦合电容 C1 把输入与输出的直流分量隔开。Q1 导通时，L1 从输入储能，C1 同时给 L2 储能，D1 截止；Q1 关断时，两只电感共同经 D1 向输出送能。理想 CCM 变换比为：

$$
V_o=\frac{D}{1-D}V_{in}
$$

在稳态下，C1 的平均电压约等于 $V_{in}$；L1 输入电流连续，适合不希望输入端出现强脉冲电流的场景。以 L1 为例：

$$
\Delta I_{L1}\approx\frac{V_{in}D}{L_1f_s}
$$

![SEPIC 输入电感 L1 的电压、电流 CCM 与 DCM 理论波形（TI 手册第 36 页局部）](/images/myimge/power-topologies/sepic-key-waveforms.png)

波形说明 L1 电流在 CCM 连续，但二极管电流、Q1 电流和 C1 电流仍是脉冲量；C1 必须按 RMS 电流和纹波而不只是容量选型。其 CCM RHPZ 近似为：

$$
f_{\mathrm{RHPZ}}\approx\frac{V_o(1-D)^2}{2\pi D^2L_1I_o}
$$

SEPIC 解决了同相升降压，却付出了两个电感、一个能量传递电容以及更高 RMS 电流的代价。

### 5. Cuk：反相升降压，输入和输出电流都较连续

![Cuk 功率级（TI 手册第 45 页局部）](/images/myimge/power-topologies/cuk-converter-schematic.png)

Cuk 通过 C1 在输入侧 L1 和输出侧 L2 之间传递能量。Q1 导通时，L1 储能，同时 C1 经 Q1、L2 向输出侧送能；Q1 关断时，输入通过 L1、D1 给 C1 补充能量，L2 继续维持负载电流。理想关系为：

$$
V_o=-\frac{D}{1-D}V_{in}
$$

![Cuk 输入电感 L1 的电压、电流 CCM 与 DCM 理论波形（TI 手册第 46 页局部）](/images/myimge/power-topologies/cuk-input-inductor-waveforms.png)

L1 和 L2 分别让输入、输出电流连续，这是 Cuk 相比反相 Buck-Boost 最明显的端口特性。C1 是主能量传递元件，稳态平均电压约为 $V_{in}+|V_o|$，同时承受较大的交流电流。它适合重视输入输出电流连续性的场合，但需要接受反相输出、器件数量和电容应力。

### 6. Zeta：同相升降压，输出电流连续

![Zeta 功率级（TI 手册第 55 页局部）](/images/myimge/power-topologies/zeta-converter-schematic.png)

Zeta 可视为 SEPIC 的互补形式。Q1 导通时，输入经 Q1、C1 和 L2 直接参与向输出传能，同时 L1 建立磁能；Q1 关断时，D1 提供续流路径，L2 继续给负载供电。理想 CCM 关系同样是：

$$
V_o=\frac{D}{1-D}V_{in}
$$

![Zeta 输入侧电感 L1 的电压、电流 CCM 与 DCM 理论波形（TI 手册第 56 页局部）](/images/myimge/power-topologies/zeta-input-inductor-waveforms.png)

Zeta 的输出电流由 L2 平滑，因此连续；输入侧开关电流则更脉冲。选择它通常是为了同相升降压和连续输出电流，而不是为了最少器件。L1、L2、C1 的纹波和 RMS 电流仍需要逐一计算。

## 三、Flyback 家族：磁芯先储能，再向次级释放

### 7. 单管 Flyback

![单管 Flyback 功率级（TI 手册第 65 页局部）](/images/myimge/power-topologies/flyback-converter-schematic.png)

Flyback 的磁性器件本质上是带多绕组的储能电感。Q1 导通时，初级承受 $+V_{in}$，初级电流按 $V=L\,di/dt$ 上升；由于绕组同名端关系，次级 D1 反偏，磁芯在气隙中储能。Q1 关断后，绕组电压反向，D1 导通，次级电流从峰值向下下降并给 $C_o$ 和负载供能。

理想 CCM 变换比和初级纹波为：

$$
V_o=n\frac{D}{1-D}V_{in},\qquad
\Delta I_p=\frac{V_{in}D}{L_pf_s}
$$

![Flyback 初级电压、电流在 CCM、DCM 和临界模式下的理论波形（TI 手册第 67 页局部）](/images/myimge/power-topologies/flyback-primary-waveforms.png)

左列 CCM 的初级电流从非零谷值上升，关断后初级开关支路电流立刻为零；中列 DCM 在 $t_3$ 出现磁化电流归零区；右列临界模式刚好在下一周期前降到零。图中的蓝线是初级绕组/开关时段电流，并不表示磁芯能量在关断瞬间消失，而是能量已经转移到次级。

![Flyback 次级绕组电压与整流电流的 CCM 理论波形（TI 手册第 68 页局部）](/images/myimge/power-topologies/flyback-secondary-waveforms.png)

次级电流只出现在 Q1 关断期间，起点约为初级关断电流按匝比反射后的值，再线性下降。输出电容因此要吸收脉冲充电电流。MOSFET 的关断电压不能只按输入选：

$$
V_{DS,off}\approx V_{in}+\frac{N_p}{N_s}(V_o+V_D)+V_{spike}
$$

$V_{spike}$ 主要来自漏感，通常由 RCD、TVS 或有源钳位限制。在 DCM 的第一轮能量估算中，每周期储能为 $\tfrac12L_pI_{pk}^2$：

$$
P_o\approx\eta\frac{1}{2}L_pI_{pk}^2f_s
$$

CCM Flyback 也有“先缩短次级传能时间”的 RHPZ，补偿带宽需要保守处理。多路输出、器件少和易隔离是它的优势；峰值电流、漏感尖峰、变压器气隙和交叉调整率是主要代价。

### 8. 双管 Flyback：用两个开关钳住电压

![双管 Flyback 功率级（TI 手册第 76 页局部）](/images/myimge/power-topologies/two-switch-flyback-schematic.png)

Q1、Q2 同时导通时，初级承受 $V_{in}$ 并储能；两管同时关断时，D3、D4 把漏感和复位能量送回输入，次级向输出放能。理想变换比仍是：

$$
V_o=n\frac{D}{1-D}V_{in}
$$

![双管 Flyback 初级电压、电流的 CCM 与 DCM 理论波形（TI 手册第 78 页局部）](/images/myimge/power-topologies/two-switch-flyback-primary-waveforms.png)

相较单管 Flyback，每只 MOSFET 的理想电压应力被钳在约 $V_{in}$，而不是 $V_{in}$ 再叠加反射输出电压；实际仍要留寄生尖峰裕量。代价是两只功率管、两路驱动和两个钳位二极管，复位要求也通常把占空比限制在 0.5 以下。

## 四、Forward 家族：开通时直接向次级传能

Forward 与 Flyback 的根本差异是能量时序。主开关导通时，变压器立即把能量送到次级，输出电感 L1 负责平滑；关断时，次级整流管截止，续流管让输出电感继续供电。三种 Forward 的理想 CCM 主关系相同：

$$
V_o\approx DnV_{in}
$$

$$
\Delta I_L=\frac{(nV_{in}-V_o)D}{Lf_s}
=\frac{V_o(1-D)}{Lf_s}
$$

它们真正不同的是磁化电流怎样复位、主开关承受多高电压，以及能否回收复位能量。

### 9. 有源钳位 Forward

![有源钳位 Forward 功率级（TI 手册第 85 页局部）](/images/myimge/power-topologies/active-clamp-forward-schematic.png)

Q1 导通时，初级加正电压，次级 D1 导通，输出电感电流上升。Q1 关断后，钳位管 Q2 与 C1 给磁化电流提供通路，初级出现反向复位电压；次级转入 D2 续流，输出电感电流下降。理想稳态钳位电容电压可近似理解为：

$$
V_{clamp}\approx\frac{V_{in}}{1-D}
$$

![有源钳位 Forward 的初级与输出电感关键理论波形，上半为变压器初级，下半为输出电感（TI 手册第 87、89 页局部）](/images/myimge/power-topologies/active-clamp-forward-key-waveforms.png)

上半图中，初级电压在 $t_1$ 为正、$t_2$ 为负，负电压完成磁通复位；初级电流在关断区间仍可沿钳位支路流动。下半图中，输出电感电压一正一负，对应连续的三角电流。有源钳位可以回收磁化和漏感能量，并在合适的寄生参数、负载和死区条件下形成 ZVS，但不能只凭拓扑名称保证全负载软开关。

### 10. 单管 Forward

![单管 Forward 功率级（TI 手册第 98 页局部）](/images/myimge/power-topologies/single-switch-forward-schematic.png)

单管 Forward 用复位绕组 $N_d$ 和二极管 D3 在 Q1 关断后给初级施加反向电压。若 $N_d=N_p$，复位时间至少等于导通时间，因此：

$$
D_{max}\le\frac{N_p}{N_p+N_d}=0.5
$$

主开关理想关断应力近似为：

$$
V_{DS,max}\approx V_{in}\left(1+\frac{N_p}{N_d}\right)
$$

一比一复位绕组时约为 $2V_{in}$，还要再计漏感尖峰。

![单管 Forward 的初级复位与输出电感关键理论波形，上半为变压器初级，下半为输出电感（TI 手册第 100、102 页局部）](/images/myimge/power-topologies/single-switch-forward-key-waveforms.png)

初级红色波形在 $t_1$ 为 $+V_{in}$，随后在复位区间 $t_d$ 为负；伏秒面积必须相等，否则磁通会逐周期偏移。输出电感的蓝色电流在 CCM 不归零，在 DCM 则经历上升、下降和零电流三个区间。

### 11. 双管 Forward

![双管 Forward 功率级（TI 手册第 111 页局部）](/images/myimge/power-topologies/two-switch-forward-schematic.png)

Q1、Q2 同时导通，把输入电压加到初级；关断后 D3、D4 同时导通，把磁化能量回送输入，并将两只 MOSFET 的理想关断电压各自钳在约 $V_{in}$。输出侧仍是 D1 整流、D2 续流，所以变换比仍为 $V_o\approx DnV_{in}$。

![双管 Forward 的初级与输出电感关键理论波形，上半为变压器初级，下半为输出电感（TI 手册第 113、115 页局部）](/images/myimge/power-topologies/two-switch-forward-key-waveforms.png)

初级波形有正向传能和负向复位两段，因此占空比通常小于 0.5。它比单管方案多一只 MOSFET 和一路驱动，却显著降低单管电压应力，且钳位路径明确，适合较高输入电压的硬开关 Forward。

## 五、双端与桥式拓扑：让变压器双向励磁

### 12. Push-Pull：两半初级交替工作

![Push-Pull 功率级（TI 手册第 123 页局部）](/images/myimge/power-topologies/push-pull-converter-schematic.png)

Q1、Q2 交替导通，每次驱动中心抽头初级的一半，次级经全波整流后向输出电感送能。若 $D$ 表示每只开关相对完整周期的导通占比，则每周期有两个传能脉冲：

$$
V_o\approx2DnV_{in},\qquad D<0.5
$$

![Push-Pull 的初级与输出电感关键理论波形，上半为变压器初级，下半为输出电感（TI 手册第 125、129 页局部）](/images/myimge/power-topologies/push-pull-key-waveforms.png)

初级红色电压正负交替，磁芯双向励磁；次级整流后，输出电感每周期得到两次正向电压脉冲。两路驱动、开关参数或半绕组匝数稍有不对称，都可能产生伏秒不平衡并推动磁芯偏磁。关断开关电压通常接近 $2V_{in}$ 再叠加尖峰，因此它更适合低压、大电流输入，而不是高压母线。

### 13. Half-Bridge：初级得到正负半母线电压

![Half-Bridge 功率级（TI 手册第 148 页局部）](/images/myimge/power-topologies/half-bridge-schematic.png)

两个 MOSFET 交替导通，分压电容把初级一端维持在母线中点，因此变压器承受约 $+V_{in}/2$ 和 $-V_{in}/2$。若 $D$ 是每只开关在完整周期中的导通占比，则：

$$
V_o\approx DnV_{in}
$$

![Half-Bridge 的初级与输出电感关键理论波形，上半为变压器初级，下半为输出电感（TI 手册第 150、153 页局部）](/images/myimge/power-topologies/half-bridge-key-waveforms.png)

上半图的初级电压幅值只有半母线，但正负交替；下半图显示次级全波整流后，输出电感在两个传能区间上升，在间隔区间下降。每只 MOSFET 的关断电压约为 $V_{in}$。设计重点是分压电容的容量、纹波电流和中点平衡，任何长期直流偏置都会影响磁通对称性。

### 14. Full-Bridge：初级得到完整正负母线电压

![Full-Bridge 功率级（TI 手册第 161 页局部）](/images/myimge/power-topologies/full-bridge-schematic.png)

两组对角管交替导通，初级得到 $+V_{in}$ 和 $-V_{in}$。若 $D$ 表示每组对角管相对完整周期的导通占比，则：

$$
V_o\approx2DnV_{in}
$$

![Full-Bridge 的初级与输出电感关键理论波形，上半为变压器初级，下半为输出电感（TI 手册第 163、166 页局部）](/images/myimge/power-topologies/full-bridge-key-waveforms.png)

它与 Half-Bridge 的波形形状相似，但初级电压幅值翻倍，因此同一母线和匝比下可以传递更高功率。每只 MOSFET 仍主要承受母线电压。代价是四只功率管、两组高侧驱动以及严格的死区和直通保护；硬开关时，开关损耗也会限制频率。

### 15. Phase-Shifted Full-Bridge：用相移调节有效脉宽

![移相全桥功率级（TI 手册第 174 页局部）](/images/myimge/power-topologies/phase-shifted-full-bridge-schematic.png)

PSFB 的每只 MOSFET 通常保持接近 50% 占空比，控制量是两桥臂之间的相移。桥臂状态相反时，初级得到 $+V_{in}$ 或 $-V_{in}$；两桥臂同为高电平或同为低电平时，初级电压为零，电流在桥内续流。定义变压器的有效占空比为 $D_{eff}$：

$$
V_o\approx D_{eff}nV_{in}
$$

![PSFB 的初级相移与输出电感关键理论波形，上半为变压器初级，下半为输出电感（TI 手册第 175、177 页局部）](/images/myimge/power-topologies/phase-shifted-full-bridge-key-waveforms.png)

上半图的 $t_{ph}$ 是相移造成的零电压续流区间；相移越大，有效加在变压器上的脉宽越短。初级电流在零电压区仍可能循环，这部分电流不向输出传递有效功率，却会增加导通损耗。换相时，漏感或外加串联电感的能量可以给 MOSFET 输出电容充放电，形成 ZVS。一个直观的必要条件是：

$$
\frac12L_{eq}I_{pri}^2\gtrsim\frac12C_{oss,eq}V_{in}^2
$$

负载变轻后 $I_{pri}$ 下降，换相能量可能不足，ZVS 会丢失。TI 手册这一章的计算前提是约 50%～100% 负载实现 ZVS，不能把它外推成全负载保证。PSFB 还要检查环流、占空比丢失、次级整流尖峰和领先/滞后桥臂的换相差异。

## 六、把拓扑放到同一张选择表里

| 需求 | 优先比较 | 关键代价 |
|---|---|---|
| 非隔离、固定降压 | Buck、同步 Buck | 最大占空比、低压大电流损耗、负载瞬态 |
| 非隔离、固定升压 | Boost | RHPZ、输出不可天然关断、器件电压应力 |
| 输入跨过输出、允许反相 | 反相 Buck-Boost、Cuk | 反相输出、RHPZ或能量电容应力 |
| 输入跨过输出、要求同相 | SEPIC、Zeta | 两个电感、耦合电容、RMS 电流 |
| 隔离、器件数优先 | 单管 Flyback | 峰值电流、漏感尖峰、气隙、交叉调整率 |
| 隔离、希望降低单管应力 | 双管 Flyback | 两只开关、驱动和占空比限制 |
| 隔离、开通时直接传能 | 单管/双管/有源钳位 Forward | 磁芯复位、输出电感、钳位设计 |
| 低压大电流输入 | Push-Pull | 偏磁、开关约两倍输入电压应力 |
| 较高功率隔离 | Half-Bridge、Full-Bridge | 驱动复杂度、磁通平衡、硬开关损耗 |
| 较高功率且希望软开关 | PSFB | 轻载 ZVS、环流、占空比丢失 |

初选以后，我会按同一顺序继续计算：先用伏秒平衡得到占空比和电感纹波，再计算每只 MOSFET、二极管、绕组和电容的峰值及 RMS 电流；随后加入漏感、寄生电容、死区和压降重新检查应力；最后建立小信号模型，确认 RHPZ、交越频率和相位裕量，并通过样机验证效率、温升、纹波、负载瞬态、启动与保护。

这篇文章完成的是拓扑结构、理想关系和理论波形的对应。它可以用于缩小候选范围，但不能代替具体控制器数据手册、磁芯设计和硬件实测。

## 参考资料

- Texas Instruments, *Power Topologies Handbook*, SLYU036A, Rev. A, 2024.
- Robert W. Erickson, Dragan Maksimović, *Fundamentals of Power Electronics*.
