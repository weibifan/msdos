# QEMU MS-DOS Virtual Machine

> Lightweight MS-DOS emulation using QEMU.

## Files

- **myimage.zip** — Pre-built QEMU disk image with MS-DOS installed
- **qemu_screenshot.png** — Screenshot of the running environment

## Quick Start

```bash
# 1. Extract the disk image
unzip myimage.zip

# 2. Boot with QEMU
qemu-system-x86_64 -m 64 -drive file=myimage.img,format=raw
```

## Detailed Setup

If you need to create a fresh MS-DOS VM:

```bash
# Create a blank disk image
qemu-img create -f raw dos_hd.img 200M

# Boot from an installation floppy image
qemu-system-x86_64 -m 64 \
  -drive file=dos_hd.img,format=raw \
  -fda DOS622.IMG
```

## Installation Notes

- Memory: 64 MB (more than enough for MS-DOS)
- Video: Standard VGA (no special drivers needed)
- Networking: Not configured (MS-DOS has no native TCP/IP)
- Sound: PC speaker only (Sound Blaster can be added)

## Resources

- [QEMU Documentation](https://www.qemu.org/documentation/)
- [QEMU x86 emulation reference](https://wiki.qemu.org/Documentation/Platforms/PC)
