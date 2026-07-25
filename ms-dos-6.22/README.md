<p align="center">
  <a href="README.md"><img alt="English" height="30" src="https://img.shields.io/badge/English-3593D2?style=for-the-badge"></a>&nbsp;
  <a href="README.zh-CN.md"><img alt="简体中文" height="30" src="https://img.shields.io/badge/简体中文-7CB342?style=for-the-badge"></a>
</p>

# MS-DOS 6.22

MS-DOS 6.22 installation disks, disk images, and related resources.

## Files

| File | Description |
|------|-------------|
| `MS-DOS 6.22.iso` | MS-DOS 6.22 full installation CD image |
| `disk1.img` | Installation disk 1 |
| `disk2.img` | Installation disk 2 |
| `disk3.img` | Installation disk 3 |
| `Suppdisk.img` | Supplemental disk |
| `DOS622SC.zip` | MSDN Simplified Chinese DOS 6.22 installer |
| `screenshot.png` | Installation screenshot |
| `install(chinese voice).mp4` | Installation video with Chinese narration<br><video src="install(chinese%20voice).mp4" controls width="320"></video> |

## Quick Start

**QEMU (ISO):**
```bash
qemu-system-x86_64 -m 64 -cdrom "MS-DOS 6.22.iso"
```

**QEMU (Floppy):**
```bash
qemu-system-x86_64 -m 64 -fda disk1.img -fdb disk2.img
```

**DOSBox:**
```bash
imgmount d "MS-DOS 6.22.iso" -t cdrom
d:
setup
```

## Notes

- 3 install floppy disks + 1 supplemental disk, all 1.44 MB standard format
- `DOS622SC.zip` contains the MSDN Simplified Chinese version; extract and run SETUP.EXE to install
- ISO works with most VMs (QEMU / VirtualBox / VMware)
