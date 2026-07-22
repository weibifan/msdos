# Assembly Development Tools

A collection of x86 assembly language development tools for MS-DOS.

| File | Description |
|------|-------------|
| `MASM.EXE` | Microsoft Macro Assembler (MASM) — the official x86 assembler from Microsoft. |
| `LINK.EXE` | Microsoft Linker — links object files into executables. Used with MASM. |
| `debug.exe` | MS-DOS DEBUG — built-in command-line debugger for inspecting and debugging executables. |
| `masm611.zip` | MASM 6.11 — Microsoft Macro Assembler v6.11 complete package. |
| `tasm31.zip` | Turbo Assembler (TASM) v3.1 — Borland's high-speed x86 assembler with IDE integration. |
| `nasm098p.zip` | NASM v0.98p — Netwide Assembler, a portable x86 assembler with Intel syntax. |

## Quick Start in DOSBox

```bash
mount c c:\msdos_repo\assembly
c:
masm hello.asm;          # Assemble: hello.asm → hello.obj
link hello.obj;          # Link:     hello.obj → hello.exe
hello                     # Run
```

Use `debug hello.exe` to inspect and step through the executable.

## Reference

- [8086 Assembly Language Programs](https://github.com/Amey-Thakur/8086-ASSEMBLY-LANGUAGE-PROGRAMS) — a comprehensive collection of 8086 assembly programs
