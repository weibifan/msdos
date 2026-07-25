# NES Architecture (Simplified)

## 概述 (Overview)

Nintendo Entertainment System（1983 年）是一款 8 位游戏主机。了解其架构对于理解 UEFI_Contra 的工作原理至关重要，因为该项目在 UEFI GOP 上重新实现了 NES 渲染。

## 核心组件

### CPU：MOS 6502 @ 1.79 MHz

- 8 位处理器
- 16 位地址总线（64 KB 地址空间）
- 3 个通用寄存器：A、X、Y
- 栈指针、程序计数器、状态寄存器
- 无乘除指令
- 小端序

### PPU：图像处理单元（RP2C02）

PPU 是一颗专用的图形芯片，负责所有视频输出。

**关键规格：**
- 分辨率：256×240 像素（实际有效 256×224）
- 共 64 种颜色（来自固定调色板）
- 8 个调色板，每个 4 种颜色（背景 4 个，精灵 4 个）
- 2BPP（每像素 2 位）瓦片格式
- 8×8 像素瓦片（精灵可为 8×16）
- 2 个图案表（各 256 个瓦片），位于 PPU $0000 和 $1000
- 2 个名称表（32×30 瓦片地图），位于 PPU $2000 和 $2800
- 64 个硬件精灵（每扫描线最多 8 个）
- 精灵优先级、翻转和颜色效果

### 内存映射

```
CPU Address Map:
$0000-$07FF: RAM (2 KB)
$0800-$1FFF: Mirrors of RAM
$2000-$2007: PPU Registers
$4000-$4017: APU + I/O Registers
$4018-$401F: Test/Disabled
$4020-$5FFF: Cartridge PRG-ROM (optional)
$6000-$7FFF: Cartridge SRAM
$8000-$FFFF: Cartridge PRG-ROM (fixed)

PPU Address Map:
$0000-$0FFF: Pattern Table 0 (background tiles)
$1000-$1FFF: Pattern Table 1 (sprite tiles)
$2000-$23FF: Nametable 0
$2400-$27FF: Nametable 1
$2800-$2BFF: Nametable 2
$2C00-$2FFF: Nametable 3
$3F00-$3F0F: Background Palette
$3F10-$3F1F: Sprite Palette
```

## 2BPP 瓦片格式

每个 8×8 像素瓦片占用 16 字节：
- 8 字节用于低位平面（位 0）
- 8 字节用于高位平面（位 1）

```
Example tile byte layout (4 pixels):
Low plane:    0xAA = 10101010
High plane:   0x55 = 01010101
Combined:     10 01 10 01 = 2, 1, 2, 1 (palette indices)
```

每个 2 位值是该瓦片 4 色调色板中的索引。

## NES 调色板

NES 有一个固定的 64 条目调色板：

```
Index   Color           Index   Color
$00     Transparent     $10     Dark Grey
$01     White           $11     Blue Grey
$02     Light Grey      $12     ...
...     ...             ...     ...
$0F     Black           $1F     Black
```

每个 NES 调色板条目映射到一个 RGB 值，UEFI_Contra 在 `nes_palette.c` 中实现了这一点。

## 背景渲染

NES 背景由以下部分组成：
1. **名称表（Nametable）**：32×30 的瓦片索引网格（每单元格 1 字节）
2. **属性表（Attribute Table）**：每 16×16 像素区域的 2 位调色板选择器
3. **图案表（Pattern Table）**：实际的 8×8 像素瓦片数据（2BPP）

### 超级瓦片系统（Contra 特定）

Contra 使用更高效的 **超级瓦片（Super-Tile）** 系统：

```
Level Data (RLE compressed)
        │
        ▼
    Screen Layout (8×7 = 56 Super-Tile indices, 32×32 pixels each)
        │
        ▼
    Super-Tile Definition (16 tile indices = 4×4 array of 8×8 tiles)
        │
        ▼
    Pattern Table (actual 2BPP pixel data, 16 bytes per tile)
```

**RLE（游程编码）**：控制字节 0x80+NN 表示"将下一个字节重复 NN 次"。例如 `$87 $00` = 将 0x00 重复 7 次。

## 精灵渲染

精灵是 8×8 或 8×16 像素的对象：
- 屏幕上最多 64 个精灵
- 每扫描线最多 8 个精灵
- OAM（对象属性内存）：存储精灵的 X、Y、瓦片索引、属性

精灵属性字节：
```
Bit 7: Flip vertical
Bit 6: Flip horizontal
Bit 5: Priority (behind/above background)
Bits 1-0: Palette index
```

UEFI_Contra 通过 UEFI 文件系统协议从 `.spr` 文件（从 PNG 预转换）加载精灵数据。

## 卡带映射器（Contra 使用 UNROM）

UNROM 映射器（iNES 映射器 #2）：
- 128KB PRG-ROM 分为 8 个 × 16KB 的库（bank）
- Bank 7 固定映射到 $C000-$FFFF
- Banks 0-6 可切换映射到 $8000-$BFFF
- 8KB CHR-RAM（非 ROM——Contra 将瓦片数据写入 PPU）

## 帧时序

- NTSC：每秒 60 帧
- 每帧：262 条扫描线（241 条可见，21 条 VBlank）
- PPU 在 VBlank 期间生成 NMI（非屏蔽中断）
- 游戏在 VBlank 期间更新状态和精灵

UEFI_Contra 使用游戏循环维护的 60fps 定时器。

## 参考文献

- [NESDev Wiki](https://www.nesdev.org/wiki/)
- [NES Architecture: A Practical Approach](https://www.nesdev.org/wiki/NES_reference)
- [NES Palette Reference](https://www.nesdev.org/wiki/PPU_palettes)
