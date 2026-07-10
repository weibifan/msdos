# Boot Disk Collection

A collection of bootable disk images for MS-DOS and Windows 9x era systems.

## Images

| File | Content | Purpose |
|------|---------|---------|
| `DOS622.IMG` | MS-DOS 6.22 | Standard DOS boot disk |
| `DOSBOOT.img` | Generic DOS | Boot disk for various DOS versions |
| `DOSRESCU.IMG` | DOS Rescue | System rescue and recovery |
| `RESCUE.IMG` | Rescue utils | Utility disk with recovery tools |
| `UNIX.img` | UNIX boot | UNIX boot disk |
| `WIN95.img` | Windows 95 | Windows 95 startup disk |
| `WIN97.img` | Windows 97 OEM | Windows 97 (OEM) startup disk |
| `WIN98.IMG` | Windows 98 | Windows 98 startup disk |
| `WIN98SE.IMG` | Windows 98 SE | Windows 98 Second Edition startup disk |

## Tools

| File | Description |
|------|-------------|
| `HD.EXE` | Write disk images directly to floppy drives |
| `UNDISK.EXE` | Extract/capture disk image files |
| `UNDISKP.EXE` | UNDISK variant for protected mode |

## Usage

**Write an image to a real floppy disk:**

```bash
HD.EXE DOS622.IMG
```

**Extract an existing floppy to an image file:**

```bash
UNDISK.EXE A: output.img
```

## Notes

- All images are 1.44 MB (standard high-density floppy format)
- Use with real floppy drives, emulators (QEMU, VirtualBox, VMware), or virtual floppy tools
