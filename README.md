# MS-DOS Legacy Collection 🖥️

> **Preserving the foundations of personal computing — MS-DOS environments, tools, boot disks, and historical resources.**

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-MS--DOS%206.22%2F7.1-lightgrey)]()
[![Maintenance](https://img.shields.io/badge/maintained%3F-yes-green.svg)]()

---

## 📋 Overview

This repository is a curated collection of **MS-DOS resources**, including:

- **Complete MS-DOS 6.22 system images** — ready to deploy via Ghost or disk images
- **MS-DOS 7.1** — the final DOS release (from Windows 9x)
- **Boot disk images** — DOS 6.22, rescue disks, Windows 9x startup disks, and more
- **MS-DOS 6.0 source code** — for historical and educational reference
- **QEMU VM configuration** — run MS-DOS in a lightweight emulator
- **VMware Workstation VM** — pre-configured virtual machine
- **Retro Windows** — Windows 1.0 and Chinese PWIN32

---

## 📦 Repository Structure

```
msdos/
├── README.md                          # This file
├── DOS622.GHO                         # MS-DOS 6.22 Ghost disk image
├── MS-DOS_VMware_5.5.zip              # Pre-configured VMware VM
├── MS-DOS_6.0_Source_Code.zip         # MS-DOS 6.0 source code (educational)
├── PWIN32_Chinese_Windows_3.2.zip     # Chinese version of Windows 3.2
├── Windows_1.0.rar                    # Windows 1.0 (historical)
│
├── boot_disk/                         # Boot disk image collection
│   ├── DOS622.IMG                     #   MS-DOS 6.22 boot disk
│   ├── DOSBOOT.img                    #   Generic DOS boot disk
│   ├── DOSRESCU.IMG                   #   DOS rescue disk
│   ├── RESCUE.IMG                     #   Rescue utility disk
│   ├── UNIX.img                       #   UNIX boot disk
│   ├── WIN95.img                      #   Windows 95 startup disk
│   ├── WIN97.img                      #   Windows 97 (OEM) startup disk
│   ├── WIN98.IMG                      #   Windows 98 startup disk
│   ├── WIN98SE.IMG                    #   Windows 98 SE startup disk
│   ├── HD.EXE                         #   Raw disk image writer
│   ├── UNDISK.EXE                     #   Disk image extraction tool
│   └── UNDISKP.EXE                   #   UNDISK (protected mode)
│
├── msdos7/                            # MS-DOS 7.1 (final DOS release)
│   ├── dos71_1.zip                    #   Disk 1
│   ├── dos71_2.zip                    #   Disk 2
│   └── msdos71b.zip                   #   MS-DOS 7.1 beta
│
└── QEMU/                              # QEMU virtual machine setup
    ├── myimage.zip                    #   Pre-built QEMU disk image
    ├── qemu_screenshot.png            #   Screenshot of QEMU running DOS
    └── README.md                      #   QEMU setup guide
```

---

## 🚀 Quick Start

### Option 1: VMware Workstation (Recommended)

1. Extract `MS-DOS_VMware_5.5.zip`
2. Open the `.vmx` file with VMware Workstation 5.x or later
3. Power on the virtual machine
4. You're in MS-DOS!

### Option 2: QEMU (Lightweight)

See the [QEMU guide](QEMU/README.md) for detailed setup instructions.

```bash
# Quick start (after extracting the image)
qemu-system-x86_64 -m 64 -drive file=myimage.img,format=raw
```

### Option 3: Physical Machine / Real Hardware

Use the boot disk images in `boot_disk/`:

```bash
# Write a boot disk image to a floppy disk (requires a floppy drive)
hd.exe DOS622.IMG
```

Or extract the Ghost image `DOS622.GHO` to a hard disk partition using Norton Ghost.

---

## 🛠 Tools Included

| Tool | Description |
|------|-------------|
| **HD.EXE** | Write raw disk images to floppy drives |
| **UNDISK.EXE** | Extract disk image files |
| **UNDISKP.EXE** | UNDISK protected-mode variant |
| **Norton Ghost** | System imaging and restore (via DOS622.GHO) |

---

## 📚 Historical Notes

- **MS-DOS 6.22** (1994) — The last standalone retail version of MS-DOS before it became part of Windows 9x.
- **MS-DOS 7.1** (1998) — The final DOS version, shipped with Windows 98 SE. Introduced FAT32 and larger disk support.
- **Windows 1.0** (1985) — Microsoft's first GUI operating environment, running on top of MS-DOS.
- **PWIN32** — The Chinese (Simplified) localized version of Windows 3.2, an important milestone for computing in China.

---

## ⚠️ System Requirements (MS-DOS 6.22)

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| CPU | 8088 | 486 DX or better |
| RAM | 640 KB | 4–16 MB |
| Storage | 10 MB | 100 MB |
| Floppy | 1.44 MB drive | — |
| Graphics | CGA | VGA |
| Boot media | Floppy or HDD | HDD with DOS |

---

## 📖 References & Further Reading

- [MS-DOS history on Wikipedia](https://en.wikipedia.org/wiki/MS-DOS)
- [MS-DOS 6.22 Technical Reference](https://archive.org/details/msdos622)
- [QEMU documentation](https://www.qemu.org/documentation/)
- [FreeDOS — modern free DOS alternative](http://www.freedos.org/)

---

## 🤝 Contributing

Contributions are welcome! If you have additional MS-DOS resources, tools, or documentation:

1. Fork the repository
2. Create a feature branch
3. Submit a Pull Request

> **Note on licensing**: Most MS-DOS original files are provided under Microsoft's historical licenses or for educational/archival purposes. Please respect applicable copyrights.

---

## 📜 License

This repository is provided for **educational and historical preservation purposes**. Original MS-DOS components are the property of their respective owners. Original tools and documentation in this collection are shared under the MIT License unless otherwise noted.

---

<p align="center">
  <sub>Preserving computing history, one byte at a time. 🖥️</sub>
</p>
