# MIT 6.828 JOS Bootloader 编译与启动

本文讲解 `mit-6.828-jos/boot/` 中的 `boot.S` 和 `main.c` 是如何被编译成
512 字节引导扇区，并在 QEMU 虚拟机中加载 JOS 内核的：

| 文件 | 编译产物 | 写入位置 | 写入工具 | 作用 |
|------|---------|---------|---------|------|
| `boot.S` + `main.c` | `boot` (裸二进制) | 磁盘 LBA 0 | `dd` 或 QEMU 直接加载 | 开启 A20 + 保护模式，加载 ELF 内核 |

对比 MS-DOS 的两层结构，MIT 只有**一个引导扇区**，它同时做了 MBR 和 VBR 的工作，
只是做得更少——不用分区表，不用文件系统，直接从固定扇区位置读 ELF 内核。

---

## 0. 五句话扫清背景知识

### 问题一：MIT 6.828 的 bootloader 是什么？

MIT 6.828（2018）是 MIT 的操作系统课程，让学生从零写一个叫 **JOS** 的教学内核。
课程提供了两个引导文件：

- **`boot.S`**（汇编）：负责 CPU 初始化——开启 A20 地址线、加载 GDT、切换到
  32 位保护模式、设置栈，然后跳转到 C 代码。
- **`main.c`**（C）：负责磁盘 I/O——通过 IDE 控制器直接读取后续扇区，
  解析 ELF 格式内核头，将内核各段加载到指定物理地址，然后跳转执行。

**类比**：`boot.S` 是"开门的人"（把你从实模式带到保护模式），
`main.c` 是"搬行李的人"（从硬盘搬数据到正确的位置）。

### 问题二：它有多大？

| | 代码 | 数据 | 总大小 |
|---|------|------|--------|
| boot.S | 43 行 (编译后 ~60 字节) | GDT 表 + 描述符 (~20 字节) | ~80 字节 |
| main.c | ~90 行 (编译后 ~300 字节) | 无 | ~300 字节 |
| 签名 | - | 55 AA | 2 字节 |
| **总计** | | | **~382 字节**（远小于 510 字节上限） |

`sign.pl` 脚本会在编译完成后检查：如果超过 510 字节则报错，否则填充零到
510 字节，追加 55AA 签名。

### 问题三：MIT bootloader 和 MS-DOS MBR/VBR 有什么本质区别？

| | MS-DOS MBR | MS-DOS VBR | MIT bootloader |
|---|---|---|---|
| 包含分区表 | 是 | 否 | **否** |
| 包含 BPB / 文件系统逻辑 | 否 | 是 | **否** |
| CPU 模式 | 16 位实模式 | 16 位实模式 | **切换到 32 位保护模式** |
| 加载下一级的方式 | 读分区表项 → 读固定扇区 | 读根目录 → 找文件名 | **读固定扇区 → 解析 ELF 头** |
| 下一级是什么 | VBR（任何 OS） | IO.SYS | **ELF 内核（必须是 JOS 格式）** |
| 实际硬件可用 | 是 | 是 | **否**（仅 QEMU / 实验环境） |

关键点：MIT 不做分区表、不做文件系统，它假设"第 2 扇区开始就是 ELF 内核"。
这是一个**教学简化**，不是工业标准。

### 问题四：我们的源代码目录里有什么？

```
mit-6.828-mbr/
├── boot/
│   ├── boot.S          ← 汇编入口（A20 + GDT + 保护模式）
│   ├── main.c          ← C 代码（IDE 读盘 + ELF 加载）
│   ├── Makefrag        ← make 构建规则片段
│   └── sign.pl         ← Perl 脚本：填充零 + 添加 55AA 签名
├── inc/
│   ├── types.h         ← 定长整数类型定义（bootloader 需要的基础类型）
│   ├── mmu.h           ← GDT 宏、CR0 标志、段描述符结构
│   ├── x86.h           ← inb/outb/insl 等端口 I/O 内联函数
│   └── elf.h           ← ELF 头部 + Program Header 结构体
└── GNUmakefile         ← 顶级构建文件
```

### 问题五：为什么混合汇编和 C？

和 MS-DOS 不同，MIT 的 bootloader 用汇编做了最小启动后，立刻切换到保护模式并
**调用 C 代码**。这是因为：

1. **C 代码更易读**——磁盘 I/O 和 ELF 解析如果用汇编写，代码量会翻几倍
2. **保护模式让 C 可用**——保护模式下段基址为 0，32 位地址空间直接可达，
   指针操作和结构体访问和普通 C 程序一样
3. **不需要嵌入其他程序**——MIT 的 bootloader 是独立二进制，不像
   MS-DOS 那样需要嵌入 FDISK/FORMAT。所以不需要"编译两次"那一套

---

## 1. 编译链全解析

### 1.1 最终产物是什么？

```
boot.S + main.c → 编译、链接、后处理 → obj/boot/boot（512 字节裸二进制）
```

这个 `obj/boot/boot` 文件就是**磁盘第一个扇区**的镜像。
QEMU 启动时，直接把这个文件的内容读到 0x7C00 开始执行。

### 1.2 编译链分步详解

```
boot.S ──┐
         ├── i386-jos-elf-gcc ──→ obj/boot/boot.o
main.c ──┘
                                    │
                                    ↓
                    obj/boot/boot.o + obj/boot/main.o
                                    │
                         ld -N -e start -Ttext 0x7C00
                                    │
                                    ↓
                              obj/boot/boot.out
                           （ELF 格式可执行文件）
                                    │
                            objcopy -S -O binary -j .text
                                    │
                                    ↓
                              obj/boot/boot
                          （裸二进制，~380 字节）
                                    │
                              perl sign.pl
                                    │
                                    ↓
                              obj/boot/boot
                          （填充 0 到 510 字节 + 55AA）
```

**类比**：

- **GCC** = 翻译官，把汇编和 C 翻译成机器码目标文件（`.o`）
- **LD（链接器）** = 组装工，把所有 `.o` 拼在一起，修复地址。
  `-Ttext 0x7C00` 告诉链接器：代码从物理地址 0x7C00 开始（这和 BIOS 加载地址一致）。
- **OBJCOPY** = 剥皮工，把 ELF 格式的外壳（文件头、节头表等）剥掉，
  只留下裸机器码。`-j .text` 表示只保留 `.text` 节。
- **sign.pl** = 质检员，检查是否超 510 字节，不对齐则填充，最后贴上 55AA 标签。

**关键参数解释**：

| 参数 | 含义 | 为什么需要 |
|------|------|-----------|
| `-N` | 设置 `.text` 为可读写（不纯读） | bootloader 的某些构造需要段可写 |
| `-e start` | 入口点为 `start` 标签 | 告诉链接器从哪开始执行 |
| `-Ttext 0x7C00` | 代码段起始地址为 0x7C00 | BIOS 加载地址就是 0x7C00 |
| `-S` (objcopy) | 剥离调试信息和符号表 | 减小产物大小，不需要调试信息 |
| `-O binary` | 输出为纯二进制 | 去除 ELF 外壳，只留机器码 |
| `-j .text` | 只复制 .text 节 | 排除 .data/.bss 等（引导代码不需要） |

**对比 MS-DOS 编译链的 MASM → LINK → EXE2BIN**：

```
MS-DOS 链:   ASM  → MASM → .OBJ → LINK → .EXE → EXE2BIN → .BIN
MIT 链:      .S/.c → GCC → .o    → LD   → .out → objcopy → boot
                                    ↑            ↑
                                 功能等同      功能等同
                                 LINK         EXE2BIN
```

MIT 的工具链用 GNU 的开源工具替代了 MASM + LINK + EXE2BIN 的组合。
`LD -Ttext 0x7C00` 相当于 LINK 中指定 `ORG 7C00h`，
`OBJCOPY -O binary` 做的事情和 EXE2BIN 完全一样——剥离可执行文件头部。

### 1.3 Makefrag 中的实际构建规则

```makefile
# 编译 boot.S 为 .o
$(OBJDIR)/boot/%.o: boot/%.S
    $(CC) -nostdinc $(KERN_CFLAGS) -c -o $@ $<

# 编译 main.c 为 .o（启用了 -Os 尺寸优化）
$(OBJDIR)/boot/main.o: boot/main.c
    $(CC) -nostdinc $(KERN_CFLAGS) -Os -c -o $@ $@.c

# 链接 + 转二进制 + 签名
$(OBJDIR)/boot/boot: $(BOOT_OBJS)
    $(LD) $(LDFLAGS) -N -e start -Ttext 0x7C00 -o $@.out $^
    $(OBJDUMP) -S $@.out >$@.asm          ← 生成反汇编供调试
    $(OBJCOPY) -S -O binary -j .text $@.out $@
    perl boot/sign.pl $@                   ← 填充 + 签名
```

注意 `$(OBJDUMP) -S $@.out >$@.asm` 这一行——它生成一份带源码的反汇编文件，
方便学生对照汇编和 C 源码来调试引导代码。这也是教学工具链的一个特点。

### 1.4 sign.pl 签名脚本

这是整个编译链的最后一步，只有 23 行 Perl：

```perl
open(BB, $ARGV[0]) || die "open $ARGV[0]: $!";
binmode BB;
my $buf;
read(BB, $buf, 1000);
$n = length($buf);

if($n > 510){
    print STDERR "boot block too large: $n bytes (max 510)\n";
    exit 1;
}
print STDERR "boot block is $n bytes (max 510)\n";

$buf .= "\0" x (510-$n);    # 填充零到 510 字节
$buf .= "\x55\xAA";          # 追加启动签名

open(BB, ">$ARGV[0]") || die "open >$ARGV[0]: $!";
binmode BB;
print BB $buf;
close BB;
```

做的事情很简单：

1. 读取已经生成的 boot 镜像
2. 如果超过 510 字节，报错退出（但实际只有 ~380 字节，不会触发）
3. 填充零到恰好 510 字节
4. 追加 `55 AA` 签名
5. 写回文件

**

对比 MS-DOS 的 MBR/VBR 编译**：MS-DOS 在汇编代码中通过 `ORG` 和 `DB` 伪指令
预留了签名位置，而 MIT 在编译后用 Perl 脚本动态添加。后者的方式更灵活，
不需要在源码中操心对齐问题。

---

## 2. boot.S 逐段详解

### 2.1 功能概览

`boot.S` 是引导代码的第一阶段，只需要做 5 件事：

```
1. 关中断、清方向位、清段寄存器
2. 开启 A20 地址线
3. 建立临时 GDT（三段：空 + 代码 + 数据）
4. 切换到保护模式
5. 远跳转到 32 位代码段 → 设置栈 → 调用 bootmain
```

全部 42 行有效代码，去掉空行和注释只有 ~30 条指令。

### 2.2 逐行分析

#### 头文件和常量定义

```asm
#include <inc/mmu.h>              ; GDT 宏（SEG_NULL, SEG）和 CR0 标志

.set PROT_MODE_CSEG, 0x8         ; 保护模式代码段选择子（GDT 索引 1）
.set PROT_MODE_DSEG, 0x10        ; 保护模式数据段选择子（GDT 索引 2）
.set CR0_PE_ON,      0x1         ; CR0 保护模式使能位
```

`PROT_MODE_CSEG = 0x8`（二进制 0000 1000）：RPL=0，TI=0（GDT），Index=1（第二项）。
`PROT_MODE_DSEG = 0x10`（二进制 0001 0000）：Index=2（第三项）。

选择子的值为 `Index × 8`，因为每个 GDT 描述符正好 8 字节。

#### 入口与实模式初始化

```asm
start:
    .code16                     ; 告诉汇编器：以下是 16 位代码
    cli                         ; 关中断——切换模式时不能有中断
    cld                         ; 清方向位——字符串操作从低到高

    xorw    %ax,%ax
    movw    %ax,%ds             ; DS = 0
    movw    %ax,%es             ; ES = 0
    movw    %ax,%ss             ; SS = 0
```

`CLI` 是必须的：在切换 GDT 和 CR0 时，如果发生中断，中断处理程序会使用旧的
段描述符表，导致三重故障（triple fault）或不可预料行为。

清段寄存器是因为 BIOS 可能在进入 bootloader 前设置了不确定的值。
确保它们都是 0，让后续的地址计算可预测。

#### 开启 A20 地址线

```asm
seta20.1:
    inb     $0x64,%al           ; 读键盘控制器状态
    testb   $0x2,%al            ; 检查 Input Buffer Full 位
    jnz     seta20.1            ; 忙则等待

    movb    $0xd1,%al           ; 命令：写输出端口
    outb    %al,$0x64

seta20.2:
    inb     $0x64,%al
    testb   $0x2,%al
    jnz     seta20.2

    movb    $0xdf,%al           ; 数据：A20 使能
    outb    %al,$0x60
```

**为什么要开启 A20？**

历史原因。8086 只有 20 根地址线，访问 0x10000-0x10FFEF 的地址时回绕到
0x00000-0xFFEF。80286 有 24 根地址线，不再回绕。但为了兼容 8086 软件，
IBM PC/AT 设计了 A20 Gate，默认将第 21 根地址线（A20）强制为 0，
让 80286 模拟 8086 的回绕行为。

JOS 内核加载到 0x100000（1MB）以上，所以必须开启 A20，否则访问高位内存时
地址会被截断。

**为什么通过键盘控制器？**

A20 gate 的硬件设计连在键盘控制器（8042）的输出端口上，因为主板上只有这个
芯片有额外的通用 I/O 引脚可用。虽然名字叫"键盘控制器"，但 8042 实际上
也负责 A20 和复位 CPU。

方法是通过端口 0x64 发送命令 `0xD1`（写输出端口），然后通过端口 0x60
发送数据 `0xDF`（置位 A20 使能位）。

#### 加载 GDT 并切换保护模式

```asm
    lgdt    gdtdesc             ; 加载 GDT 描述符（基址 + 限长）
    movl    %cr0, %eax
    orl     $CR0_PE_ON, %eax    ; CR0 的最低位置 1
    movl    %eax, %cr0          ; 切换到保护模式
```

`LGDT gdtdesc` 加载一个 6 字节的伪描述符（pseudo-descriptor）：
```
gdtdesc:
    .word   0x17                ; GDT 限长 = 24 字节（3 个描述符 × 8 字节 - 1）
    .long   gdt                 ; GDT 基址
```

GDT 本身在下方定义：
```asm
gdt:
    SEG_NULL                    ; 索引 0：空描述符（必须）
    SEG(STA_X|STA_R, 0x0, 0xffffffff)  ; 索引 1：代码段，基址 0，限长 4GB
    SEG(STA_W, 0x0, 0xffffffff)        ; 索引 2：数据段，基址 0，限长 4GB
```

`SEG(type, base, lim)` 是 `inc/mmu.h` 中定义的宏：
```asm
#define SEG(type,base,lim) \
    .word (((lim) >> 12) & 0xffff), ((base) & 0xffff); \
    .byte (((base) >> 16) & 0xff), (0x90 | (type)), \
        (0xC0 | (((lim) >> 28) & 0xf)), (((base) >> 24) & 0xff)
```

展开后生成 8 字节描述符。`0x90 = 10010000`：Present=1, DPL=0, S=1（代码/数据段）。
`0xC0`：G=1（4KB 粒度）, D/B=1（32 位段）。

**注意**：两个段都设置基址为 0、限长为 4GB，这意味着保护模式下的
虚拟地址（逻辑地址）和物理地址一一对应，不需要段转换。
这是 GDT 的"扁平模型"（flat model）。

#### 远跳转并进入 32 位模式

```asm
    ljmp    $PROT_MODE_CSEG, $protcseg   ; 远跳转刷新 CS

    .code32                     ; 告诉汇编器：以下是 32 位代码
protcseg:
    movw    $PROT_MODE_DSEG, %ax
    movw    %ax, %ds
    movw    %ax, %es
    movw    %ax, %fs
    movw    %ax, %gs
    movw    %ax, %ss
```

`LJMP` 的两重作用：

1. **刷新 CS 寄存器**：切换 CR0 后，CS 还是旧的 16 位段选择子。
   通过 `LJMP` 加载新的选择子 `0x8`，CPU 才真正开始在保护模式下取指。
2. **切换执行模式**：从 `.code16` 切换到 `.code32`。
   这之后的指令都被 CPU 解释为 32 位指令。

然后所有段寄存器都设为 `0x10`（数据段选择子）。
注意这里也设置了 `FS` 和 `GS`——这是 MS-DOS MBR/VBR 不需要做的，
因为实模式下只有 DS、ES、SS 三个数据段寄存器可用。

#### 设置栈并跳转到 C

```asm
    movl    $start, %esp        ; ESP = 0x7C00（栈向下生长）
    call    bootmain
```

**为什么栈顶设在 0x7C00？**

因为 BIOS 把 bootloader 加载到 `0x00007C00-0x00007DFF`，而 `0x00007C00`
以下是未使用的内存。栈从 0x7C00 向下生长，可以安全地使用到 ~0x7A00
（约 512 字节栈空间，bootmain 用不了多少）。

注意 `$start` 就是 `0x7C00`（链接器参数 `-Ttext 0x7C00` 设定）。

#### 兜底死循环

```asm
spin:
    jmp spin
```

如果 `bootmain()` 返回（正常情况下不会），CPU 就在原地死循环。
这是引导代码的常见做法——没有地方可以返回了。

### 2.3 boot.S 代码布局

```
                                 ┌─────────────┐
0x7C00  start:                   │ cli; cld    │
                                 │ xor ax,ax   │
                                 │ mov ds/es/ss│
                                 │ seta20 ...   │ ← 开启 A20
                                 │ lgdt gdtdesc│
                                 │ mov cr0     │ ← 切保护模式
                                 │ ljmp ...    │
0x7C3C  protcseg:                │ mov ds/es/..│
                                 │ mov esp     │
                                 │ call bootmain│
                                 │ spin: jmp   │
0x7C58  gdt:                     │ SEG_NULL    │ ← 8B
                                 │ CODE_SEG    │ ← 8B
                                 │ DATA_SEG    │ ← 8B
0x7C64  gdtdesc:                 │ .word 0x17  │ ← 2B
                                 │ .long gdt   │ ← 4B
                              ── └─────────────┘
                                （~110 字节，含 padding）
```

---

## 3. main.c 逐段详解

### 3.1 功能概览

`main.c` 的代码比 `boot.S` 多一倍（~90 行），但做的事更复杂：

```
bootmain():
  1. 读扇区 1-8（ELF 头）到 0x10000
  2. 检查 ELF 魔数
  3. 遍历 Program Headers → 从文件偏移处读数据到物理地址
  4. 跳转到 ELF 入口

readseg():  包装函数，按字节数 + 偏移读
readsect(): 最底层，用 IDE PIO 读一个扇区
waitdisk(): 等待磁盘控制器就绪
```

### 3.2 常量与声明

```c
#define SECTSIZE    512
#define ELFHDR      ((struct Elf *) 0x10000)

void readsect(void*, uint32_t);
void readseg(uint32_t, uint32_t, uint32_t);
```

`ELFHDR` 被定义为固定地址 `0x10000`（物理地址 1MB 边界处）。
这里为什么选 0x10000？

- 0x10000（64KB）是一个方便的暂存区
- 这个地址在 bootloader 和内核之间的过渡期是空闲的
- 内核最终可能会加载到别处，所以这个区域可以被覆盖

### 3.3 bootmain()——主函数

```c
void bootmain(void)
{
    struct Proghdr *ph, *eph;

    // 读第 2-9 扇区到 0x10000（ELF 头 + Program Header 表）
    readseg((uint32_t) ELFHDR, SECTSIZE*8, 0);

    // 检查 ELF 魔数
    if (ELFHDR->e_magic != ELF_MAGIC)
        goto bad;

    // 遍历 Program Headers
    ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
    eph = ph + ELFHDR->e_phnum;
    for (; ph < eph; ph++)
        readseg(ph->p_pa, ph->p_memsz, ph->p_offset);

    // 跳转到内核入口
    ((void (*)(void)) (ELFHDR->e_entry))();

bad:
    outw(0x8A00, 0x8A00);
    outw(0x8A00, 0x8E00);
    while (1)
        /* do nothing */;
}
```

**步骤一：读取 ELF 头**

`readseg(0x10000, 4096, 0)` 从**第 2 扇区**（内核的起始位置）开始读 8 个扇区：
- 第 2 扇区 → ELF Header（~52 字节）
- 第 3-9 扇区 → Program Header 表和其他早期数据

4096 字节 = 8 个扇区 = 一个 4KB 页面。JOS 内核很小，8 扇区足够容纳
ELF 头和 Program Header 表了。

**步骤二：验证 ELF 魔数**

`ELF_MAGIC = 0x464C457F` 在 `inc/elf.h` 中定义：
```c
#define ELF_MAGIC 0x464C457FU   /* "\x7FELF" in little endian */
```

内存中实际是 `\x7F E L F`。如果首 4 字节不是这个值，说明磁盘上的内核
格式不对。

**步骤三：解析 Program Headers**

```
ELF Header 结构（从 0x10000 开始）：
  e_entry     = 入口点地址（如 0x1000A0）
  e_phoff     = Program Header 表偏移（如 52 字节）
  e_phnum     = Program Header 数量（如 2 个）

Program Header 表（在 0x10000 + 52 字节处）：
  [0]  p_type  = PT_LOAD（1）
       p_pa    = 0x100000 （加载到物理地址 1MB）
       p_offset= 0x3400   （在 ELF 文件中的偏移）
       p_memsz = 0x7A00   （加载 29.75KB）
  [1]  p_type  = PT_LOAD
       p_pa    = 0xF0100000（虚拟地址，通过页表映射到物理地址）
       p_offset= ...
       p_memsz = ...
```

对每个 `p_type == PT_LOAD` 的段，`readseg` 从对应文件偏移处读取
数据到 `p_pa` 指定的物理地址。

**步骤四：跳转到内核入口**

`((void (*)(void))(ELFHDR->e_entry))()` 将 `e_entry` 的值（一个 32 位地址）
当作函数指针调用。内核的入口点通常用汇编写（`kern/entry.S`），
做最后的初始化（设置页表、开启分页、跳转到 `i386_init()`）。

### 3.4 readseg()——按字节偏移读盘

```c
void readseg(uint32_t pa, uint32_t count, uint32_t offset)
{
    uint32_t end_pa;

    end_pa = pa + count;
    pa &= ~(SECTSIZE - 1);       // 向下对齐到扇区边界

    offset = (offset / SECTSIZE) + 1;  // 字节偏移 → 扇区号（+1 跳过 boot 扇区）

    while (pa < end_pa) {
        readsect((uint8_t*) pa, offset);
        pa += SECTSIZE;
        offset++;
    }
}
```

**`offset` 的转换**：

`readseg` 的参数 `offset` 是**文件内的字节偏移**。由于内核数据从**第 2 扇区**
（扇区 1）开始，所以需要做两个换算：

1. `offset / SECTSIZE`：字节偏移 → 扇区偏移
2. `+ 1`：跳过 boot 扇区（扇区 0）

例如：
- `readseg(..., ..., 0)` → 从扇区 1 开始读（即内核的第 1 扇区）
- `readseg(..., ..., 4096)` → 从扇区 9 开始读（因为 4096/512 + 1 = 9）

**`pa` 的对齐**：

`pa &= ~(SECTSIZE - 1)` 确保物理地址向下对齐到 512 字节边界。
`readsect` 一次读 512 字节，如果 `pa` 不是 512 的倍数，会覆盖 `pa` 之前的数据。
实际使用时，`pa` 通常已经是对齐的，这个操作是安全保障。

### 3.5 readsect()——IDE PIO 读一个扇区

```c
void readsect(void *dst, uint32_t offset)
{
    waitdisk();

    outb(0x1F2, 1);
    outb(0x1F3, offset);
    outb(0x1F4, offset >> 8);
    outb(0x1F5, offset >> 16);
    outb(0x1F6, (offset >> 24) | 0xE0);
    outb(0x1F7, 0x20);

    waitdisk();
    insl(0x1F0, dst, SECTSIZE/4);
}
```

这是标准的 **IDE PIO（Programmed I/O）** 读扇区流程。

**IDE 控制器端口映射**：

| 端口 (IO 地址) | 功能 | 值含义 |
|---------------|------|-------|
| 0x1F2 | 扇区计数 | 1（读 1 个扇区） |
| 0x1F3 | LBA 低 8 位 | `offset & 0xFF` |
| 0x1F4 | LBA 8-15 位 | `(offset >> 8) & 0xFF` |
| 0x1F5 | LBA 16-23 位 | `(offset >> 16) & 0xFF` |
| 0x1F6 | LBA 24-27 位 + 驱动器选择 | `(offset >> 24)` \| `0xE0` |
| 0x1F7 | 命令寄存器 | `0x20` = READ SECTORS |
| 0x1F0 | 数据端口（16 位/32 位读） | 读 `SECTSIZE/4` 次 (128 次 dword) |

**LBA 寻址**：

MIT 使用的是 **LBA（Logical Block Addressing）** 模式，而不是 MS-DOS MBR 使用的 CHS。
LBA 让扇区编号简化为一个线性数字：0, 1, 2, ...，而不是 CHS 的三维结构。

`0xE0` 在端口 0x1F6 中的含义：
- Bit 7 = 1（LBA 模式使能）
- Bit 6 = 1（选择主设备）
- Bit 5 = 1（保留）
- Bit 4 = 0（从设备 = 0，主设备 = 0）
- Bit 3-0 = LBA 的 bits 24-27

### 3.6 waitdisk()——等待磁盘就绪

```c
void waitdisk(void)
{
    while ((inb(0x1F7) & 0xC0) != 0x40)
        /* do nothing */;
}
```

读取 0x1F7 端口（状态寄存器），检查 bit 7（BSY）和 bit 6（DRDY）：
- bit 7 = 0（不忙）且 bit 6 = 1（就绪）= 0x40 → 可以操作
- bit 7 = 1 → 磁盘忙，继续等待

注意 MS-DOS 的 MBR 和 VBR 也做同样的事，但通过 INT 13h 间接完成——BIOS
在 INT 13h 内部处理了这些端口操作和等待逻辑。

### 3.7 readsect 和 waitdisk 对比 MS-DOS

| | MIT (main.c) | MS-DOS (MSBOOT.ASM) |
|---|---|---|
| 磁盘接口 | **直接端口 I/O**（0x1F0-0x1F7） | **INT 13h**（BIOS 中断） |
| 寻址模式 | **LBA**（线性扇区号） | 兼容 LBA 或 CHS |
| 一次读多少 | 1 扇区 | 1-多扇区 |
| 错误处理 | **无**（死循环） | 重试或显示错误 |
| 等待方式 | 忙等（spin wait） | INT 13h 内部处理 |

MIT 选择直接端口 I/O 而不是 INT 13h 的原因：
1. **教学目的**——让学生看到磁盘控制器的真实接口
2. **简化依赖**——不需要依赖 BIOS 的 INT 13h 实现（QEMU 的 BIOS 可能不够标准）
3. **性能**——直接 PIO 比 INT 13h 少一层调用开销（不过 bootloader 不需要关心性能）

---

## 4. 内核 ELF 布局与加载过程

### 4.1 磁盘布局

```
扇区 0:     [boot.S + main.c 编译产物]  ← 512 字节引导扇区
扇区 1-8:   [ELF Header + Program Headers + 内核代码/数据]
             ↑ 被 readseg(0x10000, 4096, 0) 读取
扇区 9+:    [其余内核数据]
```

### 4.2 加载过程的内存布局

假设 JOS 内核有典型的两个 PT_LOAD 段：

```
加载前（磁盘上）:

ELF Header (52B)     → 位于扇区 1 的开头
Program Header[0]    → 在 ELF 头后的偏移 e_phoff 处
  p_pa = 0x100000    → 加载到 1MB 处
  p_offset = 0x3400  → 该段在 ELF 文件中的偏移
  p_filesz = 0x79C8  → 文件中的数据大小
Program Header[1]
  p_pa = 0xF0100000  → 虚拟地址
  p_offset = 0x10000
  p_filesz = 0x2000
```

加载后（物理内存中）:

```
地址 0x00010000 → ELF Header (暂存，加载后可丢弃)
地址 0x00100000 → .text + .data + .rodata (段 0)
地址 0xF0100000 → 高地址段（实际通过页表映射到物理地址）
```

但注意：JOS 内核启用了分页（在 `kern/entry.S` 中），所以 `p_pa = 0xF0100000`
的段实际上是通过页表映射到某个物理地址的。但 bootloader 不需要管这个——
它只是机械地把数据读到 `p_pa` 指定的物理地址。

### 4.3 加载过程可视化

```
bootmain() 执行过程：

初始状态：
  内存 0x7C00 = bootloader
  内存 0x0000-0x7BFF = 空闲
  磁盘扇区 0 = bootloader
  磁盘扇区 1+ = JOS 内核 ELF

↓ ① readseg(0x10000, 4096, 0)

  内存 0x10000-0x10FFF = ELF Header + Program Headers + 部分内核数据
                 ^ 8 个扇区

↓ ② 校验 e_magic == 0x464C457F ✓
↓   读取 e_phoff = 0x34, e_phnum = 2

↓ ③ for each Program Header:

  [0] readseg(0x100000, 0x79C8, 0x3400)
      → 从扇区 (0x3400/512 + 1) = 27 开始读
      → 加载到物理地址 1MB
      → 共约 31KB 数据（62 个扇区）

  [1] readseg(0xF0100000, 0x2000, 0x10000)
      → 从扇区 (0x10000/512 + 1) = 129 开始读
      → 加载到物理地址 0xF0100000
      → 但分页还未开启，这个地址需要后续页表映射
      → 或者 JOS 的设计是：bootloader 只加载物理地址段，
        高地址段由 entry.S 在分页开启后处理

      实际上，JOS 的 bootloader 只加载了一个段到 1MB 物理地址。
      e_entry 通常指向这个段的入口。
      分页和映射到高地址的工作由内核自己的 entry.S 完成。

↓ ④ ((void(*)())0x1000A0)()  ← 跳到内核入口

  控制权移交给内核，bootloader 完成使命。
```

---

## 5. 完整的启动流程

```
QEMU 启动（或真机加电）
  │
  │ CPU 复位 → 进入实模式 → CS=0xF000, IP=0xFFF0
  │ 执行 BIOS 代码（POST + 设备初始化）
  │
  │ INT 19h → 读启动设备的 LBA 0 到 0:7C00
  │ （在我们的 case 中就是 obj/boot/boot 文件的内容）
  │
  ▼
boot.S 开始执行（在 0:7C00，16 位实模式）
  │
  │ ① CLD, CLI, 清段寄存器
  │ ② 读取 8042 状态 → 写入 A20 使能命令
  │    （等待 Input Buffer 空闲 → 写 0xD1 → 等待空闲 → 写 0xDF）
  │ ③ LGDT 加载 GDT（3 个描述符：空/代码/数据）
  │ ④ MOV CR0 → OR 1 → MOV CR0（PE=1）
  │ ⑤ LJMP 0x8:protcseg（刷新 CS，进入 32 位模式）
  │
  ▼
boot.S（已在 32 位保护模式）
  │
  │ ⑥ MOV DS=ES=FS=GS=SS=0x10（扁平模型，基址 0，限长 4GB）
  │ ⑦ MOV ESP=0x7C00（栈向下生长）
  │ ⑧ CALL bootmain（跳转到 C 代码）
  │
  ▼
main.c (bootmain) 开始执行
  │
  │ ⑨ waitdisk() → 等磁盘就绪
  │ ⑩ 设置 IDE 控制器端口：
  │    0x1F2=1, 0x1F3=0x01, 0x1F4=0, 0x1F5=0,
  │    0x1F6=0xE0, 0x1F7=0x20
  │    等待磁盘 → INSL 读 128 次 dword 到 0x10000
  │    重复 8 次（读 8 个扇区）
  │
  │ ⑪ 检查 0x10000 的前 4 字节 == 0x464C457F ("\x7FELF")
  │    如果不等 → 显示错误码到 0x8A00 → 死循环
  │
  │ ⑫ 解析 ELF 头：
  │    e_phoff = Program Header 表偏移
  │    e_phnum = 段数量
  │    遍历：
  │      for ph = ELFHDR + e_phoff; ph < e_phoff + e_phnum; ph++
  │          readseg(ph->p_pa, ph->p_memsz, ph->p_offset)
  │          将内核从硬盘读到指定物理地址
  │
  │ ⑬ ((void(*)())ELFHDR->e_entry)()

  ▼
JOS 内核入口 (kern/entry.S)
  │
  │ 加载 CR3 页目录 → 开启分页
  │ 设置新的栈 → 跳转到 i386_init()
  │
  ▼
i386_init() → 控制台初始化 → 内存检测 → ……
  │
  ▼
  最终显示: "Welcome to the JOS kernel monitor!"
            "Type 'help' for a list of commands."
```

### 对比 MS-DOS 启动链

```
MS-DOS:
  BIOS → MBR → VBR → IO.SYS → MSDOS.SYS → COMMAND.COM
  4 次控制权转移，涉及分区表、FAT 文件系统

MIT 6.828:
  BIOS → boot.S → main.c → KERNEL
  1 次汇编到 C、1 次控制权转移，不涉及任何文件系统或分区表
```

MIT 的路径**短得多**，因为它的设计目标不是兼容性，而是简单和可理解。

---

## 6. 总结表格

### 文件清单

| 文件 | 编译产物 | 用途 | 工具链 |
|------|---------|------|-------|
| `boot/boot.S` | `obj/boot/boot.o` | CPU 初始化（A20, GDT, 保护模式） | `i386-jos-elf-gcc -c` |
| `boot/main.c` | `obj/boot/main.o` | 磁盘 I/O + ELF 加载 | `i386-jos-elf-gcc -Os -c` |
| `boot/Makefrag` | — | 构建规则 | `make` |
| `boot/sign.pl` | — | 填充零 + 55AA 签名 | `perl` |
| `inc/mmu.h` | — | GDT 宏、CR0 标志 | — |
| `inc/x86.h` | — | port I/O 内联函数 | — |
| `inc/elf.h` | — | ELF 结构体定义 | — |

### 与 MS-DOS 全览对比

| 维度 | MS-DOS MBR + VBR | MIT 6.828 bootloader |
|------|-----------------|---------------------|
| **文件数** | 5+（FDBOOT.ASM, BOOTREC.ASM, MSBOOT.ASM, BOOT.SKL, USA-MS.MSG） | **6**（boot.S, main.c, inc/*.h, sign.pl, Makefrag, GNUmakefile） |
| **代码行数** | ~560 行（MBR ~80 + VBR ~480） | **~130 行**（boot.S 43 + main.c 87） |
| **语言** | 纯 16 位 8086 汇编 | **16→32 位汇编 + C** |
| **编译器** | MASM 5.x | GCC 交叉编译（`i386-jos-elf-`） |
| **编译产物** | `.BIN` → DBOF → `.INC` → 嵌入 FDISK/FORMAT | **`obj/boot/boot`**（独立二进制） |
| **签名方式** | 汇编中 `ORG` + `DB` 预留 | **Perl 脚本** `sign.pl` 后处理 |
| **磁盘接口** | INT 13h (BIOS) | **IDE 端口 I/O** (0x1F0-0x1F7) |
| **扇区寻址** | CHS（MBR）+ LBA（VBR） | **LBA** |
| **下一级加载** | 分区表 → Active → VBR / 文件名 → IO.SYS | **固定扇区 1+ → ELF → e_entry** |
| **多系统支持** | 是（4 分区，任意 OS） | **否**（仅 JOS） |
| **文件系统** | 必须理解 FAT（VBR） | **不感知** |
| **保护模式** | 否（全程实模式） | **是**（boot.S 内切换） |
| **内存占用** | 0x600-0x7FF (MBR) + 0x7C00 (VBR) + 0x500 (目录) + 0x700 (IO.SYS) | **0x7C00-0x7D7B** (~380B 代码) + 0x10000 (ELF 暂存) |
| **错误处理** | 显示错误消息 + 等待按键 | **死循环**（QEMU 端口 0x8A00 输出错误码） |

### 核心设计思想

1. **boot.S 只做"硬件初始化"**——不做磁盘 I/O，不做内核加载，只负责把 CPU
   从实模式带到保护模式并准备好 C 执行环境。职责单一。

2. **main.c 只做"加载内核"**——通过直接操作 IDE 控制器端口扇区到内存，
   然后按 ELF 格式解析段、复制数据、跳转入口。不做分区、不做文件系统。

3. **教学优先于工业兼容性**——不使用 INT 13h（让学生看到磁盘控制器的真实面貌）、
   不使用分区表（免得学生还要了解分区格式）、不使用文件系统（ELF 内核直接裸放
   在扇区 1+）。代价是：这样生成的引导扇区只能在 QEMU 或专用实验环境使用。

4. **编译链用 GNU 工具链替换了 MASM + LINK + EXE2BIN**——`gcc` 替代 `MASM`，
   `ld` 替代 `LINK`，`objcopy -O binary` 替代 `EXE2BIN`。功能一一对应，
   但都是开源软件，跨平台可用。
