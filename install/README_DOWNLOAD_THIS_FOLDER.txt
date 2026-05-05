Perceive Install Folder (Flat, No Subfolders)

This folder is intentionally flat.
Do not create nested release subfolders.

Runtime requirement (all platforms):
- MATLAB Runtime R2023a or newer
- No MATLAB license required for end users

One compiled application entry point: perceive
- Double-click / launcher with no arguments opens the startup GUI (same as perceive_gui_startup).
- Command line: pass JSON paths and options as before (advanced use).

-----------------------------------
Windows
-----------------------------------
Files for the GUI + Runtime check:
- perceive.exe
- run_perceive_gui_startup.bat  (launcher; optional but recommended)
- detect_matlab_runtime_windows.ps1

Optional:
- MCRInstaller.exe (offline/local Runtime installer)

How to run on Windows:
1) Double-click run_perceive_gui_startup.bat, or double-click perceive.exe
2) If Runtime is missing, follow prompts
3) Re-run the same launcher

Advanced (Command Prompt):
  perceive.exe
  perceive.exe "C:\path\Report_Json_Session_Report_....json"
  perceive.exe start

-----------------------------------
macOS / Linux
-----------------------------------
Launcher script:
- run_perceive_gui_startup.sh

Compiled artifact:
- macOS: perceive.app  (double-click or open via launcher)
- Linux: perceive  (ELF binary)

How to run on macOS/Linux:
1) Open Terminal in this folder
2) Run: chmod +x run_perceive_gui_startup.sh
3) Run: ./run_perceive_gui_startup.sh
4) If Runtime is missing, follow prompts and re-run launcher

Advanced (Terminal):
  ./perceive                  (Linux)
  open perceive.app           (macOS)
  ./perceive /path/to/file.json

MATLAB (source toolbox):
  perceive                    (batch: cwd JSON / file picker)
  perceive start              (startup GUI)
  perceive('myfile.json','21', ...)

Troubleshooting:
- runtime_check.log is created next to the launcher
- share runtime_check.log for support
