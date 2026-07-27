---
title: 从一个多路选择器开始学 Verilog：module、assign 和 always
slug: verilog-from-module-to-always
date: 2026-07-27 11:30:00
tags:
  - Verilog
  - FPGA
  - RTL
  - 数字电路
categories:
  - 学习记录
description: 从二选一多路选择器出发，理解 Verilog 模块、连续赋值、过程块、阻塞与非阻塞赋值，以及 wire、reg 和锁存器之间的关系。
banner: /images/myimge/wallhaven-pink/wallhaven-x6xq2v.jpg
cover: /images/myimge/wallhaven-pink/wallhaven-vq95d8.jpg
author: Alen
authorLink: https://github.com/alen9966
authorAbout: 从原理图到实测波形，记录硬件设计中的选择、失误与验证。
---

我刚开始学 Verilog 时，最容易犯的错误是把它当成 C 语言：代码从上往下执行，写几行判断和赋值，就能得到想要的结果。可真正开始写 FPGA 程序后会发现，同样是一个等号，放在 `assign` 里和放在 `always` 里含义不同；同样是 `always`，敏感列表写信号变化和写时钟上升沿，最后得到的电路也完全不同。

Verilog 不是在告诉处理器“下一步做什么”，而是在描述一块数字电路“由什么组成、信号怎样连接、什么时候更新”。这篇文章从最简单的多路选择器开始，把 `module`、`assign`、`always`、阻塞赋值和非阻塞赋值串起来。资料采用传统 Verilog-2001 的 `wire`、`reg` 写法，暂不展开 SystemVerilog。

## 一、先把代码当成电路

二选一多路选择器有两个数据输入、一个选择信号和一个输出。选择信号为 `0` 时输出其中一路，为 `1` 时输出另一路。这个功能既可以画成一个 MUX 符号，也可以展开成非门、与门和或门。

![二选一多路选择器的符号、门级结构和波形（《Verilog语言知识学习快速基础学习》第 3 页）](/images/myimge/verilog-basics/mux-hardware-waveform-slide-3.png)

从波形上看，`sel` 改变后，输出 `y` 跟着切换。这里没有时钟，也不需要记住上一次结果，因此它是组合逻辑。用 Verilog 描述时，可以直接写：

```verilog
module mux2 (
    input  wire a,
    input  wire b,
    input  wire sel,
    output wire y
);

assign y = sel ? b : a;

endmodule
```

这段代码不是先声明输入、再执行 `assign`、最后执行 `endmodule`。综合工具会把它理解成一个电路模块，其中 `sel ? b : a` 对应选择关系。只要 `a`、`b` 或 `sel` 发生变化，`y` 就按新的组合结果变化。

## 二、module 定义了电路的边界

首先看最外层结构：

```verilog
module 模块名 (
    端口列表
);

    内部信号和功能描述

endmodule
```

`module` 和 `endmodule` 圈出一块电路。端口就是这块电路与外部连接的引脚，`input`、`output` 和 `inout` 分别表示输入、输出和双向端口。位宽写成 `[高位:低位]`，例如 `[3:0]` 表示 4 位信号。

![模块端口、位宽和符号之间的关系（《Verilog语言知识学习快速基础学习》第 7 页）](/images/myimge/verilog-basics/verilog-module-and-port-example-slide-7.png)

以 4 位输入为例：

```verilog
module full_adder (
    input  wire [3:0] a,
    input  wire [3:0] b,
    input  wire       cin,
    output wire [3:0] sum,
    output wire       cout
);

// 功能描述略

endmodule
```

这里 `[3:0]` 对应 `a[3]` 到 `a[0]` 四根线。端口没有写位宽时默认是 1 位，但工程中最好把位宽写清楚。模块名和文件名在 Verilog 语法上不要求一致，不过保持一致更方便工程管理和查找顶层模块。

模块里面最常见的描述方式有三种：

- `assign` 连续赋值；
- `always` 过程块；
- 调用已经写好的底层模块或门原语。

它们在模块中是并行存在的，书写顺序通常不表示硬件工作的先后顺序。

## 三、assign 适合直接描述组合关系

`assign` 的基本格式是：

```verilog
assign 目标信号 = 表达式;
```

例如一个与或逻辑：

```verilog
wire m;

assign m = b | c;
assign y = a & m;
```

两条 `assign` 同时描述两段组合逻辑，并不是先算 `m` 再执行下一行。实际电路中，`m` 是前一级逻辑的输出，也是后一级逻辑的输入。输入变化经过门延迟传播后，整个组合网络会得到新的稳定值。

为什么 `assign` 的目标通常写成 `wire`？因为它描述的是一根被持续驱动的连线，不需要在过程块内部保存一个变量值。表达式中可以使用算术、逻辑、关系、按位、移位、拼接和条件运算符，但要特别注意位宽。

例如：

```verilog
wire [3:0] a = 4'b1001;
wire [3:0] y;

assign y = a << 1;
```

`y` 仍然只有 4 位，因此最高位移出去以后不会自动保留。Verilog 中很多看起来奇怪的计算结果，最后都能追到位宽、符号位或常量写法上。

## 四、always 不是“按顺序一直执行”

`always` 的基本形式为：

```verilog
always @(触发条件) begin
    过程语句
end
```

关键不只是里面写了什么，还要看它什么时候被触发。

### 1. 组合逻辑过程块

二选一多路选择器也可以用 `always` 描述：

```verilog
module mux2_always (
    input  wire a,
    input  wire b,
    input  wire sel,
    output reg  y
);

always @(*) begin
    if (sel)
        y = b;
    else
        y = a;
end

endmodule
```

`@(*)` 表示只要过程块读取的任意信号发生变化，就重新计算一次。旧式代码会把敏感信号手工写成 `@(a or b or sel)`，但漏掉一个信号会造成仿真结果与综合电路不一致，因此组合逻辑优先使用 `@(*)`。

这里的 `y` 声明为 `reg`，只是因为它在过程块中被赋值，并不表示综合后一定出现寄存器。这个过程对 `sel=0` 和 `sel=1` 都给出了 `y`，所以综合结果仍然是组合逻辑。

### 2. 时序逻辑过程块

如果敏感条件改成时钟上升沿，含义就不同了：

```verilog
module dff (
    input  wire clk,
    input  wire rst_n,
    input  wire d,
    output reg  q
);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        q <= 1'b0;
    else
        q <= d;
end

endmodule
```

正常工作时，只有 `clk` 上升沿到来，`q` 才采样 `d`。两个时钟沿之间即使 `d` 改变，`q` 仍保持原值。`rst_n` 写在敏感列表中，表示这里采用低电平异步复位。

所以区分组合逻辑和时序逻辑时，不能只看有没有 `always`。真正需要看的是触发条件，以及输出是否需要跨时间保存状态。

## 五、阻塞赋值和非阻塞赋值

Verilog 过程块中有两种赋值符号：

```verilog
y = expression;   // 阻塞赋值
y <= expression;  // 非阻塞赋值
```

阻塞赋值 `=` 会在当前过程内完成计算和更新，后面的语句能够读到新值。非阻塞赋值 `<=` 会先计算右侧表达式，再把左侧更新安排到当前仿真时间片的非阻塞赋值阶段，因此同一时钟沿触发的各级寄存器读到的是更新前的值。

![阻塞赋值和非阻塞赋值读取新旧值的对比（《Verilog语言知识学习快速基础学习》第 31 页）](/images/myimge/verilog-basics/blocking-nonblocking-example-slide-31.png)

以两级移位寄存器为例：

```verilog
always @(posedge clk) begin
    q1 <= d;
    q2 <= q1;
end
```

时钟上升沿到来时，`q1` 准备接收 `d`，`q2` 准备接收旧的 `q1`。这样才能得到两级寄存器。如果改成阻塞赋值：

```verilog
always @(posedge clk) begin
    q1 = d;
    q2 = q1;
end
```

第二行会读到刚刚更新的 `q1`，仿真行为不再是预期的两级延迟。

入门时可以先记住一条工程规则：组合逻辑过程块使用阻塞赋值 `=`，时钟触发的时序逻辑使用非阻塞赋值 `<=`，不要在同一个过程块里混用。它不是 Verilog 语法的全部边界，但能避开大多数初学阶段的仿真问题。

## 六、wire 和 reg 到底表示什么

传统 Verilog 中，`wire` 属于线网类型，`reg` 属于变量类型。二者的区别主要是由谁来驱动，而不是看信号名称像不像寄存器。

`wire` 常用于：

- `assign` 的赋值目标；
- 模块实例的连接线；
- 门原语的输出；
- 输入端口。

`reg` 常用于 `always` 或 `initial` 过程块中的赋值目标。一个 `reg` 最终可能综合成触发器、锁存器，也可能只是组合逻辑输出。综合成什么，取决于过程块是否在所有情况下完成赋值，以及过程块由电平变化还是时钟边沿触发。

SystemVerilog 中常使用 `logic` 代替很多 `reg` 声明，但驱动规则和组合、时序逻辑的区别仍然存在。本文继续使用 PPT 中的 Verilog-2001 写法，避免把两套语法混在一起。

## 七、if 和 case 为什么会综合出锁存器

使用 `if` 或 `case` 描述组合逻辑时，输出必须在所有可能路径中得到赋值。如果有一条路径没有赋值，电路就需要保留上一次结果，综合工具只能加入锁存器。

下面的写法条件不完整：

```verilog
always @(*) begin
    if (en)
        y = d;
end
```

当 `en=0` 时没有说明 `y` 应该是多少，于是 `y` 必须记住原值。改成完整条件即可：

```verilog
always @(*) begin
    if (en)
        y = d;
    else
        y = 1'b0;
end
```

`case` 也一样。四选一多路选择器可以写成：

```verilog
module mux4 (
    input  wire       d0,
    input  wire       d1,
    input  wire       d2,
    input  wire       d3,
    input  wire [1:0] sel,
    output reg        y
);

always @(*) begin
    case (sel)
        2'b00: y = d0;
        2'b01: y = d1;
        2'b10: y = d2;
        2'b11: y = d3;
        default: y = 1'b0;
    endcase
end

endmodule
```

对于 2 位 `sel`，四个取值已经写全，`default` 理论上不会处理新的二进制组合。不过仿真中还存在 `x` 和 `z`，保留 `default` 能让未确定状态的处理更明确。

## 八、调用底层模块就是连接现成电路

一个工程不可能把所有逻辑都塞进同一个 `module`。更常见的做法是先写好 D 触发器、计数器、滤波器或通信接口，再在顶层模块中实例化它们。

![命名端口映射与顺序端口映射（《Verilog语言知识学习快速基础学习》第 36 页）](/images/myimge/verilog-basics/module-port-mapping-slide-36.png)

假设已经有一个 `dff` 模块，命名端口映射写法为：

```verilog
dff u_dff1 (
    .clk   (clk),
    .rst_n (rst_n),
    .d     (d1),
    .q     (q1)
);
```

点号后面是底层模块的端口名，括号里面是当前模块的连接信号。命名映射不依赖端口声明顺序，阅读时也能直接知道每根线接到哪里，因此工程中通常优先使用。

顺序映射也能工作：

```verilog
dff u_dff2 (clk, rst_n, d2, q2);
```

但只要底层模块调整端口顺序，或者调用处少看了一位，就可能接错。模块实例越来越多以后，命名端口带来的几行额外代码通常是值得的。

## 九、写完一个模块后检查什么

一段代码能够通过语法检查，不代表它一定描述了想要的硬件。我现在写完一个基础模块后，会先检查下面几件事：

- 输入、输出和内部信号的位宽是否一致；
- 组合逻辑是否使用 `@(*)`，每个输出是否在所有路径中赋值；
- 时序逻辑是否统一使用非阻塞赋值 `<=`；
- `reg` 是否真的因为过程赋值而声明，而不是因为名字像寄存器；
- 模块实例是否使用命名端口，方向和位宽是否对应；
- 常量是否写清位宽和进制，例如 `4'b0011`；
- 仿真中是否考虑 `x`、复位和边界输入。

Verilog 入门真正需要建立的不是关键字清单，而是代码与电路之间的对应关系。`module` 定义边界，`assign` 描述持续存在的组合关系，`always @(*)` 描述组合过程，`always @(posedge clk)` 描述时钟触发的状态更新。把这几层关系分清以后，再学习计数器、状态机和接口时，代码就不会只剩下语法。

这篇文章目前只整理了语言基础和综合习惯，没有加入具体 FPGA 工程、时序约束和板级测试结果。后面真正建立 Quartus 或 Vivado 工程时，还需要补上 testbench、波形仿真、引脚约束和时序分析。

## 资料来源

- 《Verilog语言知识学习快速基础学习》：模块结构、多路选择器、连续赋值、过程块、阻塞与非阻塞赋值、数据类型及模块调用，正文图片分别截取自第 3、7、31、36 页。
