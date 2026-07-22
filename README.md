<p align="center">
  <a href="README.md"><img alt="English" height="30" src="https://img.shields.io/badge/English-3593D2?style=for-the-badge"></a>&nbsp;
  <a href="README.zh-CN.md"><img alt="简体中文" height="30" src="https://img.shields.io/badge/简体中文-7CB342?style=for-the-badge"></a>
</p>

# MS-DOS Legacy Collection 🖥️

> Preserving the foundations of personal computing — MS-DOS environments, tools, boot disks, and historical resources.

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![GitHub Stars](https://img.shields.io/github/stars/weibifan/msdos?style=flat&logo=github)]()
[![Last Commit](https://img.shields.io/github/last-commit/weibifan/msdos)]()
[![Platform](https://img.shields.io/badge/platform-MS--DOS%206.22-lightgrey)]()
[![Maintenance](https://img.shields.io/badge/maintained%3F-yes-green.svg)]()
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)]()

---

## 📋 Overview

This repository is a curated collection of **MS-DOS resources**, including:

- **MS-DOS 6.22** — Ghost disk image and boot disk
- **MS-DOS 7.10** — The final DOS release (from Windows 98 SE)
- **Boot disk images** — DOS rescue disks, Windows 9x startup disks, and utilities
- **VM images** — Pre-configured virtual machines for [QEMU](ms-dos-in-qemu/README.md) and [VMware](ms-dos-in-vmware/README.md)
- **MS-DOS 6.0 source code** — For historical and educational reference
- **Retro Windows** — Windows 1.0 and Chinese PWIN 3.2 installation disks
- **Assembly tools** — MASM, TASM, NASM, LINK, DEBUG for x86 assembly development
- **Other utilities** — UltraISO and WinImage for disk image management

---

## 📦 Repository Structure

```
msdos/
├── README.md                              # This file
├── ms-dos-622.gho                         # MS-DOS 6.22 Ghost system image
├── Ghost60.exe                            # Norton Ghost 6.0 (disk imaging tool)
│
├── boot-disk/                             # Boot disk image collection
│   ├── README.md                          #   Documentation
│   ├── ms-dos-622.img                     #   MS-DOS 6.22 boot disk
│   ├── ms-dos-rescue.img                  #   DOS rescue disk
│   ├── win95.img                          #   Windows 95 startup disk
│   ├── win98se.img                        #   Windows 98 SE startup disk
│   ├── hd-copy.exe                        #   HD-COPY v2.3R — floppy disk copier/imager
│   ├── undisk.exe                         #   Disk image extraction tool
│   └── undiskp.exe                        #   UNDISK (protected mode)
│
├── tools/                                 # DOS utility tools
│   ├── ARJ.EXE                            #   ARJ v2.50 archiver
│   ├── pkzip250.exe                       #   PKZIP v2.50 archiver
│   ├── pct9.zip                           #   PC Tools 9.0 utility suite
│   ├── sea13.zip                          #   Sea v1.3 image viewer
│   ├── TT/                                #   Typing Tutor IV — typing tutor program
│   └── README.md                          #   Documentation
│
├── games/                                 # Classic DOS games
│   ├── doom.zip                           #   DOOM (1993, id Software)
│   ├── Command & Conquer.zip              #   C&C (1995, Westwood Studios)
│   └── README.md                          #   Documentation
│
├── ms-dos-7.10/                           # MS-DOS 7.1 (final DOS release)
│   ├── ms-dos-71-disk1.zip                #   Installation disk 1
│   ├── ms-dos-71-disk2.zip                #   Installation disk 2
│   └── ms-dos-71-boot.zip                 #   Boot disk
│
├── ms-dos-in-qemu/                        # MS-DOS 6.22 in QEMU 1.2
│   ├── README.md                          #   Setup guide
│   ├── myimage.zip                        #   Pre-built QEMU disk image
│   └── qemu-screenshot.png                #   Screenshot
│
├── ms-dos-in-vmware/                      # MS-DOS 6.22 in VMware 5.5
│   ├── README.md                          #   Setup guide
│   └── ms-dos-vmware-5.5.zip              #   Pre-built VMware VM
│
├── ms-dos-6.0-source-code.zip             # MS-DOS 6.0 source code (educational)
├── chinese-windows-3.2-setup-disk.zip     # PWIN 3.2 (Chinese Windows 3.2)
├── web-demo/                                # Online DOS demo (js-dos)
│   ├── index.html                          #   Typing Tutor IV in browser
│   └── tt-bundle.jsdos                     #   js-dos bundle
├── UCDOS-7.0-WPS-CCED-6.0-setup.iso      # UCDOS 7.0 (with WPS) + CCED 6.0
│
├── c and c++/                              # C/C++ development tools
│   ├── README.md                          #   Documentation
│   ├── Turbo C 2.01 (5.25-360k).zip       #   Turbo C 2.01 — consolidated from 6 disk images
│   └── Turbo C++ 3.0.zip                  #   Turbo C++ 3.0 — complete package
│
├── assembly/                              # Assembly development tools
│   ├── README.md                          #   Documentation
│   ├── MASM.EXE                           #   Microsoft Macro Assembler
│   ├── LINK.EXE                           #   Microsoft Linker
│   ├── debug.exe                          #   MS-DOS DEBUG debugger
│   ├── masm611.zip                        #   MASM 6.11 package
│   ├── tasm31.zip                         #   Turbo Assembler v3.1
│   └── nasm098p.zip                       #   NASM v0.98p
│
├── others/                                # Other utilities
│   ├── README.md                          #   Documentation
│   ├── UltraISO-9.7.6.3860-CN.zip         #   UltraISO disk image editor
│   └── WinImage11-cn.zip                  #   WinImage disk image utility
```

---

## 🚀 Quick Start

### Option 1: DOSBox (Cross-Platform, Recommended) 🎯

**One-click launch** — install [DOSBox](https://www.dosbox.com/), then:

```bash
dosbox -conf dosbox.conf
```

This automatically mounts the repository, sets up PATH, and configures memory (EMS/XMS), sound (Sound Blaster 16), and VGA (SVGA S3) for an optimal retro experience.

**Inside DOSBox**, you start at the repository root `C:\`. To explore:

```dos
C:\> dir              → List files in current directory
C:\> cd tools\TT      → Enter Typing Tutor IV directory
C:\TOOLS\TT> TT       → Start the typing tutor program
C:\> cd games         → Browse classic DOS games
C:\> cd assembly      → Assembly development tools
```

Type `EXIT` at any time to quit DOSBox.

> ![Typing Tutor IV running in DOSBox](tools/TT/screenshot.png)
> *Typing Tutor IV — a classic DOS typing tutor included in this collection.*

> **▶️ [Try it in your browser](web-demo/index.html)** — run Typing Tutor IV online via [js-dos](https://js-dos.com/) (open `web-demo/index.html` locally, or serve with `npx serve web-demo`).

---

### Option 2: QEMU (Lightweight)

```bash
cd ms-dos-in-qemu
unzip myimage.zip
qemu-system-x86_64 -m 64 -drive file=myimage.img,format=raw
```

See the [QEMU guide](ms-dos-in-qemu/README.md) for details.

### Option 3: VMware Workstation

1. Extract `ms-dos-in-vmware/ms-dos-vmware-5.5.zip`
2. Open the `.vmx` file with **VMware Workstation 5.x** or later
3. Power on

### Option 4: Physical Machine / Real Hardware

Use a boot disk image with a floppy drive:

```bash
hd-copy.exe boot-disk/ms-dos-622.img
```

Or deploy the Ghost image `ms-dos-622.gho` using Norton Ghost.

---

## 📚 Content Details

### MS-DOS 6.22 (1994)

The last standalone retail version of MS-DOS. Available as:
- **Ghost image** (`ms-dos-622.gho`) — Ready-to-deploy system image
- **Boot disk** (`boot-disk/ms-dos-622.img`) — 1.44 MB floppy image

### MS-DOS 7.10 (1998)

The final DOS version, shipped with Windows 98 SE. Introduced FAT32 and large disk support. Contains three floppy disk images for installation.

### Virtual Machine Images

| Platform | Image | Description |
|----------|-------|-------------|
| **QEMU 1.2** | `ms-dos-in-qemu/` | Lightweight emulation, 64 MB RAM, 200 MB disk |
| **VMware 5.5** | `ms-dos-in-vmware/` | Pre-configured VM with VGA, floppy support |

### Retro Windows & Chinese DOS Software

| File | Description |
|------|-------------|
| `windows-1.0-setup-disk.zip` | Microsoft Windows 1.0 (1985) — the first GUI OS |
| `chinese-windows-3.2-setup-disk.zip` | PWIN 3.2 — Chinese localized Windows 3.2 |
| `UCDOS-7.0-WPS-CCED-6.0-setup.iso` | **UCDOS 7.0** (with WPS word processor) + **CCED 6.0** (Chinese character editor) — essential Chinese DOS software from the 1990s |

### C / C++ Development Tools

| File | Description |
|------|-------------|
| `c and c++/Turbo C 2.01 (5.25-360k).zip` | Turbo C 2.01 — 6 disk images (360 KB each) of the classic MS-DOS C compiler by Borland |
| `c and c++/Turbo C++ 3.0.zip` | Complete Turbo C++ 3.0 package — Borland's object-oriented C++ IDE for DOS |

### Assembly Development Tools

| Tool | Description |
|------|-------------|
| `assembly/MASM.EXE` | Microsoft Macro Assembler — the official x86 assembler |
| `assembly/LINK.EXE` | Microsoft Linker — links object files into executables |
| `assembly/debug.exe` | MS-DOS DEBUG — built-in debugger for inspecting executables |
| `assembly/masm611.zip` | MASM 6.11 — complete assembler package from Microsoft |
| `assembly/tasm31.zip` | Turbo Assembler v3.1 — Borland's high-speed x86 assembler |
| `assembly/nasm098p.zip` | NASM v0.98p — portable Netwide Assembler |

### Other Utilities

| File | Description |
|------|-------------|
| `others/UltraISO-9.7.6.3860-CN.zip` | UltraISO v9.7.6 (Chinese) — CD/DVD image editor and creator |
| `others/WinImage11-cn.zip` | WinImage v11 (Chinese) — floppy and hard disk image utility |

### Original Source Code

`ms-dos-6.0-source-code.zip` contains the assembly source code of MS-DOS 6.0, released by Microsoft for educational and historical reference.

---

## 🛠 Boot Disk Tools

| Tool | Description |
|------|-------------|
| **Ghost60.exe** | Norton Ghost 6.0 — system disk imaging and cloning |
| **hd-copy.exe** | HD-COPY v2.3R — fast floppy disk copier/imager (Oliver Fromme, Cardware) |
| **undisk.exe** | Extract/capture disk image files |
| **undiskp.exe** | UNDISK protected-mode variant |

---

## 🖥️ Classic 1996 PC Configuration

A typical high-end PC from the mid-1990s, capable of running MS-DOS 6.22, Windows 3.2, and early Windows 9x:

| Component | Specification |
|-----------|---------------|
| **CPU** | Intel 80486 DX2 — 66 MHz |
| **RAM** | 8 MB |
| **Storage** | 512 MB HDD |
| **Graphics** | S3 Graphics Adapter with 1 MB VRAM (640×480 high color under Windows 3.2) |
| **Floppy** | 3.5-inch floppy drive × 1 |
| **CD-ROM** | 2× or 4× CD-ROM drive |
| **Sound** | Sound Blaster 16 |
| **Mouse** | Microsoft-compatible serial mouse |
| **Network** | NE2000 compatible (added later) |

---

## ⚠️ System Requirements (MS-DOS 6.22)

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| CPU | 8088 | 486 DX or better |
| RAM | 640 KB | 4–16 MB |
| Storage | 10 MB | 200 MB |
| Floppy | 1.44 MB drive | — |
| Graphics | CGA | VGA |
| Boot media | Floppy or HDD | HDD with DOS |

---

## 📖 References

- [MS-DOS History](https://en.wikipedia.org/wiki/MS-DOS)
- [MS-DOS 6.22 Technical Reference](https://archive.org/details/msdos622)
- [DOSBox](https://www.dosbox.com/) — DOS emulator for running DOS applications on modern systems
- [DOS资源站 CN-DOS.net](https://www.cn-dos.net/) — Chinese DOS community and resource archive
- [老操作系统集锦](http://www.regexlab.com/sswater/zh/oldos.htm) — Retro OS collection
- [QEMU Documentation](https://www.qemu.org/documentation/)
- [FreeDOS](https://www.freedos.org/) — Modern free DOS alternative

---

## 🤝 Contributing

Contributions welcome! If you have additional MS-DOS resources, tools, or documentation:

1. Fork the repository
2. Create a feature branch
3. Submit a Pull Request

> **Note**: Original MS-DOS components are the property of their respective owners. This collection is provided for **educational and archival purposes**.

---

<p align="center">
  <sub>Preserving computing history, one byte at a time. 🖥️</sub>
</p>
