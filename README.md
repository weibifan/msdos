<p align="center">
  <a href="README.md"><img alt="English" height="30" src="https://img.shields.io/badge/English-3593D2?style=for-the-badge"></a>&nbsp;
  <a href="README.zh-CN.md"><img alt="简体中文" height="30" src="https://img.shields.io/badge/简体中文-7CB342?style=for-the-badge"></a>
</p>

# MS-DOS Legacy Collection 🖥️

> Preserving the foundations of personal computing — MS-DOS environments, tools, boot disks, and historical resources.

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-MS--DOS%206.22-lightgrey)]()
[![Maintenance](https://img.shields.io/badge/maintained%3F-yes-green.svg)]()

---

## 📋 Overview

This repository is a curated collection of **MS-DOS resources**, including:

- **MS-DOS 6.22** — Ghost disk image and boot disk
- **MS-DOS 7.10** — The final DOS release (from Windows 98 SE)
- **Boot disk images** — DOS rescue disks, Windows 9x startup disks, and utilities
- **VM images** — Pre-configured virtual machines for [QEMU](ms-dos-in-qemu/README.md) and [VMware](ms-dos-in-vmware/README.md)
- **MS-DOS 6.0 source code** — For historical and educational reference
- **Retro Windows** — Windows 1.0 and Chinese PWIN 3.2 installation disks

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
│   ├── ms-dos-boot.img                    #   Generic DOS boot disk
│   ├── ms-dos-rescue.img                  #   DOS rescue disk
│   ├── rescue.img                         #   Utility disk with recovery tools
│   ├── unix.img                           #   UNIX boot disk
│   ├── win95.img                          #   Windows 95 startup disk
│   ├── win97.img                          #   Windows 97 (OEM) startup disk
│   ├── win98.img                          #   Windows 98 startup disk
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
├── windows-1.0-setup-disk.zip             # Windows 1.0 installation disk
├── UCDOS-7.0-WPS-CCED-6.0-setup.iso      # UCDOS 7.0 (with WPS) + CCED 6.0
│
├── Turbo C 2.01 (5.25-360k)/              # Turbo C 2.01 development environment
│   ├── Disk1 - Install - Help.img         #   Installation & help (360KB)
│   ├── Disk2 - Integrated Development Environment.img  #   IDE
│   ├── Disk3 - Command Line - Utilities.img #   Command line tools
│   ├── Disk4 - Libraries.img              #   Libraries
│   ├── Disk5 - Header Files - Libraries.img #   Header files
│   └── Disk6 - Examples - BGI - Misc.img  #   Examples & graphics
│
└── Turbo C++ 3.0/                         # Turbo C++ 3.0 development environment
    └── Turbo C++ 3.0.zip                  #   Complete package
```

---

## 🚀 Quick Start

### Option 1: QEMU (Lightweight)

```bash
cd ms-dos-in-qemu
unzip myimage.zip
qemu-system-x86_64 -m 64 -drive file=myimage.img,format=raw
```

See the [QEMU guide](ms-dos-in-qemu/README.md) for details.

### Option 2: VMware Workstation

1. Extract `ms-dos-in-vmware/ms-dos-vmware-5.5.zip`
2. Open the `.vmx` file with **VMware Workstation 5.x** or later
3. Power on

### Option 3: Physical Machine / Real Hardware

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

### Turbo C / C++ Development Tools

| Directory | Description |
|-----------|-------------|
| `Turbo C 2.01 (5.25-360k)/` | 6 disk images (360 KB each) of Turbo C 2.01 — the classic MS-DOS C compiler by Borland |
| `Turbo C++ 3.0/` | Complete Turbo C++ 3.0 package — Borland's object-oriented C++ IDE for DOS |

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
