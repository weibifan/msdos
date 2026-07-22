# web-demo — Online DOS Demo

This directory contains an in-browser demo of **Typing Tutor IV** powered by [js-dos v8](https://js-dos.com/).

## How to run

### Option 1: Local server (recommended)

```bash
npx serve web-demo/
# or
python -m http.server 8080 -d web-demo/
```

Then open http://localhost:8080 in your browser.

### Option 2: Open directly

Open `index.html` in your browser (may not work due to CORS on some browsers).

## Files

| File | Description |
|------|-------------|
| `index.html` | Demo page with embedded js-dos emulator |
| `tt-bundle.jsdos` | js-dos bundle (TT.EXE + config) |

## How it works

The `.jsdos` file is a standard ZIP archive containing:

```
.jsdos/dosbox.conf   — DOSBox configuration with autoexec to launch TT.EXE
TT.EXE               — Typing Tutor IV executable
TT.HLP               — Help file
TT.HIS               — History/scores file
```

The HTML page loads the [js-dos](https://js-dos.com/) library from CDN and launches the bundle.
