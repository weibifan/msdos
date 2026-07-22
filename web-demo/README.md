# web-demo — Online DOS Demo

This directory contains an in-browser demo of **Typing Tutor IV** powered by [js-dos v8](https://js-dos.com/).

## How to run

**Online (GitHub Pages):**  
https://weibifan.github.io/msdos/web-demo/

**Locally:**  
```bash
npx serve web-demo/
# or
python -m http.server 8080 -d web-demo/
```
Then open http://localhost:8080.

## Files

| File | Description |
|------|-------------|
| `index.html` | Demo page with embedded js-dos emulator |
| `TT.EXE` | Typing Tutor IV executable |
| `TT.HLP` | Help file |
| `TT.HIS` | History/scores file |

## How it works

The HTML loads js-dos from CDN, mounts the current directory as `C:\` via `mount c .`, and auto-runs `TT.EXE` through `dosboxConf`.
