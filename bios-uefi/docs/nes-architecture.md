# NES Architecture (Simplified)

## Overview

The Nintendo Entertainment System (1983) is an 8-bit game console. Understanding its architecture is essential for understanding how UEFI_Contra works, since the project reimplements NES rendering on UEFI GOP.

## Core Components

### CPU: MOS 6502 @ 1.79 MHz

- 8-bit processor
- 16-bit address bus (64 KB address space)
- 3 general-purpose registers: A, X, Y
- Stack pointer, program counter, status register
- No multiply/divide instructions
- Little-endian

### PPU: Picture Processing Unit (RP2C02)

The PPU is a dedicated graphics chip that handles all video output.

**Key specs:**
- Resolution: 256×240 pixels (256×224 active)
- 64 colors total (from a fixed palette)
- 8 palettes of 4 colors each (4 for background, 4 for sprites)
- 2BPP (2 bits per pixel) tile format
- 8×8 pixel tiles (or 8×16 for sprites)
- 2 pattern tables (256 tiles each) at PPU $0000 and $1000
- 2 nametables (32×30 tile maps) at PPU $2000 and $2800
- 64 hardware sprites (8 per scanline limit)
- Sprite priority, flipping, and color effects

### Memory Mapping

```
CPU Address Map:
$0000-$07FF: RAM (2 KB)
$0800-$1FFF: Mirrors of RAM
$2000-$2007: PPU Registers
$4000-$4017: APU + I/O Registers
$4018-$401F: Test/Disabled
$4020-$5FFF: Cartridge PRG-ROM (optional)
$6000-$7FFF: Cartridge SRAM
$8000-$FFFF: Cartridge PRG-ROM (fixed)

PPU Address Map:
$0000-$0FFF: Pattern Table 0 (background tiles)
$1000-$1FFF: Pattern Table 1 (sprite tiles)
$2000-$23FF: Nametable 0
$2400-$27FF: Nametable 1
$2800-$2BFF: Nametable 2
$2C00-$2FFF: Nametable 3
$3F00-$3F0F: Background Palette
$3F10-$3F1F: Sprite Palette
```

## 2BPP Tile Format

Each 8×8 pixel tile is 16 bytes:
- 8 bytes for the low bit-plane (bit 0)
- 8 bytes for the high bit-plane (bit 1)

```
Example tile byte layout (4 pixels):
Low plane:    0xAA = 10101010
High plane:   0x55 = 01010101
Combined:     10 01 10 01 = 2, 1, 2, 1 (palette indices)
```

Each 2-bit value is an index into the 4-color palette for that tile.

## NES Palette

The NES has a fixed 64-entry palette:

```
Index   Color           Index   Color
$00     Transparent     $10     Dark Grey
$01     White           $11     Blue Grey
$02     Light Grey      $12     ...
...     ...             ...     ...
$0F     Black           $1F     Black
```

Each NES palette entry maps to an RGB value, which UEFI_Contra implements in `nes_palette.c`.

## Background Rendering

The NES background is rendered from:
1. **Nametable**: 32×30 grid of tile indices (byte per cell)
2. **Attribute Table**: 2-bit palette selector per 16×16 pixel region
3. **Pattern Table**: Actual 8×8 pixel tile data (2BPP)

### Super-Tile System (Contra-specific)

Contra uses a more efficient **Super-Tile** system:

```
Level Data (RLE compressed)
        │
        ▼
    Screen Layout (8×7 = 56 Super-Tile indices, 32×32 pixels each)
        │
        ▼
    Super-Tile Definition (16 tile indices = 4×4 array of 8×8 tiles)
        │
        ▼
    Pattern Table (actual 2BPP pixel data, 16 bytes per tile)
```

**RLE (Run-Length Encoding)**: Control bytes 0x80+NN mean "repeat next byte NN times". For example, `$87 $00` = repeat 0x00 seven times.

## Sprite Rendering

Sprites are 8×8 or 8×16 pixel objects:
- Up to 64 sprites on screen
- 8 sprites per scanline limit
- OAM (Object Attribute Memory): stores sprite X, Y, tile index, attributes

Sprite attributes byte:
```
Bit 7: Flip vertical
Bit 6: Flip horizontal
Bit 5: Priority (behind/above background)
Bits 1-0: Palette index
```

UEFI_Contra loads sprite data from `.spr` files (pre-converted from PNG) via UEFI file system protocol.

## Cartridge Mappers (Contra uses UNROM)

UNROM mapper (INES mapper #2):
- 128KB PRG-ROM divided into 8 × 16KB banks
- Bank 7 is fixed at $C000-$FFFF
- Banks 0-6 are switchable into $8000-$BFFF
- 8KB CHR-RAM (not ROM — Contra writes tile data to PPU)

## Frame Timing

- NTSC: 60 frames per second
- Each frame: 262 scanlines (241 visible, 21 VBlank)
- PPU generates NMI (Non-Maskable Interrupt) during VBlank
- Games update state and sprites during VBlank

UEFI_Contra uses a 60fps timer maintained by the game loop.

## References

- [NESDev Wiki](https://www.nesdev.org/wiki/)
- [NES Architecture: A Practical Approach](https://www.nesdev.org/wiki/NES_reference)
- [NES Palette Reference](https://www.nesdev.org/wiki/PPU_palettes)
