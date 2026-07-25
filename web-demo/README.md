<p align="center">
  <a href="README.md"><img alt="English" height="30" src="https://img.shields.io/badge/English-3593D2?style=for-the-badge"></a>&nbsp;
  <a href="README.zh-CN.md"><img alt="简体中文" height="30" src="https://img.shields.io/badge/简体中文-7CB342?style=for-the-badge"></a>
</p>

# web-demo — DOS Typing Tutor in Browser

Run **Typing Tutor IV** (1987, PC-TYPE III) online, powered by [js-dos v8](https://js-dos.com/).

## Usage

1. Open the page
2. Click the **▶ play button**
3. Type `tt` at the `C:\>` prompt
4. Start typing practice

## Run

**Online (GitHub Pages):**  
https://weibifan.github.io/msdos/web-demo/

**Locally:**  
```bash
cd web-demo/
python -m http.server 8080
# Open http://localhost:8080
```

## Files

| File | Description |
|------|-------------|
| `index.html` | Main page |
| `tt-bundle.zip` | DOS file bundle (TT.EXE + TT.HLP + TT.HIS + AUTOEXEC.BAT) |
| `TT.EXE` | Main program (99KB) |
| `TT.HLP` | Help file (12KB) |
| `TT.HIS` | Score records (18KB) |
| `AUTOEXEC.BAT` | Auto-start script (backup) |

## Technical Notes

- js-dos v8 loads the zip as a virtual C: drive
- Must manually click play and type `tt` due to js-dos bundle limitations
- Page uses 16:10 container ratio matching DOSBox native resolution
