# Graphics Output Protocol (GOP)

## What is GOP?

GOP (Graphics Output Protocol) is the standard UEFI protocol for graphics display. It replaces the legacy VESA BIOS Extensions (VBE) and the older EFI UGA (Universal Graphics Adapter) protocol.

## Why GOP is Important

Without GOP, a UEFI application can only output text (via the Simple Text Output Protocol). GOP enables:
- Pixel-level graphics rendering
- Games and graphical applications before the OS loads
- Splash screens, boot menus, diagnostic displays

## GOP Architecture

```c
typedef struct {
    UINT32                      Version;
    UINT32                      HorizontalResolution;
    UINT32                      VerticalResolution;
    EFI_GRAPHICS_PIXEL_FORMAT   PixelFormat;
    EFI_PIXEL_BITMASK           PixelInformation;
    UINT32                      PixelsPerScanLine;
} EFI_GRAPHICS_OUTPUT_MODE_INFORMATION;

typedef struct {
    UINT32                              MaxMode;
    UINT32                              Mode;
    EFI_GRAPHICS_OUTPUT_MODE_INFORMATION *Info;
    UINTN                               SizeOfInfo;
    EFI_PHYSICAL_ADDRESS                FrameBufferBase;
    UINTN                               FrameBufferSize;
} EFI_GRAPHICS_OUTPUT_PROTOCOL_MODE;

typedef struct EFI_GRAPHICS_OUTPUT_PROTOCOL {
    EFI_GRAPHICS_OUTPUT_PROTOCOL_QUERY_MODE  QueryMode;
    EFI_GRAPHICS_OUTPUT_PROTOCOL_SET_MODE    SetMode;
    EFI_GRAPHICS_OUTPUT_PROTOCOL_BLT         Blt;
    EFI_GRAPHICS_OUTPUT_PROTOCOL_MODE        *Mode;
} EFI_GRAPHICS_OUTPUT_PROTOCOL;
```

## Key GOP Functions

### 1. LocateProtocol — Get the GOP Instance

```c
EFI_GUID gopGuid = EFI_GRAPHICS_OUTPUT_PROTOCOL_GUID;
EFI_GRAPHICS_OUTPUT_PROTOCOL *gop;

status = BS->LocateProtocol(&gopGuid, NULL, (void**)&gop);
```

### 2. QueryMode — List Available Resolutions

```c
EFI_GRAPHICS_OUTPUT_MODE_INFORMATION *info;
UINTN sizeOfInfo;

for (i = 0; i < gop->Mode->MaxMode; i++) {
    status = gop->QueryMode(gop, i, &sizeOfInfo, &info);
    Print(L"Mode %d: %dx%d\n",
        i, info->HorizontalResolution, info->VerticalResolution);
}
```

### 3. SetMode — Switch Resolution

```c
status = gop->SetMode(gop, modeNumber);
// After SetMode, framebuffer info is in gop->Mode
Print(L"Framebuffer: 0x%lx, size: %ld, %dx%d, pitch: %d\n",
    gop->Mode->FrameBufferBase,
    gop->Mode->FrameBufferSize,
    gop->Mode->Info->HorizontalResolution,
    gop->Mode->Info->VerticalResolution,
    gop->Mode->Info->PixelsPerScanLine);
```

### 4. Blt — Block Transfer (Buffer to Screen)

```c
typedef enum {
    EfiBltVideoFill,           // Fill area with color
    EfiBltVideoToBltBuffer,    // Copy screen → buffer
    EfiBltBufferToVideo,       // Copy buffer → screen
    EfiBltVideoToVideo         // Copy screen → screen
} EFI_GRAPHICS_OUTPUT_BLT_OPERATION;

// Copy a 256×240 game buffer to the screen at (100, 50)
gop->Blt(
    gop,
    gameBuffer,                // Pixel data
    EfiBltBufferToVideo,       // Operation
    0, 0,                      // Source X, Y (in buffer)
    100, 50,                   // Destination X, Y (on screen)
    256, 240,                  // Width, Height
    0                          // Delta (0 = pixels per scanline from Width)
);
```

## Framebuffer

After `SetMode`, `gop->Mode->FrameBufferBase` points to a linear framebuffer — a contiguous block of video memory. You can write pixel data directly:

```c
UINT32 *fb = (UINT32*)(UINTN)gop->Mode->FrameBufferBase;
UINT32 pitch = gop->Mode->Info->PixelsPerScanLine;

// Plot a red pixel at (x, y)
fb[y * pitch + x] = 0xFFFF0000;  // ARGB format
```

## Double Buffering

Reading from the framebuffer is very slow. The standard technique:
1. Render to a **back buffer** in system memory
2. Copy the complete frame to the framebuffer with `Blt` (BufferToVideo)

UEFI_Contra does exactly this: renders to a 256×240 buffer, then integer-scales and Blt's it to the screen.

## Limitations

- **Boot Service only**: GOP is unavailable after `ExitBootServices()`
- The framebuffer persists after ExitBootServices, so you can continue writing pixels — but you lose Blt acceleration
- No hardware acceleration (no 3D, no shaders)

## References

- [UEFI Spec Chapter 12](https://uefi.org/specs/UEFI/2.11/12_Protocols_Console_Support.html)
- [OSDev Wiki - GOP](https://wiki.osdev.org/GOP)
- [Intel GOP Driver Guide](https://www.intel.com/content/dam/doc/guide/uefi-driver-graphics-controller-guide.pdf)
