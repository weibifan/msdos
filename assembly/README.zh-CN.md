<p align="center">
  <a href="README.md"><img alt="English" height="30" src="https://img.shields.io/badge/English-3593D2?style=for-the-badge"></a>&nbsp;
  <a href="README.zh-CN.md"><img alt="简体中文" height="30" src="https://img.shields.io/badge/简体中文-7CB342?style=for-the-badge"></a>
</p>

# 汇编开发工具

x86 汇编语言开发工具合集，用于 MS-DOS。

| 文件 | 说明 |
| ------ | ------ |
| MASM.EXE | 微软宏汇编器（MASM），官方 x86 汇编器 |
| LINK.EXE | 微软链接器，将目标文件链接为可执行文件，与 MASM 配合使用 |
| debug.exe | MS-DOS DEBUG，内置命令行调试器，用于检查和调试可执行文件 |
| masm611.zip | MASM 6.11 完整包 |
| tasm31.zip | Turbo Assembler (TASM) v3.1，Borland 高速 x86 汇编器，支持 IDE 集成 |
| nasm098p.zip | NASM v0.98p，可移植的 Netwide Assembler，Intel 语法 |

## Quick Start

**1. 启动 DOSBox（在仓库根目录执行）**

```bash
dosbox -c "mount c ." -c "c:" -c "cd assembly"
```

**2. 编译运行 hello.asm（在 DOSBox 内）**

```bash
masm hello.asm;
link hello.obj;
hello
```

使用 `debug hello.exe` 检查和单步调试可执行文件。

参见 [`hello.asm`](hello.asm) 源码——经典的 DOS Hello World，使用 INT 21h 功能 09h。

## 参考链接

- [8086 汇编语言程序合集](https://github.com/Amey-Thakur/8086-ASSEMBLY-LANGUAGE-PROGRAMS) — 全面的 8086 汇编程序收集
