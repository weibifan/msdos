# 游戏主机模拟器技术文档

> 经典游戏主机模拟器技术概述——发展历史、精度策略、代表作品一览。

## 主机模拟 vs DOS 模拟

主机模拟器与 DOS 模拟器的工作原理不同。DOS 模拟器模拟的是**一个平台**（x86 PC + 特定硬件组合），而主机模拟器针对的是**一台硬件完全确定的机器**——CPU、GPU、内存映射和 I/O 都是已知常量。这使得周期精确（cycle-accurate）模拟成为可能。

## 主流主机模拟器

### NES / 红白机（1983，任天堂）

| 规格 | 详情 |
|------|------|
| **CPU** | MOS 6502 @ 1.79 MHz（RP2A03） |
| **GPU** | Ricoh 2C02 PPU（专用图像处理器） |
| **分辨率** | 256×240 |
| **颜色** | 共 64 色（8 个调色板 × 4 色），每扫描线最多 25 色 |
| **瓦片格式** | 2BPP（每像素 2 位），8×8 瓦片 |
| **音效** | 5 通道：2 脉冲波、1 三角波、1 噪声、1 DPCM |
| **介质** | 卡带（通过映射器最高 1 MB） |

**代表模拟器：**

| 模拟器 | 平台 | 特点 |
|----------|----------|------------------|
| **Mesen** | Windows/Linux | 高精度，完整调试器，跟踪日志 |
| **Nestopia UE** | Windows/macOS/Linux | 周期精确 PPU，联网对战 |
| **FCEUX** | Windows/macOS/Linux | 最古老活跃的 NES 模拟器，Lua 脚本 |
| **puNES** | Windows/Linux | Qt 界面，专注周期精度 |
| **Nintendulator** | Windows | 映射器支持全面，兼容罕见 mapper |

### SNES / 超级任天堂（1990，任天堂）

| 规格 | 详情 |
|------|------|
| **CPU** | 65C816 @ 3.58 MHz |
| **GPU** | PPU1 + PPU2（双芯片） |
| **分辨率** | 256×224 / 512×224 |
| **颜色** | 32,768 色中选 256 |
| **模式** | Mode 0–7（瓦片、旋转、缩放、仿射变换） |
| **音效** | S-DSP（8 通道，ADPCM） |
| **特殊芯片** | Super FX（星际火狐）、SA-1、DSP-1、CX4 |

**代表模拟器：**

| 模拟器 | 平台 | 特点 |
|----------|----------|------------------|
| **bsnes / higan** | Windows/Linux | 周期精确，byuu 开发 |
| **higan** | 多系统 | SNES + NES + GB + GBA + SMS + GG + SG |
| **Snes9x** | Windows/macOS/Linux | 轻量，速度与精度平衡 |
| **Mesen-S** | Windows/Linux | 高精度，调试器，Mesen 的 SNES 分支 |
| **ZSNES** | Windows/DOS/Linux | 传奇速度（约 1997），精度已过时 |

### 世嘉 Genesis / Mega Drive（1988，世嘉）

| 规格 | 详情 |
|------|------|
| **CPU** | Motorola 68000 @ 7.67 MHz + Z80 @ 3.58 MHz |
| **GPU** | Yamaha YM7101 VDP |
| **分辨率** | 320×224 |
| **颜色** | 512 色中选 61（3 个调色板 × 16） |
| **音效** | YM2612（6 FM 通道）+ SN76489 PSG |
| **介质** | 卡带（通过 Bank 切换最高 8 MB） |

**代表模拟器：**

| 模拟器 | 平台 | 特点 |
|----------|----------|------------------|
| **Kega Fusion** | Windows | 其时代最佳精度，32X + Sega CD 支持 |
| **BlastEm** | Windows/Linux | 周期精确，活跃开发 |
| **Genesis Plus GX** | 多平台（libretro） | 精度高，RetroArch 核心 |
| **Exodus** | Windows | 调试器导向，极高精度 |
| **Genecyst** | DOS | 经典 DOS 模拟器（Bloodlust Software，1997） |

Genecyst 是一个**原生 DOS 模拟器**，无需操作系统支持——通过 DOS4GW（DOS 保护模式接口）实现 32 位寻址，直接操作 VGA 硬件。这使它非常独特：可以在 DOSBox 内嵌套运行（Genesis 模拟器放在 DOS 模拟器里面）。

### PlayStation / PS1（1994，索尼）

| 规格 | 详情 |
|------|------|
| **CPU** | MIPS R3000A @ 33.87 MHz |
| **GPU** | 定制 GPU（几何 + 光栅化） |
| **分辨率** | 256×224 至 640×480 |
| **颜色** | 1670 万色（24 位，抖动处理） |
| **音效** | SPU（24 通道，ADPCM） |
| **介质** | CD-ROM（650 MB） |
| **内存** | 2 MB 主存、1 MB 显存、512 KB 音效 |

**代表模拟器：**

| 模拟器 | 平台 | 特点 |
|----------|----------|------------------|
| **DuckStation** | Windows/Linux | 现代、精确、活跃开发 |
| **ePSXe** | Windows/Android | 历史最久，插件架构 |
| **PCSX-R** | Windows/Linux | PCSX 的开源分支 |
| **Mednafen** | 多系统 | 高精度，纯命令行 |
| **PCSX2** (PS2) | Windows/Linux | PS2 模拟器，兼 PS1 兼容 |

### Game Boy / GBC（1989，任天堂）

| 规格 | 详情 |
|------|------|
| **CPU** | Sharp LR35902（定制 8080 类）@ 4.19 MHz |
| **GPU** | 集成 LCD 控制器 |
| **分辨率** | 160×144 |
| **颜色** | 4 灰阶（GB），56 色（GBC） |
| **音效** | 4 通道（2 脉冲、1 波形、1 噪声） |
| **介质** | 卡带（最高 8 MB，电池备份 SRAM） |

**代表模拟器：**

| 模拟器 | 平台 | 特点 |
|----------|----------|------------------|
| **mGBA** | Windows/macOS/Linux | 现代高精度，活跃开发 |
| **VisualBoyAdvance** | Windows/macOS/Linux | 历史最久，也支持 GBA |
| **BGB** | Windows | 极高精度，优秀调试器 |
| **Gambatte** | 多平台（libretro） | 周期精确，DMG/CGB 支持 |
| **SameBoy** | Windows/macOS/Linux | 最高精度，可通过 PicoBoot 在真机运行 |

### Game Boy Advance（2001，任天堂）

| 规格 | 详情 |
|------|------|
| **CPU** | ARM7TDMI @ 16.78 MHz |
| **GPU** | 集成 2D 渲染器 |
| **分辨率** | 240×160 |
| **颜色** | 32,768 色 |
| **模式** | 瓦片（4/8 bpp）+ 位图（Mode 3/4/5） |
| **音效** | 6 通道（2 脉冲、1 波形、1 噪声 + 2 DMA） |

**代表模拟器：**

| 模拟器 | 平台 | 特点 |
|----------|----------|------------------|
| **mGBA** | Windows/macOS/Linux | 当前黄金标准 |
| **VisualBoyAdvance-M** | Windows/macOS/Linux | VBA 分支，仍在维护 |
| **NanoBoyAdvance** | Windows | 周期精确，较新项目 |
| **Mednafen** | 多系统 | 高精度，使用 SameBoy 的 GBA 核心 |

### Nintendo 64（1996，任天堂）

| 规格 | 详情 |
|------|------|
| **CPU** | MIPS R4300i @ 93.75 MHz |
| **GPU** | SGI RCP（Reality Co-Processor） |
| **分辨率** | 320×240 至 640×480 |
| **颜色** | 1670 万色 |
| **音效** | SGI RSP（Reality Signal Processor） |
| **介质** | 卡带（最高 64 MB） |
| **内存** | 4 MB RAMBUS（可扩展至 8 MB） |

**代表模拟器：**

| 模拟器 | 平台 | 特点 |
|----------|----------|------------------|
| **Project64** | Windows | 历史最久，插件架构 |
| **Mupen64Plus** | Windows/Linux | 开源，跨平台 |
| **Simple64** | Windows/Linux | Mupen64Plus 的现代分支 |
| **Ares** | 多系统 | 高精度，代码整洁 |
| **ParaLLEl** | 多平台（libretro） | Vulkan 后端，高精度 RSP |

### 街机 / MAME

| 规格 | 详情 |
|------|------|
| **目标** | 模拟历史上任何一台街机 |
| **首发** | 1997（Nicola Salmoria） |
| **ROM** | 需要原始街机 ROM dump（法律灰色地带） |
| **BIOS** | 许多街机 PCB 拥有自己的 BIOS/OS |

MAME（Multiple Arcade Machine Emulator）非常独特：它记录和模拟的是每块街机板的**精确硬件**，而非仅仅是游戏逻辑。截至 2026 年，它支持**超过 45,000 个独立 ROM set**。

### RetroArch

| 项目 | 详情 |
|------|------|
| **类型** | 前端 / 启动器（本身不是模拟器） |
| **API** | libretro — 模拟器核心标准化接口 |
| **平台** | Windows、macOS、Linux、Android、iOS、游戏主机等 |
| **首发** | 2010 年 |
| **协议** | GPLv3 |

RetroArch 是一个基于 **libretro API** 构建的跨平台前端。它本身不模拟任何硬件，而是加载**核心**（动态库）来实现模拟功能。本文档中的许多独立模拟器也同时提供 libretro 核心版本（例如 Genesis Plus GX、Gambatte、ParaLLEl、mGBA、Mednafen、Nestopia UE、Snes9x、PCSX-R）。

**主要特性：**
- **统一界面** — 在所有支持的平台和核心上保持一致的操作体验
- **着色器 / Slang** — 实时 GPU 加速的 CRT 模拟和后期处理滤镜
- **联网对战** — 点对点在线多人游戏
- **倒带 / Run-Ahead** — 基于存档的倒带功能和输入延迟削减
- **成就系统** — 集成 RetroAchievements.org 的怀旧成就
- **覆盖层** — 支持为每个核心配置触摸设备按钮覆盖层

## 模拟精度谱系

```
性能优先 →                              → 精度优先
     |                                  |
 ZSNES    Snes9x    PCSX-R    Mesen     bsnes   BlastEm
 v86      DOSBox    Kega      DuckSta.  Exodus  Gambatte
```

**低阶模拟（LLE）**：在寄存器或周期级别模拟每个硬件组件。速度慢但精确。代表：bsnes、Exodus、Gambatte。

**高阶模拟（HLE）**：在更高抽象层模拟组件行为（例如模拟 API 行为而非寄存器级时序）。速度较快但可能引入 bug。代表：ZSNES、早期 N64 插件。

现代模拟器大多采用**混合方案**：时序敏感组件（PPU/GPU）用 LLE，非关键路径（音频混音、文件 I/O）用 HLE。

## 模拟技术

| 技术 | 说明 | 代表使用 |
|-----------|-------------|----------|
| **解释执行** | 逐条解码和执行指令 | 早期模拟器、调试版 |
| **动态重编译** | 运行时将客机代码翻译为主机代码 | 大多数现代模拟器 |
| **静态重编译** | 执行前翻译整个二进制文件 | N64、PlayStation |
| **混合** | 冷路径解释、热路径重编译 | mGBA、DuckStation |

## BIOS 与 ROM 法律说明

| 术语 | 含义 |
|------|------|
| **ROM** | 游戏卡带/光盘数据的导出文件 |
| **BIOS** | 主机固件导出文件（部分模拟器需要） |
| **自制软件（Homebrew）** | 用户自创软件，100% 合法 |
| **公有领域 ROM** | 版权已过期的游戏（极少） |
| **净室逆向工程** | 合法方式：根据规范重新实现，而非反编译原作 |

绝大多数商业游戏 ROM 仍受版权保护。拥有原版卡带/光盘并不自动赋予下载 ROM 副本的法律权利。

## 参考链接

- [NESDev Wiki](https://www.nesdev.org/wiki/) — NES 硬件与模拟开发参考
- [MAME 文档](https://docs.mamedev.org/) — 街机模拟
- [模拟器通用百科](https://emulation.gametechwiki.com/) — 社区模拟指南
- [DuckStation](https://github.com/stenzek/duckstation) — 现代 PS1 模拟器
- [mGBA](https://mgba.io/) — Game Boy Advance 模拟器
