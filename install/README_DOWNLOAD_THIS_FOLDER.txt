Perceive Install Folder (Flat, No Subfolders)

This folder is intentionally flat.
Do not create nested release subfolders.

Runtime requirement (all platforms):
- MATLAB Runtime R2023a or newer
- No MATLAB license required for end users

-----------------------------------
Windows
-----------------------------------
Files needed for startup GUI:
- perceive_gui_startup.exe
- run_perceive_gui_startup.bat
- detect_matlab_runtime_windows.ps1

Optional:
- MCRInstaller.exe (offline/local Runtime installer)

How to run on Windows:
1) Double-click run_perceive_gui_startup.bat
2) If Runtime is missing, follow prompts
3) Re-run the same launcher

-----------------------------------
macOS / Linux
-----------------------------------
Launcher script:
- run_perceive_gui_startup.sh

Required OS-specific compiled app artifact:
- macOS: perceive_gui_startup.app
- Linux: perceive_gui_startup  (ELF binary)

Important:
- A Windows .exe does NOT run on macOS/Linux.
- Build/package the startup GUI separately on each target OS.

How to run on macOS/Linux:
1) Open Terminal in this folder
2) Run: chmod +x run_perceive_gui_startup.sh
3) Run: ./run_perceive_gui_startup.sh
4) If Runtime is missing, follow prompts and re-run launcher

Troubleshooting:
- runtime_check.log is created next to the launcher
- share runtime_check.log for support
