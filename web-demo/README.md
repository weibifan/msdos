# web-demo — 浏览器版 DOS 打字练习

在线运行 **Typing Tutor IV**（1987，PC-TYPE III），基于 [js-dos v8](https://js-dos.com/)。

## 使用方法

1. 打开页面
2. 点击中间的 **▶ 播放按钮**
3. 在 `C:\>` 提示符输入 **`tt`** 回车
4. 开始打字练习 🎮

## 运行

**在线 (GitHub Pages):**  
https://weibifan.github.io/msdos/web-demo/

**本地:**  
```bash
cd web-demo/
python -m http.server 8080
# 打开 http://localhost:8080
```

## 文件说明

| 文件 | 描述 |
|------|------|
| `index.html` | 主页面 |
| `tt-bundle.zip` | DOS 文件包（TT.EXE + TT.HLP + TT.HIS + AUTOEXEC.BAT）|
| `TT.EXE` | 主程序 (99KB) |
| `TT.HLP` | 帮助文件 (12KB) |
| `TT.HIS` | 成绩记录 (18KB) |
| `AUTOEXEC.BAT` | 自动启动脚本（备用） |

## 技术说明

- js-dos v8 将 zip 加载为虚拟 C: 盘
- 由于 js-dos 对自定义 bundle 的限制，需手动点击播放按钮和输入 `tt`
- 页面使用 16:10 容器比例匹配 DOSBox 原生分辨率
