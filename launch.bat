@echo off
chcp 65001 >nul

echo Launching project at: %~dp0
"C:\Program Files\LOVE\love.exe" %~dp0
pause