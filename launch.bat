@echo off
chcp 65001 >nul

:: 输出当前脚本所在路径
echo Launching project at: %~dp0

:: 拼接上一级目录路径（%~dp0是当前脚本路径，..\表示上一级）
set "LOVE_PATH=%~dp0..\love.exe"

:: 检查上一级目录是否存在love.exe
if exist "%LOVE_PATH%" (
    echo Found love.exe at: %LOVE_PATH%
    :: 启动love.exe并加载当前项目
    "%LOVE_PATH%" %~dp0
) else (
    :: 如果上一级没有找到，给出提示
    echo Error: love.exe not found in the parent directory!
    echo Expected path: %LOVE_PATH%
    pause
    exit /b 1
)

pause