# Graphics Output Protocol (GOP)

## 什么是 GOP？

GOP（图形输出协议）是用于图形显示的标准 UEFI 协议。它取代了传统的 VESA BIOS 扩展（VBE）和旧的 EFI UGA（通用图形适配器）协议。

## 为什么 GOP 很重要

没有 GOP，UEFI 应用程序只能输出文本（通过 Simple Text Output Protocol）。GOP 实现了以下功能：
- 像素级图形渲染
- 在操作系统加载之前运行游戏和图形应用程序
- 开机画面、启动菜单、诊断显示

## GOP 架构

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

## 关键 GOP 函数

### 1. LocateProtocol — 获取 GOP 实例

```c
EFI_GUID gopGuid = EFI_GRAPHICS_OUTPUT_PROTOCOL_GUID;
EFI_GRAPHICS_OUTPUT_PROTOCOL *gop;

status = BS->LocateProtocol(&gopGuid, NULL, (void**)&gop);
```

### 2. QueryMode — 列出可用分辨率

```c
EFI_GRAPHICS_OUTPUT_MODE_INFORMATION *info;
UINTN sizeOfInfo;

for (i = 0; i < gop->Mode->MaxMode; i++) {
    status = gop->QueryMode(gop, i, &sizeOfInfo, &info);
    Print(L"Mode %d: %dx%d\n",
        i, info->HorizontalResolution, info->VerticalResolution);
}
```

### 3. SetMode — 切换分辨率

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

### 4. Blt — 块传输（缓冲区到屏幕）

```c
typedef enum {
    EfiBltVideoFill,           // 用颜色填充区域
    EfiBltVideoToBltBuffer,    // 复制屏幕 → 缓冲区
    EfiBltBufferToVideo,       // 复制缓冲区 → 屏幕
    EfiBltVideoToVideo         // 复制屏幕 → 屏幕
} EFI_GRAPHICS_OUTPUT_BLT_OPERATION;

// 将 256×240 的游戏缓冲区复制到屏幕的 (100, 50) 位置
gop->Blt(
    gop,
    gameBuffer,                // 像素数据
    EfiBltBufferToVideo,       // 操作类型
    0, 0,                      // 源 X, Y（缓冲区中）
    100, 50,                   // 目标 X, Y（屏幕上）
    256, 240,                  // 宽度, 高度
    0                          // Delta（0 = 使用 Width 作为每扫描线像素数）
);
```

## 帧缓冲（Framebuffer）

`SetMode` 后，`gop->Mode->FrameBufferBase` 指向线性帧缓冲——一段连续的视频内存。可以直接写入像素数据：

```c
UINT32 *fb = (UINT32*)(UINTN)gop->Mode->FrameBufferBase;
UINT32 pitch = gop->Mode->Info->PixelsPerScanLine;

// 在 (x, y) 处绘制一个红色像素
fb[y * pitch + x] = 0xFFFF0000;  // ARGB 格式
```

## 双缓冲

从帧缓冲读取数据非常慢。标准技术：
1. 在系统内存的 **后缓冲（back buffer）** 中渲染
2. 使用 `Blt`（BufferToVideo）将完整帧复制到帧缓冲

UEFI_Contra 正是这样做的：渲染到 256×240 缓冲区，然后整数缩放并通过 Blt 输出到屏幕。

## 限制

- **仅限启动服务**：`ExitBootServices()` 后 GOP 不可用
- ExitBootServices 后帧缓冲仍然存在，因此可以继续写入像素——但会失去 Blt 加速功能
- 无硬件加速（无 3D，无着色器）

## 参考文献

- [UEFI Spec Chapter 12](https://uefi.org/specs/UEFI/2.11/12_Protocols_Console_Support.html)
- [OSDev Wiki - GOP](https://wiki.osdev.org/GOP)
- [Intel GOP Driver Guide](https://www.intel.com/content/dam/doc/guide/uefi-driver-graphics-controller-guide.pdf)
