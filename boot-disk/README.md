# Boot Disk Collection

A collection of bootable disk images for MS-DOS and Windows 9x era systems.

## Images

| File | Content | Purpose |
|------|---------|---------|
| `dos622.img` | MS-DOS 6.22 | Standard DOS boot disk |
| `dosboot.img` | Generic DOS | Boot disk for various DOS versions |
| `dosrescu.img` | DOS Rescue | System rescue and recovery |
| `rescue.img` | Rescue utils | Utility disk with recovery tools |
| `unix.img` | UNIX boot | UNIX boot disk |
| `win95.img` | Windows 95 | Windows 95 startup disk |
| `win97.img` | Windows 97 OEM | Windows 97 (OEM) startup disk |
| `win98.img` | Windows 98 | Windows 98 startup disk |
| `win98se.img` | Windows 98 SE | Windows 98 Second Edition startup disk |

## Tools

| File | Description |
|------|-------------|
| `pct9.zip` | PC Tools 9.0 — comprehensive DOS utility suite by Central Point Software. Includes file manager (PC Shell), disk editor (DiskEdit), recovery tools (Undelete, Unformat), disk diagnostic (DiskFix), system optimization (SI Pro, Compress), and more. |
| `hd-copy.exe` | HD-COPY v2.3R — fast floppy disk copier/imager by Oliver Fromme (TBH-Softworx, Cardware). Copies floppy on the fly or via .IMG files. Supports non-standard formats (up to 1.764 MB), fast formatting, drive cleaning, virus removal, and bad sector repair. Text-mode UI with mouse/keyboard support. |
| `undisk.exe` | UNDISK v1.6 — disk image extractor by Zhihong Feng. Extracts files from various floppy image formats (HD-COPY, DiskDupe, IMG, etc.). |
| `undiskp.exe` | UNDISKP v1.95 — enhanced version with long filename support and support for more image formats (HD-COPY, CopyQM, DiskDupe, XDFCOPY, etc.). |

## Usage

**Write an image to a real floppy disk:**

```bash
hd-copy.exe dos622.img
```

**Extract an existing floppy to an image file:**

```bash
undisk.exe A: output.img
```

## Notes

- All images are 1.44 MB (standard high-density floppy format)
- Use with real floppy drives, emulators (QEMU, VirtualBox, VMware), or virtual floppy tools
