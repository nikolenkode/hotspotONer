@echo off
setlocal
title Auto Hotspot uninstaller

:: ---- 1. Ask for admin rights if we don't have them ----
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrator rights...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

set "DEST_DIR=C:\ProgramData\AutoHotspot"

:: ---- 2. Stop and remove the scheduled task ----
schtasks /Query /TN "AutoHotspot" >nul 2>&1
if %errorlevel% equ 0 (
    schtasks /End /TN "AutoHotspot" >nul 2>&1
    schtasks /Delete /TN "AutoHotspot" /F >nul 2>&1
    echo Scheduled task "AutoHotspot" removed.
) else (
    echo Scheduled task "AutoHotspot" not found, skipping.
)

:: ---- 3. Make sure no leftover script process is running ----
powershell -NoProfile -Command "Get-CimInstance Win32_Process | Where-Object { $_.Name -eq 'powershell.exe' -and $_.ProcessId -ne $PID -and $_.CommandLine -like '*AutoHotspot\Enable-Hotspot.ps1*' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }"

timeout /t 2 /nobreak >nul

:: ---- 4. Delete installed files ----
if exist "%DEST_DIR%" (
    rmdir /S /Q "%DEST_DIR%"
    echo Folder %DEST_DIR% deleted.
) else (
    echo Folder %DEST_DIR% not found, skipping.
)

echo.
echo Done. Auto Hotspot is removed.
echo Note: the hotspot itself is not turned off. If it is still on,
echo switch it off in Settings ^> Network ^& internet ^> Mobile hotspot.
echo.
pause