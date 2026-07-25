# UEFI_Contra Project Analysis

## 概述 (Overview)

**UEFI_Contra**（作者 MikeWuPing）将经典 NES 游戏 Contra（魂斗罗）移植为在 UEFI 固件上运行的 UEFI 应用程序。游戏运行在 UEFI Shell 环境中，通过 GOP 直接渲染——无需操作系统。

**GitHub**：https://github.com/MikeWuPing/UEFI_Contra

## 项目统计

| 类别 | 行数 |
|----------|-------|
| C 源代码（.c） | ~3,200 |
| 头文件（.h） | ~1,900 |
| 关卡数据 | ~650 |
| **总计** | **~7,500** |

## 架构

### 构建系统

该项目编译为 EDK2 EmulatorPkg 应用程序：

```
ContraGame.inf (INF file)
  │
  ├─ entry.c    → UefiMain() 入口点
  ├─ main.c     → 游戏循环、初始化
  ├─ render.c   → GOP 渲染管线
  ├─ input.c    → 通过 UEFI Simple Text Input 的键盘输入
  ├─ player.c   → 玩家角色
  ├─ enemy.c    → 4 种带 AI 的敌人类型
  ├─ bullet.c   → 抛射物系统
  ├─ weapon.c   → 6 种武器类型
  ├─ level.c    → 关卡加载与滚动
  ├─ sprites.c  → 精灵加载（.spr 文件）
  ├─ game_state.c → 状态机
  └─ nes_palette.c → NES 颜色调色板
```

### 源代码结构

```
src/
├── ContraGame.inf    — EDK2 INF 构建文件
├── entry.c           — UEFI 入口点
├── main.c            — 游戏循环（60fps）、初始化
├── render.c          — 渲染管线、GOP Blt
├── input.c/.h        — 键盘输入
├── player.c/.h       — 玩家逻辑
├── enemy.c/.h        — 敌人 AI（4 种类型）
├── bullet.c/.h       — 子弹系统
├── weapon.c/.h       — 6 种武器
├── level.c/.h        — 关卡数据加载、滚动
├── game_state.c/.h   — 游戏/关卡状态机
├── sprites.c/.h      — 精灵加载（.spr）
├── nes_palette.c/.h  — NES → ARGB 颜色转换
├── types.h           — 定点数类型、常量
├── level_data.h      — 关卡布局、碰撞数据
├── intro_*.h         — 标题画面数据
└── tiles_*.h         — 瓦片数据（背景瓦片）
```

## 游戏状态机

核心游戏逻辑由两个状态机驱动：

### 游戏例程（7 个状态）

```
 00 → 01 → 02 → 03 → 04 → 05 ←→ 06
Logo  Sel   Demo  Flash Clear Core  End
```

### 关卡例程（11 个子状态，位于游戏例程 05 内部）

```
00 → 01 → 02 → 03 → 04 ←→ 05 → 06/07 → 08 → 09 → 0a
Load Show  Flikr Draw Core  Clear G/Over Boss Seq   Delay
```

## 渲染管线

每帧（60fps）：

```
PollInput() → GameStateMachine() → RenderGame()
                                      │
                    ┌──────────────────┴──────────────────┐
                    │                                     │
              DrawBackground()                     DrawSprites()
                    │                                     │
         ┌──────────┴──────────┐                         │
         │                     │                          │
   Decompress RLE       Map Super-Tile               Draw Player
   Screen Data          → Tile Array                 Draw Enemies
         │                     │                     Draw Bullets
         ▼                     ▼                     Draw HUD
   8×8 Tile Render    Palette Lookup
         │                     │
         └──────────┬──────────┘
                    ▼
          256×240 Game Buffer
                    │
                    ▼
          ScaleAndPresent()
           (2×/3× integer)
                    │
                    ▼
              GOP Blt → Screen
```

## 关键技术决策

### 1. 定点数运算
```c
// INT32 8.8 定点数格式
typedef int32_t fixed_t;
#define FIXED_SHIFT   8
#define FIXED_SCALE   (1 << FIXED_SHIFT)
#define INT_TO_FIXED(x) ((fixed_t)(x) * FIXED_SCALE)
```
避免浮点运算，确保跨平台行为一致。

### 2. 静态内存分配
所有游戏数组在编译时固定大小。无 malloc/free——防止 UEFI 环境中的内存碎片。

### 3. 双缓冲
1. 渲染到 256×240 系统内存缓冲区
2. `ScaleAndPresent()`：整数 2×/3× 缩放 + Blt 到 GOP 帧缓冲

### 4. 精灵文件（.spr）
精灵通过 Python 工具从 PNG 预转换为 `.spr` 二进制格式。运行时通过 UEFI Simple File System Protocol 加载。保持了 `.efi` 文件体积小巧。

### 5. RLE 压缩
关卡数据使用 RLE（游程编码）压缩。控制码：0x80 | 长度，后跟重复的字节。

## 敌人 AI 类型

| 类型 | 行为 |
|------|----------|
| Soldier（士兵） | 行走、停下、向玩家射击 |
| Turret（炮台） | 固定位置，跟踪并瞄准玩家 |
| Boss（首领） | 跟踪玩家，快速射击，需多次命中才能击败 |
| Runner（跑者） | 快速移动，跳过障碍物 |

## 武器系统

| 名称 | 按键 | 描述 |
|------|-----|-------------|
| Default（默认） | M | 标准步枪，单发 |
| Machine Gun（机枪） | R | 快速连射，自动重复 |
| Fire Ball（火球） | F | 旋转火球抛射物 |
| Spread（散弹） | S | 5 路扩散射击 |
| Laser（激光） | L | 穿透光束 |
| Barrier（护盾） | B | 临时无敌 |

## 碰撞检测

四级碰撞代码系统（每瓦片）：
- **代码 0**：空——自由通行
- **代码 1**：地板——可站立，按下可向下穿过
- **代码 2**：水——不可跳跃，下半身隐藏
- **代码 3**：实体——完全不可通行

## 未移植的内容

- **音频**——UEFI 音频驱动复杂度高；QEMU 音频模拟能力有限
- **双人模式**——仅实现了单人模式
- **完整游戏**——仅第一关（13 个画面）作为技术演示

## 构建流程概要

```
1. PNG 精灵 → .spr（png_to_spr.py）
2. 将源代码插入 EDK2 EmulatorPkg
3. 使用 VS2019 执行 build 命令
4. 输出：Contra.efi
5. 放置在包含 .spr 文件的 FAT 磁盘上
6. QEMU + OVMF → UEFI Shell → Contra
```

## 参考文献

- 原始项目：https://github.com/MikeWuPing/UEFI_Contra
- NES Contra 反汇编：https://github.com/vermiceli/nes-contra-us
- EDK2：https://github.com/tianocore/edk2
- QEMU：https://www.qemu.org/
