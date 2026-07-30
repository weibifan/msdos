# x86 启动体系与 MS-DOS 引导深度解析

## 1. 总述

本文以 **MS-DOS 4.0** 为主线，讲解 2000 年之前 x86 PC 的启动流程、磁盘分区体系、
MBR/Bootloader 设计以及 FAT 文件系统原理。所有代码引用均来自微软开源仓库
`microsoft/MS-DOS` v4.0 源码。

---

## 2. 系统加电启动全流程

```
加电 → BIOS POST → 自举 INT 19h → MBR → Boot Sector → IO.SYS → MSDOS.SYS → COMMAND.COM
```

### 2.1 BIOS 阶段

CPU 复位后，CS:IP 指向 `0xF000:0xFFF0`（即物理地址 `0xFFFF0`），这是 BIOS ROM
的入口。BIOS 依次执行：

- **POST**（Power-On Self Test）：检测 CPU、内存、芯片组、键盘、磁盘控制器等
- **PCI 枚举**：分配 IRQ、I/O 端口、内存地址
- **INT 13h 初始化**：建立磁盘中断服务
- **自举设备选择**：检查 `CMOS 0x3D` 字节或 BIOS 设置，决定从 A 盘、C 盘还是
  CD-ROM 启动
- **INT 19h**：读取启动设备的 **0 柱面 0 磁头 1 扇区**（即 MBR 或 VBR）到
  `0x7C00`，跳转执行

### 2.2 MBR 阶段

MBR（Master Boot Record）位于 **LBA 0**（CHS 0/0/1），共 512 字节，结构如下：

```
偏移    大小    说明
------  ------  -----------------------------------------
0x000   446     引导代码（机器码）
0x1BE   16      分区表项 1（Primary Partition 1）
0x1CE   16      分区表项 2（Primary Partition 2）
0x1DE   16      分区表项 3（Primary Partition 3）
0x1EE   16      分区表项 4（Primary Partition 4）
0x1FE   2       魔数 55 AA
```

**MBR 引导代码的核心逻辑**（参考 MS-DOS 的 `FDISK` 写入的 MBR）：

```
1.  将自身从 0x7C00 拷贝到 0x600（避免被后续加载的 VBR 覆盖）
2.  遍历分区表，查找 Active（可启动）标志 = 0x80 的表项
3.  若找到，读取该分区的 VBR（Volume Boot Record）到 0x7C00
4.  跳转执行 VBR
```

**关键事实**：MBR 并不理解文件系统，它只读原始扇区。它找到 Active 分区后，
加载该分区的**第一个扇区**（即该分区的 VBR），把控制权交给 VBR。

### 2.3 VBR / Boot Sector 阶段

VBR（Volume Boot Record）是 MS-DOS 中真正的 bootloader，也叫 **Boot Sector**。
源码在 `BOOT/MSBOOT.ASM`。它起始于分区的 LBA 0（相对于分区起点），结构为：

```
偏移    大小    说明
------  ------  -----------------------------------------
0x000   3       JMP 指令（跳转到引导代码）
0x003   8       OEM ID（如 "MSDOS4.0"）
0x00B   25/51   BPB（BIOS Parameter Block）
0x03E   引导代码（因 BPB 长度而异）
0x1FE   2       魔数 55 AA
```

> **注意**：`MSBOOT.ASM` 第 60-63 行写入的 OEM ID 取决于构建配置。
> 当 `IBMCOPYRIGHT = TRUE` 时写入 `"IBM  4.0"`，否则写入 `"MSDOS4.0"`。
> 见 `VERSION.INC` 中 `IBMVER` / `IBMCOPYRIGHT` 开关。

**MSBOOT.ASM 流程**：

```
MSBOOT.ASM 入口 (0x7C00)
  │
  ├─ 保存 INT 1Eh 磁盘参数表地址
  ├─ 复制到本地并修改 Head Settle Time = 15ms
  ├─ 设置新的磁盘参数表向量
  ├─ INT 13h AH=0 复位磁盘系统
  │
  ├─ 计算目录区起始扇区号（DIR$）
  │     = cFat × cSecFat + cSecRes + cSecHid
  │
  ├─ 计算数据区起始扇区号（BIOS$）
  │     = DIR$ + (DirNum × 32 + ByteSec - 1) / ByteSec
  │
  ├─ 读取根目录第一个扇区到 0x500（DirOff）
  │
  ├─ 扫描前两个目录项：
  │   ├─ 检查第一个文件名 == "IO     SYS"（MS 版）
  │   │                       或 "IBMBIO COM"（IBM 版）
  │   └─ 检查第二个文件名 == "MSDOS  SYS"（MS 版）
  │                       或 "IBMDOS COM"（IBM 版）
  │
  ├─ 若未找到 → 显示 "Non-System disk or disk error"
  │              等待按键 → INT 19h 重新启动
  │
  └─ 找到后 → 从数据区读取 3 个扇区到 0x700（BioOff）
        │
        └─ 设置 CH = Media Byte, DL = PhyDrv
           BX = BIOS$_L, AX = BIOS$_H
           JMP FAR PTR BIOS → 跳转到 IO.SYS 初始化入口
```

**关键数据流**：

```
读取目录：INT 13h AH=02, CH=CURTRK, CL=CURSEC, DH=CURHD, DL=PHYDRV,
          ES:BX = 0x500

扇区号转换（DODIV 函数）：
  给定逻辑扇区号 DX:AX：
    DX:AX / SecLim → 商 = 逻辑柱面（total tracks），余数 = 扇区号-1
    尚 / HdLim  → 商 = 柱面，余数 = 磁头号
```

这就是 MS-DOS 4.0 中完整的 **自定义文件系统导航**——纯汇编、无文件系统驱动，
通过已知的 FAT 布局参数（`cFat`、`cSecFat`、`DirNum` 等）直接计算扇区位置。

---

## 3. 磁盘分区体系

### 3.1 MBR 分区表结构

每个分区表项 16 字节：

```
偏移  大小  说明
----  ----  -------------------------------------------
0x00  1     启动标志（0x80 = Active，0x00 = 非启动）
0x01  3     CHS 起始地址（Head/Sector/Cylinder）
0x04  1     分区类型
0x05  3     CHS 结束地址
0x08  4     LBA 起始扇区（相对磁盘开头）
0x0C  4     分区总扇区数
```

**分区类型字节**（常见于 MS-DOS/Windows 9x）：

| 类型 | 说明 |
|------|------|
| 01h | FAT12（主分区） |
| 04h | FAT16（< 32MB） |
| 06h | FAT16（32MB-2GB） |
| 0Bh | FAT32（CHS/LBA 寻址） |
| 0Ch | FAT32（仅 LBA） |
| 05h | 扩展分区（**Extended Partition**） |
| 0Fh | 扩展分区（LBA） |
| 07h | NTFS / HPFS |
| 82h | Linux swap |
| 83h | Linux ext2/ext3 |

**MBR 的限制**：
- 最多 **4 个主分区**
- 单个分区最大 2TB（因 LBA 字段仅 4 字节 × 512 = `0xFFFFFFFF` 扇区）
- 需要扩展分区来突破 4 个限制

### 3.2 主分区 vs 扩展分区 vs 逻辑分区

```
磁盘布局示例（40MB 硬盘）：
┌─────────────────────────────────────────────┐
│ MBR (LBA 0)                                 │
│   ├─ 表项1: 主分区  (类型 06h, Active)       │  ← 可引导
│   ├─ 表项2: 扩展分区 (类型 05h)              │
│   ├─ 表项3: 未使用  (全 0)                   │
│   └─ 表项4: 未使用  (全 0)                   │
├─────────────────────────────────────────────┤
│ 主分区 C: (FAT16, LBA 1 ~ 20000)            │
│   └─ VBR → IO.SYS → MSDOS.SYS → COMMAND.COM │
├─────────────────────────────────────────────┤
│ 扩展分区 (LBA 20001 ~ end)                   │
│   └─ EBR (Extended Boot Record)              │
│       ├─ 表项1: 逻辑分区 D:                  │
│       ├─ 表项2: 指向下一个 EBR 或全 0        │
│       ├─ 表项3: 未使用                       │
│       └─ 表项4: 未使用                       │
│       └─ D: 的 VBR + 数据区                  │
│   └─ EBR2                                   │
│       ├─ 表项1: 逻辑分区 E:                  │
│       └─ 表项2: 0（无下一个）                │
│       └─ E: 的 VBR + 数据区                  │
└─────────────────────────────────────────────┘
```

**核心区别**：

- **主分区（Primary Partition）**：记录在 MBR 中，最多 4 个，可以直接引导
- **扩展分区（Extended Partition）**：也是主分区表项，但类型为 05h/0Fh，
  它不直接存储数据，而是作为**逻辑分区的容器**
- **逻辑分区（Logical Partition）**：不记录在 MBR，而记录在 **EBR**
  （Extended Boot Record，结构与 MBR 类似但无引导代码），通过链表形式串联

**引导限制**：只有**主分区**可以设置为 Active（可引导）。IO.SYS 必须在
**主分区的 FAT 卷**上。这就是为什么早期 DOS 必须安装在主分区。

### 3.3 MBR vs VBR — 关键区分

很多人混淆这两个概念，这里做明确区分：

| | MBR | VBR（Boot Sector） |
|---|---|---|
| 位置 | 磁盘 LBA 0 | 分区 LBA 0 |
| 大小 | 512B | 512B（DOS 下） |
| 内容 | 引导代码 + 分区表 | BPB + 引导代码 |
| 魔数 | 55 AA 偏移 0x1FE | 55 AA 偏移 0x1FE |
| 所属 | 整个磁盘 | 每个分区 |
| 作用 | 定位 Active 分区，加载 VBR | 加载操作系统内核文件 |
| 文件系统感知 | 不感知 | 需要理解文件系统 |

**DOS 场景**：MBR 不做文件系统解析，它只是读取 Active 分区的第一个物理扇区到
`0x7C00`。真正的文件系统交互（读取 `IO.SYS`）发生在 `MSBOOT.ASM`（VBR）中。

---

## 4. FAT 文件系统

### 4.1 FAT16 布局

```
┌─────────────────────────┐
│ VBR / Boot Sector       │  1 扇区（+ 可能保留扇区）
├─────────────────────────┤
│ FAT #1                  │  由 cSecFat 指定大小
├─────────────────────────┤
│ FAT #2（镜像）           │  与 FAT #1 相同大小
├─────────────────────────┤
│ 根目录区                 │  固定大小（DirNum × 32B）
├─────────────────────────┤
│ 数据区                   │  文件/目录内容
└─────────────────────────┘
```

VBR 中的关键 BPB 字段：

```
结构体（参考 MSBOOT.ASM 第 63-98 行）：
  ByteSec   dw 512        ; 每扇区字节数
            db 8          ; 每簇扇区数
  cSecRes   dw 1          ; 保留扇区数
  cFat      db 2          ; FAT 表数量
  DirNum    dw 512        ; 根目录项数
  cTotSec   dw 20781      ; 总扇区数（- 隐藏扇区）
  MEDIA     db 0F8h       ; 媒体描述符（F8 = 硬盘）
  cSecFat   dw 8          ; 每 FAT 扇区数
  SecLim    dw 17         ; 每磁道扇区数
  HdLim     dw 4          ; 磁头数
  cSecHid_L dw 1          ; 隐藏扇区数（LBA 偏移）
  cTotSec_L dw 0          ; 32位总扇区数
```

**FAT 表原理**：FAT（File Allocation Table）是一个**链式分配表**。

- 每个表项对应一个**簇**（Cluster，连续扇区的集合）
- 每个文件对应一个簇链：目录项记录首簇号 → FAT[首簇] = 下一簇 → ... → 末尾标记
- 簇号 0/1 保留，0xFFF0-0xFFF6 保留，0xFFF7 坏簇，0xFFF8-0xFFFF 文件末尾

```
示例：文件 IO.SYS 占用簇 2, 3, 4
FAT 表：FAT[0]=FFF, FAT[1]=FFF, FAT[2]=3, FAT[3]=4, FAT[4]=FFFF, ...
                                     ^^^        ^^^        ^^^^
                                     下一簇为3   下一簇为4   文件结束 (EOF)
```

### 4.2 目录项结构（FAT12/16）

每个目录项 32 字节，布局如下：

```
偏移  大小  说明
----  ----  -------------------------------------------
0x00  8     文件名（不足补空格，第 0 字节=0xE5 表示已删除）
0x08  3     扩展名
0x0B  1     属性（位图：01=只读, 02=隐藏, 04=系统, 08=卷标, 10=子目录, 20=归档）
0x0C  10    保留/Windows NT 保留
0x16  2     最后修改时间
0x18  2     最后修改日期
0x1A  2     首簇号（FAT16）
0x1C  4     文件大小（字节）
```

**`MSBOOT.ASM` 中的目录扫描逻辑**正是按此结构在内存
地址 `0x500`（DirOff）处对比文件名前 11 字节：

```asm
    MOV  DI, BX          ; DI = 0x500
    MOV  CX, 11          ; 比较 11 字节
    MOV  SI, OFFSET BIO  ; "IO      SYS"
    REPZ CMPSB           ; 逐字节比较
    JNZ  CKERR           ; 不等 → 报错
```

### 4.3 FAT32 的改进

FAT32 相对于 FAT16 的核心变化：

| | FAT16 | FAT32 |
|---|---|---|
| 每表项大小 | 16 位 | 28 位（高 4 位保留） |
| 最大簇数 | 65520 个 | ~268,435,456 个 |
| 最大卷容量 | 2GB（通常） | 2TB（512B 扇区时） |
| 根目录位置 | 固定位于 FAT 后 | 在数据区，可动态扩展 |
| BPB 大小 | 25 字节 | 51 字节（扩展 BPB） |
| 保留扇区数 | 通常 1 | 通常 32 |

MS-DOS 4.0 的 `MSBOOT.ASM` 实际上已经为 FAT32 的 32 位扇区号做了准备：

```asm
    cmp  cTotSec, 0      ; 检查是否为 32 位模式
    je   Dir_Cont         ; 若 16 位总扇区数为 0，使用 32 位版本
    mov  cx, cTotSec
    mov  cTotSec_L, cx    ; 将 16 位值赋给低字
```

**同时**，32 位扇区号计算被明确标注为"因空间不足而简化"：

```asm
; DODIV：将逻辑扇区号(DX:AX)转换为磁道/扇区/磁头
; 由于没有足够的空间做完整 32 位除法，仅比较高字与除数
DODIV:
    cmp  dx, SecLim       ; 防止溢出
    jae  DivOverFlow
    DIV  SECLIM           ; 32/16 位除法
```

### 4.4 NTFS（简要）

NTFS 在 1993 年随 Windows NT 3.1 引入，与 FAT 体系有本质区别：

| 特性 | FAT16/FAT32 | NTFS |
|---|---|---|
| 分配结构 | FAT 链式表 | MFT（Master File Table） |
| 元数据存储 | 隐藏目录项 | $MFT 文件 |
| 最大文件 | 2GB/4GB | 16EB |
| 权限 | 无 | ACL（访问控制列表） |
| 日志 | 无 | $LogFile 事务日志 |
| 压缩/加密 | 无 | 支持 |
| 文件名编码 | 8.3 ASCII | Unicode（最长 255 字符） |

NTFS 的引导扇区（VBR）位置仍然在分区 LBA 0，结构兼容 BPB，
但引导代码加载的是 `ntldr`（NT 4.0/2000/XP）或 `bootmgr`（Vista+），
而非 `IO.SYS`。

值得注意的是，MS-DOS **无法直接读取 NTFS 分区**。这是因为 NTFS 的
MFT 结构与 FAT 完全不兼容，且 MS-DOS 的 VBR 只认识 FAT 布局参数。

---

## 5. Boot Manager 与多引导

### 5.1 什么是 Boot Manager

Boot Manager 是一个**间接引导层**，安装在 MBR 位置，取代标准的 MBR 引导代码。
它提供菜单让用户选择从哪个分区或磁盘启动。

### 5.2 区分：MBR Boot Code vs VBR Boot Code vs Boot Manager

| 组件 | 位置 | 角色 | 示例 |
|---|---|---|---|
| MBR Boot Code | MBR (LBA 0) | 加载 Active 分区的 VBR | MS-DOS FDISK 写入的 MBR |
| VBR Boot Code | 分区 LBA 0 | 加载操作系统内核 | MSBOOT.ASM → IO.SYS |
| Boot Manager | MBR 或单独分区 | 提供多选菜单 | OS/2 Boot Manager, LILO, GRUB |

**Boot Manager 的 3 种部署方式**：

1. **接管 MBR**（如 LILO、早期 GRUB Legancy）：将引导代码写入 MBR，
   自身内核放在磁盘后段扇区中

2. **单独引导分区**（如 OS/2 Boot Manager）：创建一个 **6 字节类型**的小分区，
   MBR 跳转到该分区的 VBR，再加载菜单程序

3. **链式加载**（如 NTLDR、Windows Boot Manager）：主引导先加载自身，
   再通过读取配置文件 (`boot.ini` / `BCD`) 加载另一个 VBR 或
   直接加载内核

### 5.3 MS-DOS 场景下的"多引导"

MS-DOS 本身没有 Boot Manager。多引导通过以下方式实现：

- **FDISK /MBR**：只写 MBR 引导代码，不改分区表
- **SYSTEM COMMANDER / OS/2 Boot Manager**：第三方 Boot Manager 接管 MBR，
  为每个 DOS 分区创建独立的引导菜单项
- **DOS 4.0 及以后**：`CONFIG.SYS` 中的 `[MENU]` 功能实现了
  **同一分区内的多配置**，但这由 `IO.SYS` 处理，远早于 Boot Manager

---

## 6. IO.SYS、MSDOS.SYS、COMMAND.COM 三者的关系

### 6.1 文件角色

| 文件 | 大小（典型） | 角色 | 对应现代概念 |
|---|---|---|---|
| IO.SYS | ~14KB-40KB | DOS 内核底层 + 设备驱动 | 内核 + 设备管理器 |
| MSDOS.SYS | ~15KB-50KB | DOS 内核上层（文件系统 + 系统调用） | VFS + 系统调用层 |
| COMMAND.COM | ~40KB-60KB | Shell（命令行解释器） | bash/cmd.exe |

### 6.2 IO.SYS 的初始化流程

当 `MSBOOT.ASM` 执行 `JMP FAR PTR BIOS` 跳转到 `0x70:0x700` 时，
`IO.SYS`（即 `IBMBIO` / `MSBIO`）开始执行，状态如下：

```
输入条件（来自 MSBOOT.ASM 第 169-173 行）：
  CH = MEDIA 字节（如 0F8h）
  DL = PhyDrv（物理驱动器号，如 80h = 第一硬盘）
  BX = BIOS$_L（数据区首扇区低字）
  AX = BIOS$_H（数据区首扇区高字）
```

IO.SYS 初始化序列（参考 `MSBIO` 消息模块）：

```
IO.SYS 入口（_TEXT 段）
  │
  ├─ 设置系统栈、系统段寄存器
  ├─ 初始化 INT 向量表：
  │   ├─ INT 20h-21h（DOS 系统调用）
  │   ├─ INT 24h（严重错误处理）
  │   ├─ INT 28h（空闲中断）
  │   └─ 保留 DOS 使用的中断
  │
  ├─ 重新初始化磁盘系统
  │
  ├─ 初始化 CON（键盘+显示器）设备驱动
  ├─ 初始化 AUX（串口）、PRN（并口）等标准块设备
  │
  ├─ 初始化块设备（硬盘/软盘驱动）
  │
  ├─ 调用 DOS API 中的 SysInit：
  │   ├─ 初始化 DOS 内部数据结构（SFT、CDS、BUFFERS 等）
  │   ├─ 读取 CONFIG.SYS → 解析 DEVICE、FILES、BUFFERS、STACKS 等
  │   ├─ 加载并初始化可安装设备驱动（ANSI.SYS、HIMEM.SYS 等）
  │   └─ 打开 COMMAND.COM 文件
  │
  └─ JMP FAR PTR COMMAND.COM 的第一个扇区
```

### 6.3 MSDOS.SYS 的角色

MSDOS.SYS 是 DOS 内核的**上层**，提供：

- **DOS API**：INT 21h 的 100+ 个系统调用（文件打开、读写、进程管理等）
- **文件系统抽象**：在 `IO.SYS` 提供的块设备接口上实现 FAT 文件系统逻辑
- **SFT（System File Table）管理**：跟踪所有打开的文件句柄
- **内存管理**：MCB（Memory Control Block）链式分配
- **程序加载**：EXE 文件重定位、加载、执行
- **错误处理**：INT 24h 与 CRITICAL ERROR 处理器交互

**加载顺序的荒谬之处**：`IO.SYS` 需要在没有任何文件系统支持的条件下从磁盘读取
`MSDOS.SYS`。这实际上在 `MSBOOT.ASM` 中并未完成——`MSBOOT.ASM` 只读取了
**IBMLOAD**（`IO.SYS` 的前 3 个扇区），而 `IO.SYS` 启动后自己读取自己的
剩余部分以及 `MSDOS.SYS`。

### 6.4 CONFIG.SYS 与 AUTOEXEC.BAT

虽然不在启动流程的"必须"路径上，但这两个文件是 DOS 启动的关键配置：

```
IO.SYS 读取 CONFIG.SYS
  ├─ DEVICE=HIMEM.SYS      → 加载扩展内存驱动
  ├─ DEVICE=EMM386.EXE     → 加载 EMS 驱动
  ├─ DEVICE=ANSI.SYS       → 加载 ANSI 终端控制
  ├─ FILES=40              → 设置文件句柄数
  ├─ BUFFERS=20            → 设置磁盘缓冲区数
  ├─ STACKS=9,256          → 设置堆栈帧数
  ├─ DOS=HIGH,UMB          → 将 DOS 加载到高端内存
  ├─ SHELL=C:\DOS\COMMAND.COM C:\DOS /P  → 指定 Shell
  └─ DEVICE=C:\DOS\SMARTDRV.SYS → 磁盘缓存

IO.SYS 最后启动 COMMAND.COM
COMMAND.COM 自动执行 C:\AUTOEXEC.BAT：
  ├─ PATH=C:\DOS;C:\WINDOWS
  ├─ SET TEMP=C:\TEMP
  ├─ PROMPT $P$G
  ├─ DOSKEY
  └─ WIN (启动 Windows 3.x)
```

---

## 7. 完整启动时间线（加电到 DOS 提示符）

```
时间线                        执行体         操作
──────                        ──────         ───────────────────────────
T+0s                          硬件           CPU 复位，CS:IP = F000:FFF0
T+0.1s                        BIOS ROM      POST，检测硬件
T+2s                          BIOS ROM      初始化 INT 13h，INT 10h
T+2.5s                        BIOS ROM      INT 19h → 读 LBA 0 到 0x7C00
T+2.51s                       MBR 代码      自拷贝到 0x600
T+2.52s                       MBR 代码      扫描 Active 分区
T+2.53s                       MBR 代码      读取 VBR 到 0x7C00
T+2.54s                       MBR 代码      JMP 0x7C00
T+2.55s                       MSBOOT.ASM    设置栈、磁盘参数、GDT
T+2.6s                        MSBOOT.ASM    计算 DIR$ 和 BIOS$
T+2.7s                        MSBOOT.ASM    读目录区到 0x500
T+2.71s                       MSBOOT.ASM    对比 "IO     SYS"
T+2.72s                       MSBOOT.ASM    读 3 扇区到 0x700
T+2.73s                       MSBOOT.ASM    JMP FAR BIOS (0x70:0x700)
T+2.8s                        IO.SYS        初始化中断向量表
T+3s                          IO.SYS        加载剩余 IO.SYS + MSDOS.SYS
T+3.5s                        IO.SYS        解析 CONFIG.SYS
T+4s                          IO.SYS        加载设备驱动
T+4.5s                        IO.SYS        加载 COMMAND.COM
T+4.6s                        COMMAND.COM   显示 DOS 提示符 C:\>
T+4.7s                        COMMAND.COM   执行 AUTOEXEC.BAT
T+5s                          用户          看到 C:\> 等待输入
```

---

## 8. MSBOOT.ASM 关键代码注释

以下摘自 `MSBOOT.ASM` 的片段是理解 DOS 启动的核心：

```asm
;==========================================================================
; 计算目录区起始扇区号（逻辑扇区）
;==========================================================================
    MOV  AL, cFat          ; FAT 表数量（通常 2）
    MUL  cSecFat           ; × 每 FAT 扇区数
    ADD  AX, cSecHid_L     ; + 隐藏扇区数
    ADC  DX, cSecHid_H
    ADD  AX, cSecRes       ; + 保留扇区数
    ADC  DX, 0
    MOV  [DIR$_L], AX      ; 保存目录区起始扇区
    MOV  [DIR$_H], DX

;==========================================================================
; 计算数据区起始扇区号
;   = 目录区 + (DirNum × 32 + ByteSec - 1) / ByteSec
;==========================================================================
    MOV  AX, 32            ; 每条目录项 32 字节
    MUL  DirNum            ; = 目录总字节数
    MOV  BX, ByteSec       ; 每扇区字节数（512）
    ADD  AX, BX
    DEC  AX                ; 向上取整
    DIV  BX                ; = 目录占用扇区数
    ADD  [BIOS$_L], AX     ; 数据区始扇区 = 目录区 + 目录扇区数
    ADC  [BIOS$_H], 0

;==========================================================================
; 将逻辑扇区号(DX:AX)转换为 CHS 地址
;==========================================================================
DODIV:
    CMP  DX, SecLim        ; 防止 32/16 除法溢出
    JAE  DivOverFlow
    DIV  SECLIM            ; AX = 磁道，DX = 扇区内偏移
    INC  DL                ; 扇区号从 1 开始
    MOV  CURSEC, DL
    XOR  DX, DX
    DIV  HDLIM             ; AX = 柱面，DX = 磁头
    MOV  CURHD, DL
    MOV  CURTRK, AX
    CLC
    RET
DivOverFlow:
    STC
    RET

;==========================================================================
; 读取一个扇区（INT 13h AH=02h）
;==========================================================================
DOCALL:
    MOV  AH, 2             ; 读扇区命令
    MOV  DX, CURTRK        ; DX = 柱面
    MOV  CL, 6
    SHL  DH, CL            ; 柱面高 2 位移到 CL 高 2 位
    OR   DH, CURSEC        ; 扇区号在 CL 低 6 位
    MOV  CX, DX
    XCHG CH, CL            ; CX = 柱面(10位):扇区(6位)
    MOV  DL, PHYDRV        ; DL = 驱动器号
    MOV  DH, CURHD         ; DH = 磁头
    INT  13H
    RET
```

---

## 9. 附录：重要参考资源

| 资料 | 来源 |
|---|---|
| MS-DOS 4.0 源码 | `github.com/microsoft/MS-DOS` |
| MSBOOT.ASM 引导扇区 | `v4.0/src/BOOT/MSBOOT.ASM` |
| VERSION.INC 构建配置 | `v4.0/src/INC/VERSION.INC` |
| USA-MS.MSG 消息文本 | `v4.0/src/MESSAGES/USA-MS.MSG` |
| BOOT.SKL 消息骨架 | `v4.0/src/BOOT/BOOT.SKL` |
| FAT 文件系统规范 | Microsoft FAT32 Specification (2000) |
| INT 13h AH=02h 读扇区 | BIOS 中断手册，IBM PC-AT 技术参考 |
| MIT 6.828 JOS bootloader | `pdos.csail.mit.edu/6.828/2018/jos.git` |
| MBR 规范 | IBM PC-DOS 3.0 技术参考 (1985) |
| "Non-System disk" 消息 | `USA-MS.MSG` BOOT section, message 0001 |

---

*本文档基于 MS-DOS 4.00 源码（MIT 协议）撰写，
版本构建配置使用 IBMVER=TRUE, IBMCOPYRIGHT=FALSE（Clone 模式）。*
