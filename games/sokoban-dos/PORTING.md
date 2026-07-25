# Sokoban DOS 移植说明

## 概述

将 [bravegnu/sokoban](https://github.com/bravegnu/sokoban)（C 语言，依赖 ncurses/SDL）移植到 MS-DOS，使用 **Turbo C 2.0** 编译。

---

## 一、源代码修改

### 1. 视图层重写 (`src/dos-view.c`)

**原版：** 两套视图——`sdl-view.c`（SDL 图形）和 `term-view.c`（ncurses 终端）。
**DOS 版：** 重新实现 `dos-view.c`，使用 Turbo C 的 `conio.h`：

| 函数 | 原版 | DOS 版 |
|------|------|--------|
| 屏幕初始化 | `initscr()` / SDL_Init | `clrscr()` |
| 画字符 | `mvaddch()` | `gotoxy() + putch()` |
| 键盘输入 | `getch()` (ncurses) | `getch()` (conio) |
| 颜色 | ncurses color pairs | `textattr()` |

### 2. 头文件与类型兼容 (`src/dosdefs.h`)

Turbo C 2.0 是 C89 标准，缺少以下 C99 特性：

| 特性 | 问题 | 解决方案 |
|------|------|----------|
| `<stdbool.h>` | 不存在 | 自定义 `dosdefs.h`：`#define bool int`，`#define true 1` |
| `//` 注释 | 不支持 | 全部改为 `/* */` |

### 3. 日志模块 (`src/log.c` / `src/log.h`)

| 问题 | 原因 | 修改 |
|------|------|------|
| 变参宏 | `__VA_ARGS__` 是 C99 特性 | 移除 `log_trace()` 等宏，全部改为直接调用 `log_log(level, __FILE__, __LINE__, fmt, ...)` |
| `strftime()` | POSIX 函数，Turbo C 没有 | 改用 `sprintf()` + `struct tm` 字段手动格式化 |
| 变量声明位置 | C89 要求语句前声明 | 所有变量移到函数开头 |
| ANSI 颜色码 | DOS 终端不支持 | 移除 `LOG_USE_COLOR` 相关代码 |

### 4. 平台特定头文件

| 原版 include | 问题 | 修改 |
|-------------|------|------|
| `<unistd.h>` | DOS 无此头文件 | 移除（`sleep()` 调用一并移除） |
| `<error.h>` | GNU 扩展，DOS 无 | 替换为简单 `printf()` + `exit()` |
| `<errno.h>` | Turbo C 有此头文件 | 保留但只使用 `ferror()` 等基础功能 |

### 5. 文件行尾格式

Turbo C 2.0 要求源文件使用 **CRLF (`\r\n`)** 行尾，Unix 风格的 LF 会导致编译错误（"Unexpected end of file in conditional"）。

---

## 二、编译问题记录

### 问题 1：文件名 8.3 格式

**现象：** `game-engine.c` 在 DOSBox 的 `dir` 命令中显示为 `game-e~1.c`，TCC 找不到文件。

**原因：** DOSBox 挂载 Windows 目录时，长文件名可能以短文件名（8.3格式）呈现。超过 8 字符的文件名会被截断。

**解决：** 源文件全部使用 ≤8 字符的名称：

| 原文件名 | DOS 文件名 |
|----------|-----------|
| `game-engine.c` | `game_eng.c` |
| `level-parser.c` | `lvl_pars.c` |
| `dos-view.c` | `dos-view.c`（正好 8 字符） |
| `dosdefs.h` | `dosdefs.h`（7 字符） |

### 问题 2：TLINK.EXE 找不到

**现象：** TCC 编译成功，链接时报 "不能执行 tlink.exe"。

**原因：** TCC 在链接阶段会调用 TLINK.EXE，但在当前目录和 PATH 中找不到。

**解决：** 在 `build.bat` 中使用 `-L` 参数指定库路径，并确保 PATH 包含 `tc` 目录：

```bat
path c:\tc;%path%
..\tc\tcc -c -ms -I. -I..\tc\include *.c
..\tc\tcc -ms -L..\tc\lib *.obj
```

### 问题 3：链接器找不到启动对象

**现象：** `c0s.obj: unable to open file`。

**原因：** 小型内存模型的启动对象 `c0s.obj` 在 `tc\lib\` 目录下，链接器默认搜索路径不含该目录。

**解决：** 使用 `-L..\tc\lib` 明确指定库路径。

### 问题 4：变参宏不支持

**现象：** `lh.h line 13: macro error`。

**原因：** Turbo C 2.0 不支持 `__VA_ARGS__`（C99 特性）。

**解决：** 移除所有变参宏，直接在源代码中调用 `log_log()`。

### 问题 5：行尾格式

**现象：** `world.h line 1: Unexpected end of file in conditional`。

**原因：** 文件是 Unix LF 行尾，Turbo C 要求 DOS CRLF。

**解决：** 用 Python 脚本将所有 `.c`、`.h` 文件转为 CRLF 格式。

### 问题 6：变量声明位置

**现象：** `log.c` 编译错误。

**原因：** C89 要求在第一个语句之前声明所有局部变量。`time_t t = time(NULL)` 出现在 `lock();` 语句之后。

**解决：** 将函数内所有变量声明移到函数开头。

---

## 三、构建方法

### 前置条件

- DOSBox 0.74-3
- Turbo C 2.0（已预置在 `tc/` 目录中）

### 编译

```bash
# Windows: 双击 start.bat
# 或在 DOSBox 中手动：
Z:\> mount c D:\...\sokoban-dos
C:\> build

# build.bat 依次执行：
# 1. path c:\tc;%path%
# 2. tcc -c -ms -I. -I..\tc\include *.c
# 3. tcc -ms -L..\tc\lib *.obj
# 4. ren world.exe sokoban.exe
```

### 运行

```bash
C:\> sokoban
```

---

## 四、源代码映射

| 原版文件 | DOS 版文件 | 修改说明 |
|----------|-----------|---------|
| `main.c` | `main.c` | 移除 `<unistd.h>`，替换 `error()` 为 `printf+exit` |
| `world.c/h` | `world.c/h` | 未改动（纯 C，无平台依赖） |
| `game-engine.c/h` | `game_eng.c/h` | 未改动（纯 C，无平台依赖） |
| `level-parser.c/h` | `lvl_pars.c/h` | 移除 `<error.h>` 依赖，简化错误处理 |
| `log.c/h` | `log.c/h` | 兼容 C89：变量提前声明，移除变参宏和 ANSI 颜色码 |
| `term-view.c/h` | — | 移除（ncurses 依赖） |
| `sdl-view.c/h` | — | 移除（SDL 依赖） |
| — | `dos-view.c/h` | **新增**：基于 `conio.h` 的 DOS 控制台视图 |
| — | `view.h` | 重写，引用 `dos-view.h` |
| — | `dosdefs.h` | **新增**：定义 `bool`/`true`/`false` |
| `Makefile` | `build.bat` | 重写为 DOS 批处理 |

---

## 五、协议

本项目基于 GPL 协议发布。原始代码版权归 [bravegnu](https://github.com/bravegnu/sokoban) 所有。
