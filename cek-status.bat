@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\cek-status.ps1" %*
pause
