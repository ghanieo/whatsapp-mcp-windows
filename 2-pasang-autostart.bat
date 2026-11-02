@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\2-pasang-autostart.ps1" %*
pause
