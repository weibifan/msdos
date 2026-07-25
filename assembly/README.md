<p align="center">
  <a href="README.md"><img alt="English" height="30" src="https://img.shields.io/badge/English-3593D2?style=for-the-badge"></a>&nbsp;
  <a href="README.zh-CN.md"><img alt="简体中文" height="30" src="https://img.shields.io/badge/简体中文-7CB342?style=for-the-badge"></a>
</p>

# Assembly Development Tools

A collection of x86 assembly language development tools for MS-DOS.

| File           | Description                                                                             |
| -------------- | --------------------------------------------------------------------------------------- |
| `MASM.EXE`     | Microsoft Macro Assembler (MASM) — the official x86 assembler from Microsoft.           |
| `LINK.EXE`     | Microsoft Linker — links object files into executables. Used with MASM.                 |
| `debug.exe`    | MS-DOS DEBUG — built-in command-line debugger for inspecting and debugging executables. |
| `masm611.zip`  | MASM 6.11 — Microsoft Macro Assembler v6.11 complete package.                           |
| `tasm31.zip`   | Turbo Assembler (TASM) v3.1 — Borland's high-speed x86 assembler with IDE integration.  |
| `nasm098p.zip` | NASM v0.98p — Netwide Assembler, a portable x86 assembler with Intel syntax.            |

## Quick Start in DOSBox

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

Use `debug hello.exe` to inspect and step through the executable.

See [`hello.asm`](hello.asm) for the source code — a classic DOS Hello World using INT 21h, function 09h.

## Reference

* [8086 Assembly Language Programs](https://github.com/Amey-Thakur/8086-ASSEMBLY-LANGUAGE-PROGRAMS) — a comprehensive collection of 8086 assembly programs

