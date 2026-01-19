@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: ===================== 配置项（可根据实际情况修改） =====================
set "PROJECT_FOLDER=niannianDisco"  :: 你的love2d项目文件夹名
set "LOVE_FILE_NAME=niannianDisco"  :: 生成的.love和最终exe文件名
set "OUTPUT_FOLDER=打包文件夹"  :: 最终输出的打包文件夹名
set "LOVE_EXE=love.exe"  :: love2d的主程序（需和本bat同目录）
:: 要排除的文件/文件夹（用逗号分隔，支持通配符*）
set "EXCLUDE_LIST=*.log,*.tmp,*.bak,.git,.vscode,__pycache__,temp,debug.txt"
:: ======================================================================

echo ==============================================
echo          LÖVE2D 一键打包脚本（带排除功能）
echo ==============================================
echo 项目文件夹：%PROJECT_FOLDER%
echo 输出文件名：%LOVE_FILE_NAME%
echo 排除内容：%EXCLUDE_LIST%
echo ==============================================

:: 1. 检查必要文件/文件夹
if not exist "%PROJECT_FOLDER%" (
    echo [错误] 项目文件夹 "%PROJECT_FOLDER%" 不存在！
    pause
    exit /b 1
)
if not exist "%LOVE_EXE%" (
    echo [错误] 未找到 %LOVE_EXE%，请将love2d的exe放在本脚本同目录！
    pause
    exit /b 1
)

:: 2. 打包ZIP并排除指定文件（核心：PowerShell排除逻辑）
echo [1/5] 正在打包项目文件（排除指定内容）...
cd /d "%PROJECT_FOLDER%"
:: PowerShell命令：获取所有文件 - 排除指定内容 - 打包为ZIP
powershell -Command "$exclude = @('%EXCLUDE_LIST%'.Split(',')); $files = Get-ChildItem -Path . -Recurse -File | Where-Object { $exclude -notcontains $_.Name -and $exclude -notcontains $_.Extension -and $exclude -notcontains $_.Directory.Name }; Compress-Archive -Path $files.FullName -DestinationPath '../%LOVE_FILE_NAME%.zip' -Force"
cd ..

:: 检查zip是否生成成功
if not exist "%LOVE_FILE_NAME%.zip" (
    echo [错误] zip 文件打包失败！
    pause
    exit /b 1
)

:: 3. 将zip重命名为love
echo [2/5] 正在将zip重命名为.love...
ren "%LOVE_FILE_NAME%.zip" "%LOVE_FILE_NAME%.love" > nul 2>&1
if not exist "%LOVE_FILE_NAME%.love" (
    echo [错误] .love 文件重命名失败！
    pause
    exit /b 1
)
echo [√] .love 文件生成完成！

:: 4. 合并生成exe
echo [3/5] 正在合并生成独立exe...
copy /b "%LOVE_EXE%" + "%LOVE_FILE_NAME%.love" "%LOVE_FILE_NAME%.exe" > nul 2>&1
if not exist "%LOVE_FILE_NAME%.exe" (
    echo [错误] exe 文件合并失败！
    pause
    exit /b 1
)
echo [√] exe 文件生成完成！

:: 5. 删除临时文件
echo [4/5] 正在清理临时文件...
del /f /q "%LOVE_FILE_NAME%.love" > nul 2>&1
echo [√] 临时文件清理完成！

:: 6. 整理打包文件夹
echo [5/5] 正在整理最终打包文件...
:: 创建输出文件夹（覆盖原有）
if exist "%OUTPUT_FOLDER%" (
    rd /s /q "%OUTPUT_FOLDER%" > nul 2>&1
)
md "%OUTPUT_FOLDER%" > nul 2>&1

:: 复制生成的exe
copy /y "%LOVE_FILE_NAME%.exe" "%OUTPUT_FOLDER%\" > nul 2>&1

:: 复制所有dll依赖（love2d运行必需）
for %%f in (*.dll) do (
    copy /y "%%f" "%OUTPUT_FOLDER%\" > nul 2>&1
)

echo ==============================================
echo [成功] 打包完成！
echo 最终文件路径：%cd%\%OUTPUT_FOLDER%
echo ==============================================
pause
endlocal