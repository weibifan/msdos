# Legacy BIOS Boot Process

## 概述 (Overview)

Legacy BIOS（基本输入输出系统）自 1981 年（IBM PC）起至 2010 年代初一直是标准 PC 固件。它存储在主板上的 ROM 芯片中，是计算机开机时 CPU 执行的第一段代码。

## 上电 → 操作系统移交：完整流程

```
Power On
   │
   ▼
┌──────────────────────────────────────┐
│  1. Power-On Self-Test (POST)        │
│  ─ CPU reset vector (0xFFFFFFF0)     │
│  ─ CPU + chipset initialization      │
│  ─ Memory detection & test           │
│  ─ System bus enumeration            │
└──────────────────────────────────────┘
   │
   ▼
┌──────────────────────────────────────┐
│  2. BIOS Initialization              │
│  ─ Interrupt Vector Table (IVT)      │
│  ─ BIOS Data Area (BDA)              │
│  ─ Extended BIOS Data Area (EBDA)    │
│  ─ Option ROMs (VGA, NIC, SCSI...)   │
│    └─ INT 0x19 hook                  │
└──────────────────────────────────────┘
   │
   ▼
┌──────────────────────────────────────┐
│  3. Boot Device Selection            │
│  ─ INT 0x19 (Load Bootstrap)         │
│  ─ Check boot order (CMOS settings)  │
│  ─ Try each device:                  │
│    ├─ Floppy: sector 0, byte 0x1FE   │
│    ├─ HDD:    MBR, 0x1FE = 0x55AA   │
│    └─ CD-ROM: El Torito spec         │
└──────────────────────────────────────┘
   │
   ▼
┌──────────────────────────────────────┐
│  4. MBR Boot Code                    │
│  ─ First 440 bytes of sector 0       │
│  ─ Partition table at offset 0x1BE   │
│  ─ Signature 0x55AA at offset 0x1FE  │
│  ─ Load VBR (Volume Boot Record)     │
└──────────────────────────────────────┘
   │
   ▼
┌──────────────────────────────────────┐
│  5. Volume Boot Record (VBR)         │
│  ─ First sector of active partition  │
│  ─ Load boot loader (e.g., NTLDR)    │
│  ─ Switch to protected mode          │
└──────────────────────────────────────┘
   │
   ▼
┌──────────────────────────────────────┐
│  6. Boot Loader → OS                 │
│  ─ NTLDR → Windows                   │
│  ─ GRUB/LILO → Linux                 │
│  ─ DOS: IO.SYS + MSDOS.SYS          │
└──────────────────────────────────────┘
```

## 逐步详解

### 1. CPU 复位与 POST（开机自检）

**x86 CPU 复位状态：**
- **CS:IP = 0xF000:0xFFF0** → 物理地址 **0xFFFFFFF0**（4 GB 顶端）
- 16 位实模式
- 所有寄存器清零（CS 除外）

在 0xFFFFFFF0 处有一条 **跳转** 指令指向 BIOS 入口点（通常为 0xF000:E05B）。

**POST 检查项：**
- CPU 寄存器和标志位
- 定时器（PIT 通道 0）
- DMA 控制器
- 前 64 KB RAM（通过 0x55AA 模式读写测试）
- CMOS 电池和 RTC
- 键盘控制器（A20 门）
- 显卡初始化（VGA BIOS 位于 0xC0000）
- 辅助存储控制器

**蜂鸣码** 指示 POST 失败原因：
| 蜂鸣模式 | 错误 |
|-------|-------|
| 1 短声 | POST 正常 |
| 1 长声 + 2 短声 | 显卡故障 |
| 连续短声 | 电源故障 |
| 无声音 | CPU 或主板故障 |

### 2. BIOS 初始化

**POST 后的内存布局：**

```
0x00000000 - 0x000003FF: Interrupt Vector Table (256 × 4 bytes)
0x00000400 - 0x000004FF: BIOS Data Area (BDA)
0x00000500 - 0x0009FFFF: Conventional Memory (640 KB)
0x000A0000 - 0x000BFFFF: VGA Video Memory
0x000C0000 - 0x000C7FFF: Video BIOS (32 KB)
0x000F0000 - 0x000FFFFF: System BIOS (64 KB)
0xFFFFFFF0                 : Reset Vector
```

**关键 BIOS 数据区（BDA）字段：**
| 地址 | 大小 | 描述 |
|---------|------|-------------|
| 0x0410 | 2 字节 | 设备列表（软驱、硬盘、视频模式） |
| 0x0413 | 2 字节 | 常规内存大小（KB） |
| 0x0417 | 2 字节 | 键盘换档状态标志 |
| 0x0463 | 2 字节 | 视频控制器基 I/O 端口地址 |
| 0x0475 | 1 字节 | 检测到的硬盘数量 |

**Option ROMs（扩展 ROM）：**
- 显卡、SCSI 控制器、网卡等设备带有板载 ROM
- 每个 ROM 在偏移量 0xAA55 处有一个包含初始化程序的头部
- BIOS 在 0xC0000-0xE0000 范围内以 2 KB 步长扫描
- Option ROM 处理程序通常会挂载 INT 0x13（磁盘）或 INT 0x10（视频）

### 3. 启动设备选择（INT 0x19）

POST 完成后，BIOS 执行 **INT 0x19**（加载引导程序）。

**启动顺序存储在 CMOS RAM 中**（通过端口 0x70/0x71 访问）：
```
CMOS offset 0x2E: boot sequence flag
CMOS offset 0x3D: device priority list
```

**每个设备的启动尝试流程：**
1. 将扇区 0 读取到 0x0000:0x7C00
2. 检查 0x1FE-0x1FF 字节是否为 0x55AA 签名
3. 如果有效，跳转到 0x0000:0x7C00
4. 如果无效，尝试下一个设备
5. 全部失败则显示"No bootable device" / 执行 INT 0x18

### 4. MBR（主引导记录）

**布局**（扇区 0，LBA 0）：

| 偏移量 | 大小 | 内容 |
|--------|------|---------|
| 0x000 | 440 字节 | 引导代码（阶段 1） |
| 0x1B8 | 4 字节 | 可选磁盘签名 |
| 0x1BC | 2 字节 | 通常为 0x0000 |
| 0x1BE | 16 字节 | 分区条目 1 |
| 0x1CE | 16 字节 | 分区条目 2 |
| 0x1DE | 16 字节 | 分区条目 3 |
| 0x1EE | 16 字节 | 分区条目 4 |
| 0x1FE | 2 字节 | 签名 0x55AA |

**MBR 代码功能：**
1. 找到活动（可引导）分区
2. 将 VBR（该分区的第一个扇区）加载到 0x0000:0x7C00
3. 跳转到该地址

### 5. VBR（卷引导记录）

VBR 加载并执行文件系统特定的引导加载程序：
- **FAT12/16**：IO.SYS + MSDOS.SYS（DOS）或 NTLDR（Windows）
- **FAT32/HPFS**：与 FAT16 相同
- **NTFS**：NTLDR 或 bootmgr

### 6. 引导加载程序 → 操作系统

**DOS 引导：**
```
VBR → IO.SYS → MSDOS.SYS → COMMAND.COM
    (hidden)   (hidden)     (shell)
```

**Windows NT+ 引导：**
```
VBR → NTLDR → NTDETECT.COM → ntoskrnl.exe (NT kernel)
```

**Linux 引导（GRUB）：**
```
VBR → GRUB stage 1 → stage 1.5 → stage 2 → kernel + initrd
                   (embeded in  (filesystem
                    MBR gap)    driver)
```

## BIOS 中断（软件）

BIOS 通过 **软件中断** 提供硬件抽象：

| 中断 | 服务 | 示例 |
|-----------|---------|----------|
| INT 0x10 | 视频 | 设置模式、绘制像素、写入文字 |
| INT 0x13 | 磁盘 | 读/写扇区、获取磁盘参数 |
| INT 0x16 | 键盘 | 获取按键、检查按键状态 |
| INT 0x1A | 时间/CMOS | 读取 RTC、设置系统时间 |
| INT 0x15 | 杂项 | 内存大小、摇杆、磁带 |
| INT 0x17 | 打印机 | 打印字符、初始化、状态 |

**调用约定：** AH = 功能号，其他寄存器 = 参数，然后执行 `INT n`。

示例——使用 INT 0x13 读取磁盘扇区：
```asm
mov ah, 0x02        ; function: read sectors
mov al, 0x01       ; number of sectors
mov ch, 0x00       ; cylinder
mov cl, 0x02       ; sector (1-indexed)
mov dh, 0x00        ; head
mov dl, 0x80        ; drive (0x80 = first HDD)
mov bx, 0x7E00    ; buffer address (ES:BX)
int 0x13
```

## BIOS 限制

| 特性 | Legacy BIOS | UEFI |
|---------|-------------|------|
| CPU 模式 | 16 位实模式 | 32/64 位保护/长模式 |
| 地址空间 | 1 MB（20 位） | 完整（32/64 位） |
| 磁盘 | MBR（最大 2 TB） | GPT（最大 9.4 ZB） |
| 分区 | 4 个主分区 | 128+ |
| 网络启动 | 通过 UNDI 的 PXE | UEFI 网络栈 |
| GUI | 纯文字菜单 | 图形化预启动应用 |
| 启动速度 | 较慢（16 位，轮询 I/O） | 较快（并行初始化） |
| 安全性 | 无 | Secure Boot |

## 参考文献

- [OSDev Wiki - BIOS](https://wiki.osdev.org/BIOS)
- [IBM PC/AT Technical Reference (1984)](https://archive.org/details/IBM_PC_AT_Technical_Reference_1984)
- [Ralf Brown's Interrupt List](http://www.ctyme.com/rbrown.htm)
- [Phil Storrs PC Hardware Book](http://www.philpem.me.uk/pc-hardware-book/)
