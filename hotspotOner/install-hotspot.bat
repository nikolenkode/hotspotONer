@echo off
setlocal
title Auto Hotspot installer

:: ---- 1. Ask for admin rights if we don't have them ----
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrator rights...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

set "SRC=%~dp0Enable-Hotspot.ps1"
set "DEST_DIR=C:\ProgramData\AutoHotspot"
set "DEST=%DEST_DIR%\Enable-Hotspot.ps1"

if not exist "%SRC%" (
    echo ERROR: Enable-Hotspot.ps1 must be in the same folder as this .bat file.
    pause
    exit /b 1
)

:: ---- 2. Copy script ----
if not exist "%DEST_DIR%" mkdir "%DEST_DIR%"
copy /Y "%SRC%" "%DEST%" >nul
echo Script copied to %DEST%

:: ---- 3. Register scheduled task (at logon, highest privileges, auto-restart) ----
powershell -NoProfile -ExecutionPolicy Bypass -Command "$a = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File C:\ProgramData\AutoHotspot\Enable-Hotspot.ps1'; $t = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME; $s = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RestartCount 999 -RestartInterval (New-TimeSpan -Minutes 1) -ExecutionTimeLimit ([TimeSpan]::Zero) -MultipleInstances IgnoreNew; $p = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest; Register-ScheduledTask -TaskName 'AutoHotspot' -Action $a -Trigger $t -Settings $s -Principal $p -Force | Out-Null"

if %errorlevel% neq 0 (
    echo ERROR: failed to create the scheduled task.
    pause
    exit /b 1
)
echo Scheduled task "AutoHotspot" created.

:: ---- 4. Start it right now ----
schtasks /Run /TN "AutoHotspot" >nul 2>&1
echo.
echo Done. The hotspot will now be enabled at every logon and kept ON.
echo Log file: %DEST_DIR%\hotspot.log
echo To remove: schtasks /Delete /TN "AutoHotspot" /F
echo.
pause
