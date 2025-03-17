@echo off
setlocal enabledelayedexpansion

cd ..\dependencies
call universal-parameters.bat
cd ..\uninstall

:: Define paths using environment variables for user-specific directories
set "uninstallPath=%USERPROFILE%\AppData\Local\Bat-Files\Youtube-Downloader\uninstall\uninstall.bat"
set "startMenuShortcut=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Bat-Files\Youtube-Downloader.lnk"
set "appName=Youtube-Downloader"
set "iconPath=%USERPROFILE%\AppData\Local\Bat-Files\Youtube-Downloader\icon.ico"

:: Step 1: Register uninstaller in the registry for "Apps & Features"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\%appName%" /v "DisplayName" /t REG_SZ /d "%appName%" /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\%appName%" /v "UninstallString" /t REG_SZ /d "\"%uninstallPath%\"" /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\%appName%" /v "QuietUninstallString" /t REG_SZ /d "\"%uninstallPath%\"" /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\%appName%" /v "Publisher" /t REG_SZ /d "BenignPigeon" /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\%appName%" /v "DisplayIcon" /t REG_SZ /d "%iconPath%" /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\%appName%" /v "NoModify" /t REG_DWORD /d "1" /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\%appName%" /v "NoRepair" /t REG_DWORD /d "1" /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\%appName%" /v "DisplayVersion" /t REG_SZ /d "%programVersion%" /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\%appName%" /v "EstimatedSize" /t REG_DWORD /d 9705 /f

echo Uninstaller registered.
exit /b
