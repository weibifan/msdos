# MS-DOS 4.0 MBR 与 Boot Sector 编译与构建

本文讲解 `ms-dos-mbr-boot-sector/` 中所有源码是**如何被编译、链接、转换，
最终变成磁盘上两个 512 字节引导代码**的：

| 引导代码 | 编译产物 | 写入位置 | 写入工具 | 作用 |
|---------|---------|---------|---------|------|
| **MBR**（主引导记录） | `FDBOOT.BIN` | 磁盘 LBA 0 | FDISK | 定位 Active 分区，加载其 VBR |
| **VBR / Boot Sector**（卷引导记录） | `MSBOOT.BIN` | 分区 LBA 0 | FORMAT | 解析 BPB 和 FAT，加载 IO.SYS |

---

## 0. 五句话扫清背景知识

### 问题一：什么是 MBR？什么是 VBR（Boot Sector）？

把磁盘想象成一栋公寓楼：

- **MBR（主引导记录）** = 大楼一层的**门牌指引板**（LBA 0，第 1 个扇区）。
  它上面写着："102 室住着 Windows，202 室住着 Linux"。
  它的工作就是：找到标记了"可启动"的那个房间号，然后敲那个房间的门。
  MBR 不关心房间里面住了谁、怎么开门——它只管**敲门**。

- **VBR（卷引导记录 / Boot Sector）** = 每个房间门上贴的**开锁说明**。
  它知道这个房间的锁型号（文件系统类型），知道钥匙放在哪（FAT 表位置），
  知道进门后先迈左脚还是右脚（如何加载 `IO.SYS`）。

所以：**MBR 引导你找到分区，VBR 引导你进入分区**。

### 问题二：MBR 和 VBR 各有多大？

都是 **512 字节**。其中：

| | 引导代码 | 数据区 |
|---|---------|-------|
| MBR | 前 446 字节 | 偏移 0x1BE 起的 64 字节分区表 + 末尾 2 字节 55AA |
| VBR | 前 3~90 字节不等 | 偏移 0x0B 起的 BPB + 末尾 2 字节 55AA |

### 问题三：谁写 MBR？谁写 VBR？

- **MBR 由 FDISK 写入**（用户分区时自动写盘）
- **VBR 由 FORMAT 写入**（用户格式化分区时自动写盘）

### 问题四：我们的代码仓库里有什么？

```
MBR/                     ← FDISK 工具的一部分（负责生成 MBR）
  ├── FDBOOT.ASM         ← MBR 的引导代码（汇编，446 字节逻辑）
  └── BOOTREC.ASM        ← 包装器——把 MBR 代码打包成 C 数组

BOOT/                    ← FORMAT 工具的一部分（负责生成 VBR）
  ├── MSBOOT.ASM         ← VBR 的引导代码（汇编，512 字节）
  └── BOOT.SKL           ← 错误消息的"模板"
```

### 问题五：核心矛盾——汇编代码怎么塞进 C 程序？

FDISK 本身是 C 程序，但 MBR 引导代码是汇编写的。
C 程序没法直接"执行"汇编源代码——它需要把汇编编译后的**机器码**当做一段
**数据**来使用，就像你往信封里塞一张纸条一样。

这正是 `BOOTREC.ASM` 存在的理由：它把 `FDBOOT.ASM` 编译出来的机器码
**变成 C 可以操作的数组**，这样 FDISK 可以在数组里修改分区表，
然后通过 `INT 13h` 把整个数组写到磁盘。

---

## 1. MBR 编译链全解析

### 1.1 我们要干什么？

我们的最终目标是：生成一个叫 `FDISK.EXE` 的程序。
这个程序运行时，可以修改硬盘的 MBR。

但 `FDISK.EXE` 需要用 C 写界面、处理用户输入、计算分区大小，
而 **MBR 引导代码必须用汇编写**（C 编译出来的代码太大，放不进 446 字节）。

所以策略就是：

```
用汇编写好 MBR 模板（FDBOOT.ASM）
  → 编译成机器码（FDBOOT.BIN）
  → 塞进 C 程序里（通过 BOOTREC.ASM 转成数组）
  → C 程序运行时修改数组中的分区表部分
  → 把数组写入磁盘 LBA 0
```

### 1.2 第一步：汇编源代码 → 裸二进制

```
FDBOOT.ASM ──MASM──→ FDBOOT.OBJ ──LINK──→ FDBOOT.EXE ──EXE2BIN──→ FDBOOT.BIN
```

**类比**：你写了一封信（FDBOOT.ASM）：
- **MASM** = 手写稿转成打印稿（`.ASM` → `.OBJ`，目标文件格式，还不是可执行文件）
- **LINK** = 把打印稿装进信封，写上收发地址（`.OBJ` → `.EXE`，DOS MZ 格式，
  带 512 字节文件头）
- **EXE2BIN** = 把信从信封里**抽出来**，扔掉信封（`.EXE` → `.BIN`，纯裸二进制）

**为什么需要这三步？**

这个问题很好：**为什么 MASM 不能直接生成 `.BIN`？**

答案：MASM 在 1980 年代受限于 OMF 目标文件格式（Object Module Format）。
这个格式包含**重定位信息**——比如代码里写了 `ORG 600h`，但实际加载地址是
`0x7C00`，MASM 生成的 `.OBJ` 里记录了这些"待修复的地址"。
**LINK 负责解析所有段定义和符号，修复这些地址**，生成完整的可执行文件。
然后 **EXE2BIN 再把头部剥掉**，留下纯机器码。

```
MASM 输出 .OBJ（半成品，含重定位信息）
  → 必须 LINK（修复地址，产出完整 EXE）
  → 必须 EXE2BIN（剥掉 EXE 头，得到裸二进制）
```

**少了任何一步都不行**：不用 LINK，地址不对；不用 EXE2BIN，512 字节里
有 256 字节是文件头，代码不全。

### 1.3 第二步：裸二进制 → 汇编数据文件

```
FDBOOT.BIN ──DBOF──→ FDBOOT.INC
```

`FDBOOT.BIN` 是 512 字节的原始机器码。但我们怎么把它塞进 C 程序呢？

一种方法是：把 `FDBOOT.BIN` 以二进制资源的形式编译进 C 程序。
但在 1980 年代的 DOS 编译器里，没有标准的"二进制资源"机制。

于是 MS-DOS 团队做了一个叫 **DBOF** 的工具。
它的作用很简单：**把二进制文件转换成汇编 DB（Define Byte）伪指令**。

**类比**：DBOF 就像一个"二进制→文本"转换器。

输入 `FDBOOT.BIN`（不可读的二进制）：

```
EB 48 90 4D 53 44 4F 53 ...
```

输出 `FDBOOT.INC`（可被 MASM 包含的文本）：

```asm
db 0EBh, 048h, 090h, 04Dh, 053h, 044h, 04Fh, 053h, ...
```

这个过程**完全可逆**。`FDBOOT.INC` 被 MASM 编译后，得到的机器码和
`FDBOOT.BIN` 一模一样。

### 1.4 第三步：数据文件 → C 数组

```
FDBOOT.INC
      │
      ▼ include （两次）
BOOTREC.ASM ──MASM──→ BOOTREC.OBJ
```

这就是 `BOOTREC.ASM` 的作用。让我们看它的全部源码：

```asm
; BOOTREC.ASM 的完整内容
PUBLIC  _master_boot_record
_master_boot_record label byte

include fdboot.inc        ; ← 这 512 字节是 MBR 引导代码 + 空白分区表
include fdboot.inc        ; ← 再来 512 字节
```

**它只做了两件事：**

1. **定义一个标签 `_master_boot_record`**：
   - `PUBLIC` 让 C 代码可以看到这个标签
   - 标签名前的下划线是 C 编译器约定的命名规则（C 的 `master_boot_record`
     在汇编层叫 `_master_boot_record`）

2. **把 MBR 机器码作为数据嵌入**：
   - `include fdboot.inc` 把 512 字节的机器码变成汇编中的 DB 语句
   - 连续 `include` 两次，得到 **1024 字节**：两个 MBR 副本

**被 include 两次的玄机**：

为什么是两次？因为 `master_boot_record[2][512]` 声明为 2×512 的二维数组。
为什么需要两个副本？因为 FDISK 在修改分区表时，可能需要保留一个原始备份
用于比较或恢复（类似"撤销"功能），或者为了同时管理两个磁盘的分区信息。

**BOOTREC.ASM 的结果**：

MASM 编译 `BOOTREC.ASM` 后，`BOOTREC.OBJ` 中包含了一段数据：
```
地址         内容
0000         [FDBOOT.BIN 前 512 字节]  ← master_boot_record[0]
0200         [FDBOOT.BIN 后 512 字节]  ← master_boot_record[1]
```

而 `_master_boot_record` 标签指向这 1024 字节的开头。

### 1.5 第四步：链接进 FDISK.EXE

```
BOOTREC.OBJ + FDISK.C 编译出的所有 .OBJ 文件
      │
      ▼ LINK
  FDISK.EXE
```

**类比**：FDISK.EXE 是一个工具箱，`BOOTREC.OBJ` 是工具箱里一个写着
"MBR 模板"的抽屉。当 FDISK 运行时：

1. 用户选择"创建分区"
2. C 代码计算分区起始位置、大小、类型
3. C 代码**直接修改 `master_boot_record[0]` 数组**中偏移 `0x1BE` 处的
   16 字节分区表项
4. 用户选择"写入"
5. C 代码调用 `write_boot_record()` → `INT 13h AH=03h`
   → 把 `master_boot_record[0]` 的 512 字节写到磁盘 LBA 0

### 1.6 关键图示：MBR 512 字节的布局

```
偏移 0x000 ┌─────────────────────────────┐
            │                             │
            │  引导代码（446 字节）         │ ← FDBOOT.ASM 的汇编代码
            │  包括：                       │
            │    自拷贝 0:7C00 → 0:0600    │
            │    扫描 Active 分区          │
            │    读 VBR 到 0:7C00          │
            │    验证 55AA 签名            │
            │    跳转到 VBR               │
            │                             │
偏移 0x1BE ├─────────────────────────────┤
            │  分区表项 1 （16 字节）       │
偏移 0x1CE  │  分区表项 2 （16 字节）       │ ← 编译时全零
偏移 0x1DE  │  分区表项 3 （16 字节）       │ ← FDISK 运行时填充
偏移 0x1EE  │  分区表项 4 （16 字节）       │
偏移 0x1FE ├─────────────────────────────┤
            │  55 AA（2 字节，启动标记）    │
偏移 0x1FF └─────────────────────────────┘
```

`FDBOOT.BIN` 的原始内容包含**全部 512 字节**——包括全零的分区表区域。
当 `FDBOOT.ASM` 编译时，`ORG 7BEh` 之后的分区表占位区域就是零零零。
这些零被完整保留到 `FDBOOT.BIN`，再经由 `FDBOOT.INC` 进入 `BOOTREC.OBJ`，
最终进入 `FDISK.EXE` 的内存。

**FDBOOT.ASM 的分区表全是占位零，FDISK 在内存中才填上真正的值。**

---

## 2. VBR (Boot Sector) 编译链全解析

### 2.1 我们要干什么？

VBR（即 `MSBOOT.ASM`）是一个 **独立的引导程序**，它被 FORMAT 工具写入
**分区的第一个扇区**。当 MBR 找到 Active 分区后，把 VBR 加载到 `0x7C00`，
VBR 负责：

1. 解析 BPB（了解磁盘的扇区大小、FAT 数量、根目录大小等）
2. 计算目录区和数据区的位置
3. 读根目录，找 `IO.SYS`
4. 加载 `IO.SYS` 到内存
5. 跳转执行

### 2.2 编译链

```
MSBOOT.ASM ──MASM──→ MSBOOT.OBJ ──LINK──→ MSBOOT.EXE ──EXE2BIN──→ MSBOOT.BIN
```

这和 MBR 的 `FDBOOT.ASM → FDBOOT.BIN` 完全相同：
- **MASM** 编译汇编为目标文件
- **LINK** 链接为 DOS EXE
- **EXE2BIN** 剥离头部，得到 512 字节裸二进制

### 2.3 为什么 VBR 编译比 MBR 多了一步消息处理？

VBR 需要在屏幕上显示错误信息，比如：

> Non-System disk or disk error
> Replace and press any key when ready

但 512 字节的空间极其珍贵，不可能在每个国家/语言的版本中都硬编码消息字符串。
MS-DOS 4.0 支持多语言，所以设计了一个**消息编译系统**：

```
BOOT.SKL ← 消息"骨架"（只声明需要什么消息，不写具体文字）
  │
  ▼
MSG.EXE（消息编译器）←── USA-MS.MSG（具体文字，每种语言一个文件）
  │
  ▼
boot.cl1（编译后的消息数据，汇编 INCLUDE 文件）
  │
  ▼
MSBOOT.ASM ──include boot.cl1──→ 得到消息字符串的汇编标签
```

**类比**：这就像现代软件的国际化（i18n）：

- `BOOT.SKL` = 一个声明："我需要一条编号为 001 的错误消息"
- `USA-MS.MSG` = 英语词典："001 = Non-System disk..."
- `GERMAN.MSG` = 德语词典："001 = Keine Systemdisk..."
- `boot.cl1` = 从词典中查到的具体文字，变成汇编代码

编译时通过 `COUNTRY` 环境变量选择用哪本词典。

### 2.4 BOOT.SKL 和 USA-MS.MSG 怎么合作？

`BOOT.SKL` 全部内容：

```asm
:class 1
:use 001 BOOT SYSMSG
:end
```

翻译成大白话：

> 我要创建消息类别 1（class 1）。
> 从类别 BOOT 中取出消息编号 001，在汇编中给它起名叫 `SYSMSG`。

`USA-MS.MSG` 中的对应条目：

```
BOOT     58c1 0001
0001 U 0000 13,10,"Non-System disk or disk error",13,10
    "Replace and press any key when ready",13,10,0
```

翻译：

> 模块 BOOT，起始位置 58c1，长度 0001。
> 消息 0001：换行 + "Non-System disk..." + 换行 + "Replace..." + 换行 + 结束

MSG.EXE 读取两者后，生成 `boot.cl1`，内容大致等价于：

```asm
SYSMSG label byte
db 13,10,"Non-System disk or disk error",13,10
db "Replace and press any key when ready",13,10,0
```

然后在 `MSBOOT.ASM` 中：

```asm
include boot.cl1           ; ← SYSMSG 标签在此定义

; 遇到错误时：
CKERR:
    MOV  SI, OFFSET SYSMSG ; SI 指向消息字符串
    CALL WRITE             ; 调用显示函数
```

### 2.5 VBR 的完整编译过程

所以 VBR 的完整编译链是：

```
BOOT.SKL ──┐
           ├── MSG.EXE ──→ boot.cl1
USA-MS.MSG─┘                  │
                              ▼
                        MSBOOT.ASM
                              │
                         include boot.cl1
                         include version.inc
                              │
                         MASM → MSBOOT.OBJ
                              │
                         LINK → MSBOOT.EXE
                              │
                         EXE2BIN → MSBOOT.BIN
```

`MSBOOT.BIN` 就是最终写入分区 LBA 0 的 512 字节引导扇区。

---

## 3. 编译时的"双面人"——同一个汇编源码被编译两次

### 3.1 FDBOOT.ASM（MBR）的双面人生

这是整个构建体系最核心的设计模式。同样的 `.ASM` 文件，被编译成两份完全不同的产品：

**第一次编译：作为"可执行程序"**

目标：产出 MBR 的裸二进制镜像。

```
FDBOOT.ASM → MASM → FDBOOT.OBJ → LINK → FDBOOT.EXE → EXE2BIN → FDBOOT.BIN
                                                                        ↓
                                                                DBOF → FDBOOT.INC
                                                                        ↓
                                                                512 字节 DB 伪指令
```

`FDBOOT.BIN` 是完整的 512 字节 MBR（前 446 字节代码 + 后 66 字节零分区表 + 55AA）。
剥离 EXE 头后，它就是一块"原始磁盘扇区"——`dd` 到 LBA 0 就能用（只是分区表是空的）。

**第二次编译：作为"数据数组"**

目标：把 MBR 代码**当做数据嵌入 FDISK.EXE**，让 C 代码能在内存中修改它。

```
FDBOOT.INC（DB 伪指令形式的 MBR 代码）
      │
BOOTREC.ASM ──include fdboot.inc──→ BOOTREC.OBJ
      │
      链接到 FDISK.EXE
```

`FDBOOT.INC` 里的 `db 0EBh, 048h, ...` 被 MASM 编译后，还原成和 `FDBOOT.BIN`
一模一样的机器码。但它现在是一个 C 数组 `_master_boot_record[]`，FDISK 可以
在内存中修改它的分区表区域，再写盘。

**类比**：

- 第一次 = 汽车制造商造了一辆展车（`FDBOOT.BIN`，直接可用）
- 第二次 = 把展车的设计图塞进工厂的机器人程序（`BOOTREC.OBJ` 嵌入 FDISK），
  机器人根据客户需求微调内饰（FDISK 修改分区表），再生产（写盘）

### 3.2 MSBOOT.ASM（VBR）同样被编译两次

完全相同的模式，只是角色换成了 FORMAT：

**第一次编译：VBR 裸二进制**

```
MSBOOT.ASM → MASM → LINK → EXE2BIN → MSBOOT.BIN
                                               │
                                         DBOF → BOOT.INC
                                               │
                                        复制到 INC/BOOT.INC（全局共享）
```

`MSBOOT.BIN` 就是完整的 512 字节 VBR，`dd` 到分区 LBA 0 就能用。

**第二次编译：作为数据嵌入 FORMAT.EXE**

FORMAT 的源码 `MSFOR.ASM` 中：

```asm
INCLUDE BOOTFORM.INC     ; ← 定义 BPB 结构体（如 EXT_BPB_INFO STRUC）

BOOT    LABEL BYTE       ; ← 定义一个标签叫 BOOT，指向 VBR 数据开头
    INCLUDE BOOT.INC     ; ← 嵌入 512 字节 VBR 机器码（DB 语句）
```

看懂这两行的意思：

- `BOOT LABEL BYTE`：在汇编中声明一个地址标签 `BOOT`，类型是字节
- `INCLUDE BOOT.INC`：把 `MSBOOT.BIN` 转成的 DB 语句展开在这里

编译后，`BOOT` 标签指向内存中一段 512 字节的数据——就是 VBR 的机器码。
FORMAT 通过结构体偏移来访问这个数据块中的特定字段：

```asm
; WriteBootSector 过程（MSFOR.ASM）中：
; 复制 BPB 到 VBR 数据的偏移 0x0B 处
lea  si, deviceParameters.DP_BPB    ; 源：计算好的 BPB 参数
lea  di, Boot.EXT_BOOT_BPB          ; 目标：VBR 数据中的 BPB 位置
mov  cx, size EXT_BPB_INFO
repnz movsb                         ; 拷贝 BPB 到 VBR 模板中

; 把填充好的 VBR 写入磁盘
mov  al, drive          ; 驱动器号
mov  cx, 1              ; 1 个扇区
xor  dx, dx             ; 逻辑扇区 0（分区开头）
lea  bx, boot           ; BX = VBR 数据地址
call Write_Disk         ; INT 26h 写盘
```

**把 FORMAT 和 FDISK 并排对比**，模式完全对称：

```
                  MBR 路径                           VBR 路径
               ──────────                         ──────────
源码           FDBOOT.ASM                         MSBOOT.ASM
预编译         FDBOOT.ASM → FDBOOT.BIN            MSBOOT.ASM → MSBOOT.BIN
转 DB 格式     DBOF → FDBOOT.INC                   DBOF → BOOT.INC
包装层         BOOTREC.ASM (include fdboot.inc)    MSFOR.ASM (include BOOT.INC)
嵌入目标       FDISK.EXE                           FORMAT.EXE
运行时修改     分区表项（偏移 0x1BE）                BPB（偏移 0x0B）
写入位置       磁盘 LBA 0                         分区 LBA 0
```

### 3.3 为什么要用"编译两次"这种绕弯子的做法？

如果你今天写代码，会把引导代码单独编译成一个 `.BIN`，然后用 `xxd -i` 转成 C 头文件，
或者直接用 `objcopy` 输出二进制 blob。但在 1980 年代的 MS-DOS 工具链里：

1. **C 编译器不支持嵌入二进制资源**——没有 `#embed`，没有资源文件
2. **MASM 支持 INCLUDE**——但只能 include 汇编源码，不能 include 二进制
3. **DBOF 桥接了这个问题**——它把二进制转成汇编能理解的 DB 语句
4. **包装层（BOOTREC.ASM）再桥接 C 和汇编**——通过 `PUBLIC` 导出符号，
   让 C 的 `extern` 声明能找到这个数据块

所以"编译两次"不是设计者的偏好，而是 1980 年代工具链限制下的**必然选择**。

---

## 4. 运行时：FDISK 和 FORMAT 分别在做什么？

### 4.1 FDISK 的运行时流程

```
FDISK.EXE 启动
  │
  ├─ read_boot_record(LBA 0) → master_boot_record[0]
  │   读取现有 MBR，看看当前分区表长什么样
  │
  ├─ 主菜单
  │   1. 创建 DOS 分区
  │   2. 设置 Active 分区
  │   3. 删除分区
  │   4. 显示分区信息
  │
  ├─ 用户选择"创建主分区"
  │   ├─ 计算起始 CHS/LBA 地址（如 LBA 63, CHS 0/1/1）
  │   ├─ 计算分区大小（如 200MB = 409600 扇区）
  │   ├─ 确定分区类型（FAT16 = 06h）
  │   └─ 填充 master_boot_record[0] 偏移 0x1BE（第 1 个分区表项）
  │        字节 0: 0x80（标记为 Active）
  │        字节 1: 磁头号
  │        字节 2-3: 扇区/柱面
  │        字节 4: 0x06（FAT16）
  │        字节 5-7: CHS 结束
  │        字节 8-11: LBA 起始地址
  │        字节 12-15: 总扇区数
  │
  ├─ 用户选择"退出时写入"
  │   └─ write_boot_record(0, 0x80)
  │        → INT 13h AH=03h, CHS=0/0/1
  │        → 将 master_boot_record[0] 的 512 字节写入磁盘 LBA 0
  │
  └─ MBR 写入完成
```

### 4.2 FORMAT 的运行时流程

FORMAT 和 FDISK 是一对"搭档"：FDISK 创建分区、写入 MBR；
FORMAT 格式化分区、写入 VBR。

```
用户操作                            FORMAT 内部
──────                              ─────────────
                                    FORMAT.EXE 启动
                                      │
                                      ├─ 解析命令行参数
                                      │   如 FORMAT C: /S /V /F:1.44
                                      │   /S = 传输系统文件
                                      │   /V = 提示输入卷标
                                      │   /F:1.44 = 指定容量
                                      │
                                      ├─ 打开驱动器（INT 21h）
                                      │   通过 IOCTL 获取设备参数
                                      │   → 填充 deviceParameters 结构体
                                      │   （包括磁头数、柱面数、每道扇区数等）
                                      │
                                      ├─ CheckSwitches()
                                      │   验证开关组合的合法性
                                      │   如 /1 和 /8 不能与 /T /N 混用
                                      │   根据 /F: 值设定 TrackCnt、NumSectors
                                      │
                                      ├─ 确定分区类型
                                      │   根据容量确定 BPB：
                                      │     360KB → BPB81 / BPB82
                                      │     720KB → BPB720
                                      │     1.2MB → BPB91 / BPB92
                                      │     硬盘  → 从分区表读取
                                      │   计算 SectorsPerFAT
                                      │
                                      ├─ 交互式确认
                                      │   "Insert new diskette for drive C:"
                                      │   "Press any key to continue..."
                                      │
                                      ├─ ═══ 核心：WriteBootSector() ═══
                                      │   │
                                      │   │  这是写入 VBR 的关键函数。
                                      │   │  MSFOR.ASM 中 ~50 行代码。
                                      │   │
                                      │   │  步骤：
                                      │   │
                                      │   ├── 1. 构造 BPB 数据
                                      │   │     来自 deviceParameters.DP_BPB
                                      │   │     包含 ByteSec, SectorsPerCluster,
                                      │   │     ReservedSectors, NumberOfFATs,
                                      │   │     RootEntries, TotalSectors, MediaDesc,
                                      │   │     SectorsPerFAT, SectorsPerTrack,
                                      │   │     Heads, HiddenSector, BigTotalSectors
                                      │   │
                                      │   ├── 2. 拷贝 BPB 到 VBR 模板
                                      │   │     lea  si, deviceParameters.DP_BPB
                                      │   │     lea  di, Boot.EXT_BOOT_BPB
                                      │   │     mov  cx, size EXT_BPB_INFO
                                      │   │     repnz movsb
                                      │   │     ↑
                                      │   │     Boot 是 INCLUDE BOOT.INC 嵌入的
                                      │   │     512 字节 VBR 机器码，编译时确定地址。
                                      │   │     Boot.EXT_BOOT_BPB 对应偏移 0x0B。
                                      │   │
                                      │   ├── 3. 写盘（INT 26h）
                                      │   │     mov  al, drive   ; C: = 2
                                      │   │     mov  cx, 1       ; 1 扇区
                                      │   │     xor  dx, dx      ; 逻辑扇区 0
                                      │   │     lea  bx, boot    ; VBR 数据地址
                                      │   │     call Write_Disk  ; INT 26h 写盘
                                      │   │
                                      │   ├── 4. 设置 Media ID
                                      │   │     调用 Create_Serial_ID()
                                      │   │     用当前日期+时间生成 32 位序列号
                                      │   │     写 FAT12/FAT16 字符串
                                      │   │     调用 IOCTL Set_Media_ID
                                      │   │
                                      │   └── 结果：分区 LBA 0 已写入 VBR
                                      │
                                      ├─ 初始化 FAT 表
                                      │   FAT#1 和 FAT#2 写 0xF6（标记为已用）
                                      │   这是为了在后续扫描坏道时标记已占用簇
                                      │
                                      ├─ 扫描并标记坏道
                                      │   verify_tracks() 逐道写入并回读
                                      │   发现坏道 → 标记在 FAT 中
                                      │
                                      ├─ 初始化根目录
                                      │   全部清空为 0
                                      │   如果 /V，提示输入卷标并写入第一个目录项
                                      │
                                      ├─ OemDone()
                                      │   │
                                      │   ├── 如果 /S：传输系统文件
                                      │   │   复制 IO.SYS 和 MSDOS.SYS
                                      │   │   到数据区的前几个簇
                                      │   │   确保 VBR 能找到它们
                                      │   │
                                      │   ├── 如果 /B（软盘）：
                                      │   │   写入假的 DOS 文件占位
                                      │   │
                                      │   └── 如果硬盘：
                                      │       SetPartitionTable()
                                      │       读取 MBR，找到 DOS 分区表项
                                      │       确定分区类型字节（01h/04h/06h）
                                      │       写回 MBR
                                      │       ↑
                                      │       这是 FORMAT 间接写回 MBR 的唯一情况！
                                      │       FORMAT 通过 SetPartitionTable 更新
                                      │       分区类型（如 FAT12→01h, FAT16→06h）
                                      │
                                      ├─ 报表
                                      │   "xxx bytes total disk space"
                                      │   "xxx bytes used by system"
                                      │   "xxx bytes available on disk"
                                      │   "Volume Serial Number is xxxx-xxxx"
                                      │
                                      └─ 询问是否格式化其他磁盘
                                          "Format another (Y/N)?"
```

**核心差异：FDISK 和 FORMAT 写入什么？**

| | FDISK 写 | FORMAT 写 |
|---|---|---|
| 目标 | 磁盘 LBA 0（MBR） | 分区 LBA 0（VBR） |
| 数据来源 | `master_boot_record[0]` | `BOOT` 标签（INCLUDE BOOT.INC） |
| 修改的区域 | 偏移 0x1BE 分区表 | 偏移 0x0B BPB |
| 写盘方式 | INT 13h AH=03h | INT 26h（DOS 绝对写） |
| 是否理解文件系统 | 不理解 | 必须理解（计算 FAT 大小等） |
| 额外操作 | 无 | 初始化 FAT、根目录、复制系统文件 |

**FORMAT 写盘时使用的是 INT 26h（DOS 绝对写），而 FDISK 使用 INT 13h（BIOS 磁盘服务）。**
这反映了它们不同的"视角"：FDISK 工作在磁盘层面（不知道 DOS 是否存在），
FORMAT 工作在 DOS 层面（已经运行在 DOS 环境下，用 DOS 的文件系统调用）。

---

## 5. 启动时的完整接力

```
BIOS 加电
  │
  │ INT 19h → 读 LBA 0 到 0:7C00
  │
  ▼
MBR（FDBOOT 代码，位于 0:7C00→自拷贝到 0:0600）
  │
  │ 扫描 4 个分区表项，找 Active 标志（0x80）
  │
  ├─ 没找到 → 显示错误消息 → INT 18h（ROM BASIC）
  │
  ├─ 找到 → 从该分区表项取出 CHS 地址
  │
  │  INT 13h AH=02h → 读分区 LBA 0 到 0:7C00
  │
  │  检查 55AA 签名
  │
  ▼
VBR（MSBOOT 代码，位于 0:7C00）
  │
  │ 解析 BPB，计算 FAT 位置、根目录位置、数据区位置
  │
  │ 读根目录第一个扇区到 0:500
  │
  │ 对比前 11 字节是否为 "IO     SYS"（MS 版）或 "IBMBIO COM"（IBM 版）
  │
  ├─ 没找到 → 显示 "Non-System disk or disk error" → 等按键 → 重启
  │
  ├─ 找到 → 计算 IO.SYS 在数据区的起始扇区
  │
  │  读 3 个扇区到 0:0700（ES=0070, BX=0700 = 物理 0:0700）
  │
  │  设置 CH = MEDIA, DL = PHYDRV, BX = 数据区起始扇区, AX = 高字
  │
  ▼
IO.SYS（位于 0070:0700）
  │
  │ 初始化中断向量表
  │ 初始化设备驱动（CON, AUX, PRN, 块设备）
  │ 调用 DOS API 初始化
  │ 读取 CONFIG.SYS
  │ 加载 COMMAND.COM
  │
  ▼
C:\>
```

---

## 6. 总结表格

| 文件 | 编译产物 | 写入工具 | 写入位置 | 运行时角色 |
|------|---------|---------|---------|-----------|
| `MBR/FDBOOT.ASM` | `FDBOOT.BIN` | FDISK | 磁盘 LBA 0 | 找 Active 分区，加载 VBR |
| `MBR/BOOTREC.ASM` | `BOOTREC.OBJ` | 不写入 | FDISK 内嵌 | 将 MBR 模板暴露为 C 数组 |
| `BOOT/MSBOOT.ASM` | `MSBOOT.BIN` | FORMAT | 分区 LBA 0 | 解析 BPB，加载 IO.SYS |
| `BOOT/BOOT.SKL` | `boot.cl1` | 不写入 | 编译器输入 | 消息骨架 |

**核心设计思想**：

1. **MBR 代码不感知文件系统**——它只做最简单的"读扇区"操作
2. **VBR 代码理解文件系统**——它必须知道 FAT 的布局才能找到 `IO.SYS`
3. **汇编代码通过"编译为数据"的方式嵌入 C 程序**——这是 1980 年代没有
   标准资源管理系统下的巧妙 hack
4. **消息文字独立于引导代码**——通过骨架+消息文件的机制实现多语言
