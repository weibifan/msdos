# UEFI Overview

## What is UEFI?

UEFI (Unified Extensible Firmware Interface) is the modern replacement for the legacy PC BIOS (Basic Input/Output System). It defines a software interface between the operating system and the platform firmware.

### History

| Era | Technology | Bits | Address Space | Partition |
|-----|-----------|------|--------------|-----------|
| 1981-2010 | Legacy BIOS | 16-bit | 1 MB | MBR |
| 2000-2005 | EFI 1.0 (Intel) | 32-bit | 4 GB | GPT |
| 2005-present | UEFI 2.x | 32/64-bit | Full | GPT |

### Key Differences from Legacy BIOS

**Legacy BIOS:**
- Runs in 16-bit real mode
- Limited to 1 MB addressable space
- Uses interrupt 0x13 for disk access
- MBR partition table (max 2 TB disk, 4 primary partitions)
- Bootstrap code in first 440 bytes of MBR

**UEFI:**
- Runs in 32/64-bit protected or long mode
- Full system address space
- Protocol-based driver model
- GPT partition table (up to 9.4 ZB, 128 partitions)
- FAT32 file system support natively
- Secure Boot capability
- Can run UEFI applications (.efi files) directly

## UEFI Boot Process

```
Power On
   │
   ▼
SEC (Security Phase)
   │
   ▼
PEI (EFI Pre-Initialization)
   │  - CPU initialization
   │  - Memory detection
   ▼
DXE (Driver Execution Environment)
   │  - Most hardware initialized
   │  - UEFI protocols registered
   ▼
BDS (Boot Device Selection)
   │  - Boot manager runs
   │  - Tries boot options
   ▼
TSL (Transient System Load)
   │  - UEFI Shell (if selected)
   │  - OS boot loader runs
   ▼
RT (Runtime Phase)
   │  - OS takes over
   │  - UEFI Runtime Services remain available
   ▼
AL (After Life)
   - System shutdown/hibernate
```

## UEFI Services

### Boot Services (available before ExitBootServices)
- **Protocol Handler**: LocateProtocol, InstallProtocol, etc.
- **Memory Allocation**: AllocatePool, FreePool, AllocatePages
- **Event/Timer**: CreateEvent, SetTimer, WaitForEvent
- **Image Loading**: LoadImage, StartImage
- **ExitBootServices**: Transfers control to the OS

### Runtime Services (available after ExitBootServices)
- **Variable Services**: GetVariable, SetVariable
- **Time Services**: GetTime, SetTime
- **Reset Services**: ResetSystem
- **Capsule Update**: UpdateCapsule

## UEFI Applications

UEFI applications are PE32+ (Portable Executable) format files with the `.efi` extension. They run in the UEFI environment before any OS is loaded.

Types:
- **Boot loaders**: Load an OS (e.g., GRUB2, Windows Boot Manager)
- **Shell applications**: Run in UEFI Shell (e.g., text editors, file managers)
- **Diagnostics**: Memory testers, hardware info
- **Games**: Like UEFI_Contra!

### UEFI Application Entry Point

```c
#include <Uefi.h>
#include <Library/UefiLib.h>
#include <Library/PrintLib.h>

EFI_STATUS
EFIAPI
UefiMain(
    IN EFI_HANDLE           ImageHandle,
    IN EFI_SYSTEM_TABLE     *SystemTable
)
{
    Print(L"Hello from UEFI!\n");
    return EFI_SUCCESS;
}
```

## UEFI Shell

The UEFI Shell provides a command-line interface in the UEFI environment. Commands include:

| Command | Description |
|---------|-------------|
| `map` | List mapped devices |
| `fs0:`, `fs1:` | Switch to file system |
| `ls` | List files |
| `cd` | Change directory |
| `edit` | Text editor |
| `Contra.efi` | Run the Contra game |

## References

- [UEFI Specification](https://uefi.org/specs/UEFI/2.11/)
- [TianoCore EDK2](https://github.com/tianocore/edk2)
- [OSDev UEFI Wiki](https://wiki.osdev.org/UEFI)
