# Legacy BIOS Boot Process

## Overview

Legacy BIOS (Basic Input/Output System) has been the standard PC firmware from 1981 (IBM PC) through the early 2010s. It is stored in a ROM chip on the motherboard and is the first code the CPU executes when the computer powers on.

## Power-On → OS Handoff: Complete Sequence

```
Power On
   │
   ▼
┌──────────────────────────────────────┐
│  1. Power-On Self-Test (POST)        │
│  ─ CPU reset vector (0xFFFFFFF0)     │
│  ─ CPU + chipset initialization      │
│  ─ Memory detection & test           │
│  ─ System bus enumeration            │
└──────────────────────────────────────┘
   │
   ▼
┌──────────────────────────────────────┐
│  2. BIOS Initialization              │
│  ─ Interrupt Vector Table (IVT)      │
│  ─ BIOS Data Area (BDA)              │
│  ─ Extended BIOS Data Area (EBDA)    │
│  ─ Option ROMs (VGA, NIC, SCSI...)   │
│    └─ INT 0x19 hook                  │
└──────────────────────────────────────┘
   │
   ▼
┌──────────────────────────────────────┐
│  3. Boot Device Selection            │
│  ─ INT 0x19 (Load Bootstrap)         │
│  ─ Check boot order (CMOS settings)  │
│  ─ Try each device:                  │
│    ├─ Floppy: sector 0, byte 0x1FE   │
│    ├─ HDD:    MBR, 0x1FE = 0x55AA   │
│    └─ CD-ROM: El Torito spec         │
└──────────────────────────────────────┘
   │
   ▼
┌──────────────────────────────────────┐
│  4. MBR Boot Code                    │
│  ─ First 440 bytes of sector 0       │
│  ─ Partition table at offset 0x1BE   │
│  ─ Signature 0x55AA at offset 0x1FE  │
│  ─ Load VBR (Volume Boot Record)     │
└──────────────────────────────────────┘
   │
   ▼
┌──────────────────────────────────────┐
│  5. Volume Boot Record (VBR)         │
│  ─ First sector of active partition  │
│  ─ Load boot loader (e.g., NTLDR)    │
│  ─ Switch to protected mode          │
└──────────────────────────────────────┘
   │
   ▼
┌──────────────────────────────────────┐
│  6. Boot Loader → OS                 │
│  ─ NTLDR → Windows                   │
│  ─ GRUB/LILO → Linux                 │
│  ─ DOS: IO.SYS + MSDOS.SYS          │
└──────────────────────────────────────┘
```

## Step-by-Step Detail

### 1. CPU Reset & POST (Power-On Self-Test)

**x86 CPU Reset State:**
- **CS:IP = 0xF000:0xFFF0** → physical address **0xFFFFFFF0** (top of 4 GB)
- 16-bit real mode
- All registers cleared (except CS)

At 0xFFFFFFF0, there is a **jump** instruction to the BIOS entry point (typically 0xF000:E05B).

**POST checks:**
- CPU registers and flags
- Timer (PIT channel 0)
- DMA controller
- First 64 KB of RAM (R/W test via pattern 0x55AA)
- CMOS battery and RTC
- Keyboard controller (A20 gate)
- Video card initialization (VGA BIOS at 0xC0000)
- Secondary storage controllers

**Beep codes** indicate POST failures:
| Beeps | Error |
|-------|-------|
| 1 short | Normal POST |
| 1 long, 2 short | Video card failure |
| Continuous short | Power supply failure |
| No beep | CPU or motherboard failure |

### 2. BIOS Initialization

**Memory Map after POST:**

```
0x00000000 - 0x000003FF: Interrupt Vector Table (256 × 4 bytes)
0x00000400 - 0x000004FF: BIOS Data Area (BDA)
0x00000500 - 0x0009FFFF: Conventional Memory (640 KB)
0x000A0000 - 0x000BFFFF: VGA Video Memory
0x000C0000 - 0x000C7FFF: Video BIOS (32 KB)
0x000F0000 - 0x000FFFFF: System BIOS (64 KB)
0xFFFFFFF0                 : Reset Vector
```

**Key BIOS Data Area (BDA) fields:**
| Address | Size | Description |
|---------|------|-------------|
| 0x0410 | 2 bytes | Equipment list (floppy, HDD, video mode) |
| 0x0413 | 2 bytes | Conventional memory size (in KB) |
| 0x0417 | 2 bytes | Keyboard shift state flags |
| 0x0463 | 2 bytes | Base I/O port address of video controller |
| 0x0475 | 1 byte | Number of hard drives detected |

**Option ROMs (Expansion ROMs):**
- Devices like VGA cards, SCSI controllers, network cards have onboard ROM
- Each ROM has a header at offset 0xAA55 with initialization routine
- BIOS scans 0xC0000-0xE0000 in 2 KB increments
- Option ROM handlers typically hook INT 0x13 (disk) or INT 0x10 (video)

### 3. Boot Device Selection (INT 0x19)

After POST, BIOS executes **INT 0x19** (Load Bootstrap).

**Boot order is stored in CMOS RAM** (accessible via ports 0x70/0x71):
```
CMOS offset 0x2E: boot sequence flag
CMOS offset 0x3D: device priority list
```

**Boot attempt sequence for each device:**
1. Read sector 0 into 0x0000:0x7C00
2. Check bytes 0x1FE-0x1FF = 0x55AA signature
3. If valid, jump to 0x0000:0x7C00
4. If invalid, try next device
5. If all fail, display "No bootable device" / INT 0x18

### 4. MBR (Master Boot Record)

**Layout** (sector 0, LBA 0):

| Offset | Size | Content |
|--------|------|---------|
| 0x000 | 440 bytes | Bootstrap code (Stage 1) |
| 0x1B8 | 4 bytes | Optional disk signature |
| 0x1BC | 2 bytes | Usually 0x0000 |
| 0x1BE | 16 bytes | Partition entry 1 |
| 0x1CE | 16 bytes | Partition entry 2 |
| 0x1DE | 16 bytes | Partition entry 3 |
| 0x1EE | 16 bytes | Partition entry 4 |
| 0x1FE | 2 bytes | Signature 0x55AA |

**MBR Code Function:**
1. Find the active (bootable) partition
2. Load VBR (first sector of that partition) to 0x0000:0x7C00
3. Jump to it

### 5. VBR (Volume Boot Record)

The VBR loads and executes the boot loader specific to the filesystem:
- **FAT12/16**: IO.SYS + MSDOS.SYS (DOS) or NTLDR (Windows)
- **FAT32/HPFS**: Same as FAT16
- **NTFS**: NTLDR or bootmgr

### 6. Boot Loader → OS

**DOS Boot:**
```
VBR → IO.SYS → MSDOS.SYS → COMMAND.COM
    (hidden)   (hidden)     (shell)
```

**Windows NT+ Boot:**
```
VBR → NTLDR → NTDETECT.COM → ntoskrnl.exe (NT kernel)
```

**Linux Boot (GRUB):**
```
VBR → GRUB stage 1 → stage 1.5 → stage 2 → kernel + initrd
                   (embeded in  (filesystem
                    MBR gap)    driver)
```

## BIOS Interrupts (Software)

BIOS provides hardware abstraction through **software interrupts**:

| Interrupt | Service | Examples |
|-----------|---------|----------|
| INT 0x10 | Video | Set mode, plot pixel, write text |
| INT 0x13 | Disk | Read/write sectors, get disk params |
| INT 0x16 | Keyboard | Get keystroke, check key status |
| INT 0x1A | Time/CMOS | Read RTC, set system time |
| INT 0x15 | Misc | Memory size, joystick, cassette |
| INT 0x17 | Printer | Print character, init, status |

**Calling convention:** AH = function number, other registers = parameters, then `INT n`.

Example — read disk sector using INT 0x13:
```asm
mov ah, 0x02        ; function: read sectors
mov al, 0x01       ; number of sectors
mov ch, 0x00       ; cylinder
mov cl, 0x02       ; sector (1-indexed)
mov dh, 0x00        ; head
mov dl, 0x80        ; drive (0x80 = first HDD)
mov bx, 0x7E00    ; buffer address (ES:BX)
int 0x13
```

## BIOS Limitations

| Feature | Legacy BIOS | UEFI |
|---------|-------------|------|
| CPU mode | 16-bit real mode | 32/64-bit protected/long mode |
| Address space | 1 MB (20-bit) | Full (32/64-bit) |
| Disk | MBR (2 TB max) | GPT (9.4 ZB max) |
| Partitions | 4 primary | 128+ |
| Network boot | PXE via UNDI | UEFI network stack |
| GUI | Text-only menus | Graphical pre-boot apps |
| Boot speed | Slower (16-bit, polled I/O) | Faster (parallel init) |
| Security | None | Secure Boot |

## References

- [OSDev Wiki - BIOS](https://wiki.osdev.org/BIOS)
- [IBM PC/AT Technical Reference (1984)](https://archive.org/details/IBM_PC_AT_Technical_Reference_1984)
- [Ralf Brown's Interrupt List](http://www.ctyme.com/rbrown.htm)
- [Phil Storrs PC Hardware Book](http://www.philpem.me.uk/pc-hardware-book/)
