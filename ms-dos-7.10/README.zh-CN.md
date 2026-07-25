<p align="center">
  <a href="README.md"><img alt="English" height="30" src="https://img.shields.io/badge/English-3593D2?style=for-the-badge"></a>&nbsp;
  <a href="README.zh-CN.md"><img alt="简体中文" height="30" src="https://img.shields.io/badge/简体中文-7CB342?style=for-the-badge"></a>
</p>

# MS-DOS 7.10

The final version of MS-DOS, released as part of Windows 98 Second Edition (1998). Supports FAT32 and large disk drives.

| File | Description |
|------|-------------|
| `ms-dos-71-disk1.zip` | MS-DOS 7.1 Installation Disk 1 — setup files and core system. |
| `ms-dos-71-disk2.zip` | MS-DOS 7.1 Installation Disk 2 — additional utilities and drivers. |
| `ms-dos-71-boot.zip` | MS-DOS 7.1 Boot Disk — bootable floppy disk image for starting the system. |
| `ms-dos-71-boot-bd.zip` | MS-DOS 7.1 Boot Disk — bootable floppy disk image with more tools. |

1. 关于 MS-DOS 7.10 的本质
MS-DOS 7.10 并非微软官方独立发行的零售版本，而是 Windows 98 SE（及 Windows 95 OSR2）内核中包含的 DOS 组件。由于 Windows 9x 启动时会先加载 DOS 7.x 内核，爱好者通过提取这些系统文件（IO.SYS, MSDOS.SYS, COMMAND.COM）并配合外部命令，将其封装为可独立安装的系统。

技术优势：相比 MS-DOS 6.22，7.10 原生支持 FAT32 文件系统，突破了 2GB 分区限制，并能更好地管理大内存（通过 HIMEM.SYS 和 EMM386.EXE）。
误区纠正：第 7 楼提到的"MS-DOS 8.0"是 Windows Me 的内核版本。虽然版本号更高，但微软在 Windows Me 中移除了对"实模式 DOS"的官方支持（即无法通过 F8 键进入纯 DOS 模式），因此其兼容性与可玩性远不如 7.10。
2. 关于安装环境与分区限制
NTFS 与 DOS 的不兼容性：第 9、10 楼讨论的"无法在 NTFS 分区安装"是必然的。DOS 内核仅能识别 FAT12/16/32 文件系统。若 C 盘为 NTFS，DOS 引导扇区无法读取该分区上的系统文件，也无法加载驱动程序。
双启动机制：在 Windows NT/2000/XP 环境下实现 DOS 双启动，本质上是利用了 NT 的引导加载程序（NTLDR）。通过将 DOS 的引导扇区保存为文件（如 bootsect.dos），并在 boot.ini 中添加条目，NTLDR 会在启动时加载该扇区，从而将控制权移交给 DOS。这与 Windows 9x 时代的 MSDOS.SYS 引导菜单机制完全不同。
3. 关于 MemMaker 的历史局限
第 3 楼和第 19 楼提到的 MemMaker 是 DOS 6.x 时代的内存优化工具，旨在将驱动程序和 TSR 程序加载到上位内存（UMB）。

技术现状：在 MS-DOS 7.10 环境下，由于系统默认加载了更先进的 HIMEM.SYS 和 EMM386.EXE，且现代硬件环境与 90 年代初差异巨大，MemMaker 的自动配置往往会导致系统不稳定或死机。
结论：第 19 楼的观点正确，手工在 CONFIG.SYS 中通过 DEVICEHIGH 指令加载驱动程序，比依赖 MemMaker 的自动扫描更可靠且高效。
4. 关于硬件检测的建议
第 11、12 楼提到的检测需求，在 2003 年的背景下是合理的。

工具说明：HWINFO 是当时常用的硬件信息查询工具，而 DM（Disk Manager）通常用于大硬盘的初始化或分区。
风险提示：在 DOS 下检测硬件（尤其是硬盘坏道）时，应注意 DOS 工具无法识别现代 SATA 接口（除非加载了特定的 DOS SATA 驱动，如 GCDROM.SYS 或 UATA.SYS），且对大容量硬盘（超过 137GB 的 LBA48 寻址）存在兼容性风险，直接使用可能导致数据丢失或分区表损坏。
5. 总结
MS-DOS 7.10 是 DOS 时代的"最终形态"，其核心价值在于对 FAT32 的支持。对于希望在现代（指 2003 年左右）硬件上运行 DOS 软件的用户，它是最佳选择。但需明确：它本质上是 Windows 9x 的底层组件，而非一个独立开发的操作系统，因此在处理现代文件系统（NTFS）或现代接口硬件时，存在天然的架构限制。
