# MIT 6.828 vs MS-DOS 引导代码对比

## 背景：一次典型的启动流程

当你按下电源键，CPU 复位后从地址 0xFFFF0 开始执行 BIOS 代码。BIOS 完成硬件自检后，根据启动顺序设置，将磁盘的**第一个扇区（LBA 0，512 字节）** 读到内存 **0x7C00** 处，然后跳转过去执行。这个扇区就叫作**引导扇区（boot sector）**。

本文对比的三份代码，都是写在这个扇区里的。但它们做的事情差别很大：

- **MS-DOS MBR** 是这个扇区最常见的工业标准实现——它含有分区表，负责找到可启动分区，再将控制权交给该分区的第一个扇区（VBR）。
- **MS-DOS VBR** 是分区自己的引导扇区，它需要理解 FAT 文件系统布局，找到 `IO.SYS` 文件并加载执行。
- **MIT 6.828 JOS boot** 是一个教学用途的引导代码，它不走分区表，不读文件系统，直接加载硬盘上后续扇区中的 ELF 格式内核。

三者的核心关系在于：**它们都占据 512 字节，都以 0x7C00 为加载地址，都以 55AA 作为有效标记，但它们的职责、复杂度、代码风格完全不同。**

---

## 一、代码结构概览

先从文件构成看起：

### MIT 6.828 boot

```
mit-6.828-mbr/
├── boot.S     ← 43 行 AT&T 汇编，做硬件初始化和模式切换
└── main.c     ← ~90 行 C 代码，读取 ELF 内核并跳转执行
```

`boot.S` 还依赖头文件 `inc/mmu.h`（定义 `SEG_NULL`、`SEG()` 宏）、`inc/x86.h` 和 `inc/elf.h`（定义磁盘 I/O 函数和 ELF 结构体）。

### MS-DOS MBR

```
ms-dos-mbr-boot-sector/MBR/
├── FDBOOT.ASM    ← ~80 行 8086 汇编，MBR 主体
├── BOOTREC.ASM   ← 封装 FDBOOT.ASM 输出为 C 数组供 FDISK 链接
├── FDBOOT.INC    ← 通过 DBOF 工具从 FDBOOT.BIN 生成的 DB 数组
├── MAKEFILE      ← 构建规则
├── BOOTREC.OBJ   ← 编译产物，链接入 FDISK.EXE
└── FDISK.C       ←（同目录或相邻）主程序，通过 _master_boot_record 写入 MBR
```

### MS-DOS VBR

```
ms-dos-mbr-boot-sector/BOOT/
├── MSBOOT.ASM    ← ~480 行 8086 汇编，VBR 主体
├── BOOT.SKL      ← 消息模板（.MSG 文件经 CL1.EXE 处理后的骨架）
├── MAKEFILE
├── MSBOOT.OBJ / MSBOOT.BIN
└── INC/ 下的 VERSION.INC ← 通过条件编译区分 MS、IBM、Clone 版本
```

MS-DOS 的 MBR 和 VBR 都是**纯 16 位 8086 汇编**，编译后通过自定义工具（DBOF）转成 DB 数组，嵌入到 C 主程序（FDISK.EXE / FORMAT.EXE）里。

---

## 二、各自的工作流程详解

### 2.1 MIT 6.828 boot 的工作流程

这个引导代码分两个阶段执行：

**第一阶段（boot.S）：硬件初始化**

BIOS 将 boot.S + main.c 合并后的二进制（共 ~380 字节，比 510 字节少很多）加载到 0x7C00 并执行。`boot.S` 的入口 `start` 执行以下步骤：

1. 关闭中断（`CLI`），确保切换模式时不会被中断干扰
2. 清段寄存器（`DS=ES=SS=0`），为保护模式做准备
3. 开启 A20 地址线——这是为了让 CPU 能访问 1MB 以上的内存。早期的 8086 只有 20 根地址线，到 80286 时为了兼容，A20 线默认强制为 0，需要通过键盘控制器 8042 的第 2 个端口来开启
4. 建立临时 GDT（全局描述符表），包含 3 个描述符：
   - 第 0 项：空描述符
   - 第 1 项：代码段，基址 0x0，限长 4GB，可执行 + 可读
   - 第 2 项：数据段，基址 0x0，限长 4GB，可写
5. 设置 CR0 保护模式使能位（PE = 1），通过 `LJMP` 远跳转到 32 位代码段
6. 初始化 32 位段寄存器：`DS=ES=FS=GS=SS=PROT_MODE_DSEG`
7. 设置栈顶为 `start`（即 0x7C00，栈向下生长到 0x7BFE 等地址）
8. 调用 `bootmain` 函数——这一步是 32 位保护模式下的远调用

**第二阶段（main.c）：读取并加载 ELF 内核**

`bootmain()` 是 C 函数，在保护模式下执行：

1. 调用 `readseg(0x10000, 4096, 0)`：
   - 从第 2 扇区（offset 0，转换为 sector 1）开始读取 8 个扇区（4096 字节）到物理地址 0x10000
   - 0x10000 在 JOS 中被定义为 `ELFHDR`，作为 ELF 头部的暂存区
2. 校验 `ELFHDR->e_magic` 是否等于 `ELF_MAGIC`（0x464C457F，即 `\x7fELF`）：
   - 不匹配则进入死循环，同时在 0x8A00 和 0x8A0E 端口输出错误码（QEMU 会用这个显示错误）
3. 遍历 ELF Program Header 表：
   - `ph = (struct Proghdr*)((uint8_t*)ELFHDR + ELFHDR->e_phoff)`
   - `eph = ph + ELFHDR->e_phnum`
   - 对每个段执行 `readseg(ph->p_pa, ph->p_memsz, ph->p_offset)`
   - 这里 `p_pa` 是物理加载地址，`p_memsz` 是要加载的字节数，`p_offset` 是段在文件中的偏移
4. 加载完所有段后，通过函数指针调用内核入口：
   - `((void(*)(void))(ELFHDR->e_entry))()`
   - 这个调用**不会返回**，因为内核接管后不会回到 bootloader

**`readsect` 函数的细节**（IDE PIO 模式的扇区读取）：

```
readsect(dst, offset):
  1. 等待磁盘就绪（端口 0x1F7 的状态位 bit 6=1 且 bit 7=0）
  2. 设置参数：
     0x1F2 ← 1           （读 1 个扇区）
     0x1F3 ← offset      （LBA 低 8 位）
     0x1F4 ← offset >> 8 （LBA 8-15 位）
     0x1F5 ← offset >> 16（LBA 16-23 位）
     0x1F6 ← (offset >> 24) | 0xE0（LBA 24-27 位 + 主盘标记）
     0x1F7 ← 0x20        （读扇区命令）
  3. 等待磁盘就绪
  4. INSL(0x1F0, dst, 128)  ← 从端口以 4 字节为单位读 128 次（共 512 字节）
```

**关键点**：MIT 使用 **LBA 模式** 访问磁盘（LBA 从 0 开始，扇区 0 是 bootloader，扇区 1+ 是内核），而 MS-DOS MBR 使用 **CHS 模式**。

### 2.2 MS-DOS MBR 的工作流程

`FDBOOT.ASM` 的工作是在实模式下完成的，它没有切换到保护模式。流程如下：

1. **自拷贝**（偏移量是 `ORG 0` 还是 `ORG 7C00` 决定了是否需要这一步）：
   - 将自身从 `0:7C00` 复制到 `0:0600`（共 512 字节）
   - 原因：VBR 加载到 0:7C00 时会覆盖 MBR，所以先搬走
   - 复制后通过 `JMP 0:0600+offset` 跳转到新位置继续执行

2. **验证分区表有效性**：
   - 检查偏移量 0x1BE（第一个分区表项）到 0x1FD（最后一个表项结束）之间的数据
   - 验证 55AA 签名
   - 若无效，显示错误信息 "Bad partition table"

3. **扫描分区表**：
   - 4 个分区表项，每个 16 字节，结构如下：
     ```
     字节 0: Boot Indicator (0x80 = Active, 0x00 = 非 Active)
     字节 1-3: CHS 起始地址（Head, Sector/Cylinder hi, Cylinder lo）
     字节 4: System ID（0x01 = FAT12, 0x04 = FAT16, 0x06 = BIGDOS, 0x0B = FAT32, 等等）
     字节 5-7: CHS 结束地址
     字节 8-11: LBA 起始扇区号（32 位）
     字节 12-15: 分区总扇区数（32 位）
     ```
   - 找到第一个 `Boot Indicator = 0x80` 的表项
   - 如果没有找到 Active 分区，显示 "Error loading operating system"
   - 如果找到了，检查是否还有其他 Active 分区；如果有，也报错

4. **读取 VBR**：
   - 从 Active 分区表项中提取 CHS 地址（字节 1-3）
   - 调用 `INT 13h AH=02h`（读扇区），CHS 参数直接来自分区表
   - 读 1 个扇区到 `0:7C00`
   - 重试逻辑：每次失败后重置磁盘系统（`INT 13h AH=00h`，DL=0x80），最多重试 5 次
   - 成功后验证 55AA 签名

5. **跳转**：
   - `JMP 0:7C00`，即跳到刚加载的 VBR
   - 此时 MBR 的任务结束，VBR 成为控制者
   - DL 寄存器保存了启动驱动器号（由 BIOS 传入，MBR 必须保留）

### 2.3 MS-DOS VBR 的工作流程

`MSBOOT.ASM` 比 MBR 复杂得多，因为它需要理解 **FAT 文件系统的布局**：

1. **硬件初始化**：
   - 读取 BIOS 磁盘参数表（INT 1Eh 的向量指向它）
   - 修改磁头稳定时间（将 `seek` 参数改为更保守的值）
   - 设置新的 INT 1Eh 向量指向自己修改后的参数表

2. **利用 BPB 计算磁盘布局**：
   ```
   BPB 字段示例（每扇区 512 字节的 FAT16 分区）：
     ByteSec = 512    （每扇区字节数）
     SecPerClus = 4   （每簇扇区数）
     cSecRes = 1      （保留扇区数，包括 VBR 自身）
     cFat = 2         （FAT 表份数）
     cSecFat = 64     （每份 FAT 的扇区数）
     DirNum = 512     （根目录条目数）
     cSecHid = 63     （隐藏扇区数，即 MBR 后的扇区数，对应分区偏移）
     cTotSec = 0      （用扩展 BPB 的 32 位字段）
   ```

   通过这些字段，VBR 计算出三个关键位置：
   ```
   DIR$ = cSecHid + cSecRes + cFat × cSecFat
        = 63 + 1 + 2 × 64
        = 192           ← 根目录起始扇区（LBA）

   BIOS$ = DIR$ + (DirNum × 32 + ByteSec - 1) / ByteSec
         = 192 + (512 × 32 + 512 - 1) / 512
         = 192 + 32
         = 224           ← 数据区起始扇区（LBA）
   ```

3. **搜索目录项**：
   - 读取根目录起始扇区到 `0:500` 缓冲区
   - 逐条检查目录项（每条 32 字节），比较前 11 个字节是否为 `"IO     SYS"`（注意填充空格）
   - 每个目录项格式：
     ```
     字节 0-7:   文件名（左对齐，空格填充）
     字节 8-10:  扩展名
     字节 11:    属性（0x27 = 隐藏|系统|只读|归档，IO.SYS 的典型属性）
     字节 12-21: 保留/其他元数据
     字节 22-23: 时间
     字节 24-25: 日期
     字节 26-27: 起始簇号（16 位）
     字节 28-31: 文件大小
     ```
   - 找到后，提取起始簇号（字节 26-27）

4. **读取并跳转**：
   - 假设 IO.SYS 存放在连续簇中（DOS 4.0 要求 IO.SYS 为连续文件）
   - 用起始簇号换算扇区地址：`数据区起始扇区 + (起始簇号 - 2) × 每簇扇区数`
   - 读取 3 个扇区（IO.SYS 的头 ~1.5KB）到 `0:0700`
   - `JMP FAR 0070:0700` 跳转到 IO.SYS

5. **错误处理**：
   - 没找到 "IO     SYS"：显示 "Non-System disk or disk error"
   - 磁盘读取失败：显示 "Disk error"
   - 两种错误都会等待按键，然后 `INT 19h` 重新启动

---

## 三、关键差异的深层解释

### 3.1 为什么 MIT 的引导代码不包含分区表？

MIT 6.828 是一个教学操作系统，不到 1 万行代码。它的设计前提是：
- 在 **QEMU 虚拟机** 或 **单用途实验环境** 中运行
- 整个磁盘仅用于 JOS 一个系统
- 不需要与 Windows/Linux 等多系统共存

所以 MIT 的 bootloader 直接占据磁盘 LBA 0，把内核镜像放在后面的连续扇区。
这种做法在实际的物理机上完全不可用——如果把它写入真实硬盘的 MBR 位置，
它会破坏分区表，导致所有操作系统都无法启动。

MS-DOS 的 MBR 则是 **工业标准**：通过在引导扇区末尾预留 64 字节分区表空间，
使得一块磁盘可以划分为最多 4 个分区。每个分区有自己的 VBR，各不干扰。
这个方案从 IBM PC/AT（1984）一直沿用至今（GPT 是扩展，不改变基本逻辑）。

### 3.2 为什么 MIT 代码切换到保护模式，而 MS-DOS 不切？

- **MIT** 需要保护模式，因为它的内核是 32 位的 ELF 格式。bootloader 必须在加载内核前切换到保护模式，否则无法执行 32 位代码。此外，保护模式下的 C 代码更容易编写——可以直接用指针和结构体，不用操心段寄存器和远指针。

- **MS-DOS 4.0** 是 16 位操作系统，完全工作在实模式下。它的内核 IO.SYS 也是 16 位代码。实模式有 1MB 内存上限，但 DOS 只需要这块空间（常规内存 640KB + UMB）。VBR 不需要切模式，跳转到 IO.SYS 后继续在实模式下运行。

更本质地说：**MIT 的 bootloader 和内核之间没有 OS 层**，bootloader 直接跳到 ELF 入口；DOS 的 VBR 跳到 IO.SYS——IO.SYS 本身包含了从实模式切换到保护模式的代码（DOS 4.0 的 HIMEM.SYS 提供保护模式下的 XMS 内存管理，但这与 VBR 无关）。

### 3.3 为什么 MS-DOS VBR 不解析 FAT 链表？

这是 MS-DOS 4.0 的一个设计约束。VBR 只有 512 字节，空间极其有限。解析 FAT 链（簇链表）的代码量太大，所以 DOS 要求 `IO.SYS` 和 `MSDOS.SYS` 在文件系统中**连续存放**。VBR 只需要读起始簇号的连续几个扇区，不需要跟进 FAT 链。

这种约束在 DOS 6.x 中开始放宽——一些第三方引导加载器（如 `SYS.COM`）支持非连续文件。
但在 DOS 4.0 的设计中，`SYS` 命令（FORMAT /S）在复制系统文件时，会特意将 IO.SYS 和 MSDOS.SYS 放在磁盘的连续区域。

### 3.4 I/O 方式不同

| | MIT 6.828 | MS-DOS MBR | MS-DOS VBR |
|---|---|---|---|
| 磁盘寻址 | **LBA**（通过 CHS 端口传 LBA 值） | **CHS**（直接使用分区表中的 CHS 地址） | **LBA**（DIR$/BIOS$ 是线性扇区号） |
| INT 类型 | 直接端口 I/O（0x1F0-0x1F7） | INT 13h AH=02h/00h | INT 13h 间接使用 |
| 错误处理 | 无（失败就死循环） | 重试最多 5 次 | 显示错误信息 |

MIT 不用 INT 13h 而是直接操作 IDE 控制器端口，是因为 JOS 是一个教学系统，
它希望学生理解硬件 I/O 细节。MS-DOS 则通过 BIOS 中断来保证兼容性——
BIOS 会处理不同磁盘控制器（IDE、SCSI、ESDI）的差异。

### 3.5 入口约定

| | MIT 6.828 | MS-DOS MBR → VBR | MS-DOS VBR → IO.SYS |
|---|---|---|---|
| 跳转方式 | `CALL *e_entry` | `JMP 0:7C00` | `JMP FAR 0070:0700` |
| 参数传递 | 无 | DL = 驱动器号 | CH = 介质类型, DL = 驱动器号, BX = 数据区扇区数 |
| 栈位置 | 0x7C00 向下 | 由前级设置 | 由前级设置 |
| CS:IP | 保护模式选择子:入口 | 0:7C00 | 0070:0700 |

注意 MIT 跳转到内核时使用的是保护模式的 **段选择子**（CS = PROT_MODE_CSEG = 0x08），
而不是实模式的段:偏移。这意味着内核入口代码也必须工作在保护模式下。

---

## 四、代码量对比

在 512 字节的限制下，每份代码的空间分配：

```
MIT 6.828:
┌─────────────────────────────────────────────┐
│ boot.S: ~60 字节                              │
│   - 开启 A20 地址线: ~30 字节                  │
│   - GDT + 保护模式切换: ~20 字节               │
│   - 远跳转 + 段寄存器初始化: ~10 字节            │
├─────────────────────────────────────────────┤
│ main.c（编译后 ~320 字节）                     │
│   - bootmain(): ~60 字节                      │
│   - readseg(): ~40 字节                       │
│   - readsect(): ~80 字节                      │
│   - waitdisk(): ~20 字节                      │
│   - 内联 I/O + 其他开销: ~120 字节             │
├─────────────────────────────────────────────┤
│ 55 AA: 2 字节                                 │
└─────────────────────────────────────────────┘
总计: ~382 字节（剩余 ~128 字节未用）

MS-DOS MBR (FDBOOT.ASM):
┌─────────────────────────────────────────────┐
│ 自拷贝代码: ~30 字节                           │
│ 分区表扫描逻辑: ~60 字节                       │
│ 错误处理 + 消息: ~50 字节                      │
│ INT 13h 调 用 + 重试: ~40 字节                │
│ INT 18h 兜底: ~3 字节                         │
│ 未使用保留字节: ~263 字节（占整体 446 字节的 59%）│
├─────────────────────────────────────────────┤
│ 分区表: 64 字节（4 × 16 字节）                │
│ 55 AA: 2 字节                                 │
└─────────────────────────────────────────────┘
总计: 512 字节（代码仅占用 183 字节，大量保留空间）

MS-DOS VBR (MSBOOT.ASM):
┌─────────────────────────────────────────────┐
│ JMP 近跳: 2 字节                              │
│ OEM ID: 8 字节                                │
│ BPB（基础 + 扩展）: 51 字节                    │
│ 磁盘参数表修改: ~40 字节                       │
│ DIR$/BIOS$ 计算: ~60 字节                     │
│ 目录搜索逻辑: ~120 字节                        │
│ I/O.SYS 读取: ~50 字节                        │
│ 错误消息 + 等待按键: ~100 字节                 │
│ 错误消息字符串本身: ~80 字节                   │
├─────────────────────────────────────────────┤
│ 55 AA: 2 字节                                 │
└─────────────────────────────────────────────┘
总计: 512 字节（几乎用完，VBR 是三者中最紧凑的）
```

VBR 的代码最需要压缩——它必须同时容纳 BPB 结构、磁盘计算逻辑、目录搜索逻辑
和错误消息文本。消息字符串占了将近 80 字节，这也是为什么 MSBOOT.ASM
通过 `.MSG → CL1.EXE → .CL1` 的预处理流程来管理——可以把消息文本和代码分离，
用 `%s` 插入到生成的 `BOOT.CL1` 中。

---

## 五、代码复用与工具链

### 5.1 MS-DOS 的双重编译模式

MS-DOS 的 MBR 和 VBR 都有一个独特的设计：**同一份源文件编译两次**。

第一次编译：
```
FDBOOT.ASM  →  MASM → FDBOOT.OBJ  →  LINK → FDBOOT.EXE  →  EXE2BIN → FDBOOT.BIN
```
产生一个独立的 512 字节引导扇区镜像。

第二次编译（通过 DBOF 工具）：
```
FDBOOT.BIN  →  DBOF → FDBOOT.INC
```
`FDBOOT.INC` 是一个汇编文件，内容类似于：
```asm
        DB      0FAh, 033h, 0C0h, 08Eh, 0D0h, 0BCh, 000h, 07Ch
        DB      016h, 007h, 0BBh, 078h, 000h, 036h, 0C7h, 006h
        ...（共 512 字节）
```

然后 `BOOTREC.ASM` 通过 `INCLUDE FDBOOT.INC` 将这个数组打包为一个结构体，
并通过 `PUBLIC _master_boot_record` 导出符号，使 C 代码能够引用：
```c
// FDISK.C
extern unsigned char _master_boot_record[];

void write_mbr(void) {
    // 调用 INT 13h 将 _master_boot_record 写入 LBA 0
    disk_write(0, (void far*)_master_boot_record, 1);
}
```

VBR 的编译路径完全对应：
```
MSBOOT.ASM → MSBOOT.BIN → DBOF → MSBOOT.INC → BOOT.INC → 链接入 FORMAT.EXE
```

### 5.2 MIT 6.828 的编译方式

MIT 使用交叉编译工具链 `i386-jos-elf-*`：

```
boot.S  →  i386-jos-elf-gcc -Os -S → boot.s
main.c  →  i386-jos-elf-gcc -Os -S → main.s
两者汇编后 → i386-jos-elf-ld -Ttext 0x7C00 -e start -N → boot.out
boot.out →  objcopy -S -O binary → boot.block
```

`-Ttext 0x7C00` 让链接器假设代码从 0x7C00 开始（与 BIOS 加载地址一致）。
`objcopy -O binary` 生成纯粹的二进制镜像，不包含 ELF 头或节信息。

---

## 六、从 BIOS 角度看引导顺序

为了更直观地理解三者的关系，这里模拟 BIOS 在执行三份代码时的步骤：

### 当磁盘的 LBA 0 是 MIT 6.828 bootloader：

```
BIOS:
  1. 读磁盘 LBA 0 → 0:7C00
  2. 验证最后两字节为 55 AA ✓
  3. JMP 0:7C00

MIT bootloader:
  01: CLI, CLD, XOR AX,AX, MOV DS/ES/SS ← 安全初始化
  02: 通过 8042 开启 A20                 ← 使能 1MB+ 寻址
  03: LGDT → 加载 GDT                   ← 建立保护模式的段描述符
  04: MOV CR0, PE=1 + LJMP             ← 切换到保护模式
  05: MOV DS/ES/FS/GS/SS ← 保护模式段   ← 更新段寄存器
  06: MOV ESP, 0x7C00                  ← 设置栈
  07: CALL bootmain                     ← 进入 C 代码
  08:   readsect(0x10000, 1)            ← 读第 2 扇区（ELF 头）
  09:   if (*(int*)0x10000 != ELF_MAGIC) 死循环
  10:   解析 Program Headers
  11:   for each ph:
           readsect(ph->p_pa, ph->p_offset)
         (将内核各段加载到指定物理地址)
  12:   ((void(*)())ELFHDR->e_entry)()  ← 执行内核
```

### 当磁盘的 LBA 0 是 MS-DOS MBR + 分区表：

```
BIOS:
  1. 读磁盘 LBA 0 → 0:7C00
  2. 验证 55AA ✓
  3. JMP 0:7C00

MBR (FDBOOT.ASM):
  01: MOV SI, SP; MOV DI, 0x600; MOV CX, 0x100; REP MOVSW  ← 自拷贝到 0x600
  02: JMP 0x600 + (继续执行的偏移)
  03: 检查 0x1BE - 0x1FD 合法性，验证 55AA
  04: 扫描 4 个分区表项，找 0x80 标记
  05: 取第一个 Active 表项的 CHS 地址
         例: Head=1, Sector=0, Cylinder=0
  06: MOV AX, 0x0201; MOV CX, Sector|(Cylinder<<8); MOV DX, 0x0080; INT 13h
         （重试最多 5 次）
  07: 验证刚读的扇区最后两字节为 55AA
  08: JMP 0:7C00  ← 跳转到 VBR

VBR (MSBOOT.ASM):
  01: JMP 引导代码（跳过 BPB）
  02: 读取 BPB 字段，计算 DIR$ 和 BIOS$
  03: 读 DIR$ 扇区到 0:500
  04: 搜索 "IO     SYS"
  05: 找到 → 取起始簇号 → 换算扇区地址
  06: 读 3 扇区到 0070:0700
  07: JMP FAR 0070:0700  ← 跳转到 IO.SYS
```

关键区别在于：MIT 的代码在内存中 **只占用 0x7C00-0x7D7B**（约 380 字节），
之后直接加载内核；而 MS-DOS 的 MBR 先把自己搬走（占用 0x600-0x7FF），
再把 VBR 加载到原来的 0x7C00 位置，形成接力启动链。

---

## 七、学术与现实的区别

### 7.1 为什么 MIT 的 bootloader 不适合真实硬件？

1. **无分区表** — 写入磁盘 LBA 0 会覆盖分区表，导致其他操作系统无法启动
2. **直接端口 I/O** — 绕过 BIOS INT 13h，不兼容非 IDE 磁盘（SCSI、NVMe、USB）
3. **固定扇区读取** — 假设内核从第 2 扇区开始，没有容错
4. **ELF 格式限制** — 只能启动 ELF 内核，不能加载 Windows、Linux 或其他 DOS
5. **无错误恢复** — 磁盘读取出错直接死循环，用户无任何反馈

### 7.2 为什么 MS-DOS 的引导方案能用几十年？

1. **分区表标准** — 同一个 MBR 可引导 DOS、Windows 9x、Linux（通过 GRUB/引导管理器）
2. **INT 13h 兼容层** — BIOS 适配了 30 年的磁盘硬件变化，VBR/MBR 不用改
3. **BPB 自描述** — 每份 VBR 通过 BPB 感知当前分区的几何参数，无需硬编码
4. **错误反馈** — 显示明确的错误信息："Bad partition table"、"Non-System disk"

### 7.3 如果用一句话总结：

> **MIT 的 bootloader 演示了"在 512 字节内让内核跑起来"的最小可行性——但它只对自己的内核负责。MS-DOS 的 MBR 和 VBR 则展示了工业软件如何在同样的 512 字节限制下，兼顾多分区、多系统、文件系统兼容性和用户反馈。**
