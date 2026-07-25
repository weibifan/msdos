# UEFI_Contra Project Analysis

## Overview

**UEFI_Contra** (by MikeWuPing) ports the classic NES game Contra to run as a UEFI application on UEFI firmware. The game runs in the UEFI Shell environment, rendering through GOP directly — no operating system needed.

**GitHub**: https://github.com/MikeWuPing/UEFI_Contra

## Project Statistics

| Category | Lines |
|----------|-------|
| C source (.c) | ~3,200 |
| Headers (.h) | ~1,900 |
| Level data | ~650 |
| **Total** | **~7,500** |

## Architecture

### Build System

The project is built as an EDK2 EmulatorPkg application:

```
ContraGame.inf (INF file)
  │
  ├─ entry.c    → UefiMain() entry point
  ├─ main.c     → Game loop, initialization
  ├─ render.c   → GOP rendering pipeline
  ├─ input.c    → Keyboard input via UEFI Simple Text Input
  ├─ player.c   → Player character
  ├─ enemy.c    → 4 enemy types with AI
  ├─ bullet.c   → Projectile system
  ├─ weapon.c   → 6 weapon types
  ├─ level.c    → Level loading and scrolling
  ├─ sprites.c  → Sprite loading (.spr files)
  ├─ game_state.c → State machine
  └─ nes_palette.c → NES color palette
```

### Source Code Structure

```
src/
├── ContraGame.inf    — EDK2 INF build file
├── entry.c           — UEFI entry point
├── main.c            — Game loop (60fps), initialization
├── render.c          — Rendering pipeline, GOP Blt
├── input.c/.h        — Keyboard input
├── player.c/.h       — Player logic
├── enemy.c/.h        — Enemy AI (4 types)
├── bullet.c/.h       — Bullet system
├── weapon.c/.h       — 6 weapons
├── level.c/.h        — Level data loading, scrolling
├── game_state.c/.h   — Game/Level state machine
├── sprites.c/.h      — Sprite loading (.spr)
├── nes_palette.c/.h  — NES → ARGB color conversion
├── types.h           — Fixed-point types, constants
├── level_data.h      — Level layout, collision data
├── intro_*.h         — Title screen data
└── tiles_*.h         — Tile data (background tiles)
```

## Game State Machine

The core game logic is driven by two state machines:

### Game Routine (7 states)

```
 00 → 01 → 02 → 03 → 04 → 05 ←→ 06
Logo  Sel   Demo  Flash Clear Core  End
```

### Level Routine (11 sub-states, inside Game Routine 05)

```
00 → 01 → 02 → 03 → 04 ←→ 05 → 06/07 → 08 → 09 → 0a
Load Show  Flikr Draw Core  Clear G/Over Boss Seq   Delay
```

## Rendering Pipeline

Per frame (60fps):

```
PollInput() → GameStateMachine() → RenderGame()
                                      │
                    ┌─────────────────┴─────────────────┐
                    │                                    │
              DrawBackground()                    DrawSprites()
                    │                                    │
         ┌──────────┴──────────┐                        │
         │                     │                         │
   Decompress RLE       Map Super-Tile              Draw Player
   Screen Data          → Tile Array                Draw Enemies
         │                     │                    Draw Bullets
         ▼                     ▼                    Draw HUD
   8×8 Tile Render    Palette Lookup
         │                     │
         └──────────┬──────────┘
                    ▼
          256×240 Game Buffer
                    │
                    ▼
          ScaleAndPresent()
           (2×/3× integer)
                    │
                    ▼
              GOP Blt → Screen
```

## Key Technical Decisions

### 1. Fixed-Point Arithmetic
```c
// INT32 8.8 fixed-point format
typedef int32_t fixed_t;
#define FIXED_SHIFT   8
#define FIXED_SCALE   (1 << FIXED_SHIFT)
#define INT_TO_FIXED(x) ((fixed_t)(x) * FIXED_SCALE)
```
Avoids floating-point, ensures consistent behavior across platforms.

### 2. Static Memory Allocation
All game arrays are fixed-size at compile time. No malloc/free — prevents memory fragmentation in the UEFI environment.

### 3. Double Buffering
1. Render to a 256×240 system memory buffer
2. `ScaleAndPresent()`: integer 2×/3× scale + Blt to GOP framebuffer

### 4. Sprite Files (.spr)
Sprites are pre-converted from PNG to `.spr` binary format (Python tool). Loaded at runtime via UEFI Simple File System Protocol. Keeps `.efi` file size small.

### 5. RLE Compression
Level data is compressed with RLE (Run-Length Encoding). Control code: 0x80 | length, followed by the byte to repeat.

## Enemy AI Types

| Type | Behavior |
|------|----------|
| Soldier | Walks, stops, shoots at player |
| Turret | Fixed position, tracks and aims at player |
| Boss | Tracks player, rapid fire, multiple hits to defeat |
| Runner | Fast movement, jumps over obstacles |

## Weapon System

| Name | Key | Description |
|------|-----|-------------|
| Default | M | Standard rifle, single shot |
| Machine Gun | R | Rapid fire, auto-repeat |
| Fire Ball | F | Spinning fire projectile |
| Spread | S | 5-way spread shot |
| Laser | L | Penetrating beam |
| Barrier | B | Temporary invincibility |

## Collision Detection

Four-level collision code system (per tile):
- **Code 0**: Empty — free passage
- **Code 1**: Floor — can stand on, can drop through with Down
- **Code 2**: Water — cannot jump, lower body hidden
- **Code 3**: Solid — completely impassable

## What Was Not Ported

- **Audio** — UEFI audio driver complexity is high; QEMU audio emulation is limited
- **Two-player mode** — Only single player implemented
- **Full game** — First level only (13 screens) as a tech demo

## Build Process Summary

```
1. PNG sprites → .spr (png_to_spr.py)
2. Insert source into EDK2 EmulatorPkg
3. build command with VS2019
4. Output: Contra.efi
5. Place on FAT disk with .spr files
6. QEMU + OVMF → UEFI Shell → Contra
```

## References

- Original: https://github.com/MikeWuPing/UEFI_Contra
- NES Contra Disassembly: https://github.com/vermiceli/nes-contra-us
- EDK2: https://github.com/tianocore/edk2
- QEMU: https://www.qemu.org/
