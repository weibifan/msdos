# BIOS / UEFI Bare-Metal Gaming

This directory explores running classic games **without an operating system** — directly on UEFI firmware using the **Graphics Output Protocol (GOP)**.

## Games

| Game | Launch | Status |
|------|--------|--------|
| **Super Mario Bros** | `start-mario.bat` | ✅ Pre-compiled (`super-mario/smb.efi`) |
| **Contra** | `start-contra.bat` | ⏳ Source only — see `contra/build.bat` to compile |

## Directory Structure

| Path | Description |
|------|-------------|
| `OVMF/` | OVMF (Open Virtual Machine Firmware) — UEFI firmware for QEMU |
| `super-mario/` | Super Mario Bros UEFI port — includes `smb.efi` + `startup.nsh` |
| `contra/` | [UEFI_Contra](https://github.com/MikeWuPing/UEFI_Contra) source + build guide |
| `contra/contra-uefi/` | NES Contra ported to UEFI Shell (C source) |
| `contra/build.bat` | Build instructions for `Contra.efi` (requires VS2019 + EDK2) |
| `start-mario.bat` | Launch Super Mario in QEMU + OVMF |
| `start-contra.bat` | Launch Contra in QEMU + OVMF (after building) |
| `docs/` | In-depth technical articles (UEFI, GOP, NES, Contra) |

## Quick Start

### Prerequisites

- [QEMU](https://www.qemu.org/) (included; located at `C:\Program Files\qemu`)

### Play Super Mario Bros

```batch
start-mario.bat
```

### Build & Play Contra

See `contra/build.bat` for full EDK2 build setup (requires VS2019 + EDK2 + NASM).

## Documentation

| File | Description |
|------|-------------|
| `docs/uefi-overview.md` | UEFI architecture, boot process, protocols |
| `docs/bios-legacy.md` | Legacy BIOS flow: power-on → POST → MBR → OS |
| `docs/gop-protocol.md` | Graphics Output Protocol — framebuffer, Blt, modes |
| `docs/nes-architecture.md` | NES hardware: PPU, 2BPP tiles, palettes, Super-Tile |
| `docs/contra-uefi-analysis.md` | UEFI_Contra source analysis: pipeline, state machine, collision |

## Project References

- [UEFI_Contra](https://github.com/MikeWuPing/UEFI_Contra) — Original project by MikeWuPing
- [NESDev Wiki](https://www.nesdev.org/wiki/) — NES hardware reference
- [OSDev Wiki - GOP](https://wiki.osdev.org/GOP) — Graphics Output Protocol
- [UEFI Specification](https://uefi.org/specs/UEFI/2.11/) — Official specification
- [OVMF Project](https://github.com/tianocore/tianocore.github.io/wiki/OVMF) — Open Virtual Machine Firmware
