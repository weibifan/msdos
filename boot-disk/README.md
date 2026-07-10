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
| `hd.exe` | Write disk images directly to floppy drives |
| `undisk.exe` | Extract/capture disk image files |
| `undiskp.exe` | UNDISK variant for protected mode |

## Usage

**Write an image to a real floppy disk:**

```bash
hd.exe dos622.img
```

**Extract an existing floppy to an image file:**

```bash
undisk.exe A: output.img
```

## Notes

- All images are 1.44 MB (standard high-density floppy format)
- Use with real floppy drives, emulators (QEMU, VirtualBox, VMware), or virtual floppy tools
