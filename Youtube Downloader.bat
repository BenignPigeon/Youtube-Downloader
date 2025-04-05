@echo off
setlocal EnableDelayedExpansion

:: Step 1: Check if yt-dlp is installed
where yt-dlp >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo yt-dlp not found. Installing using winget...
    winget install yt-dlp -e --silent
    if %ERRORLEVEL% EQU 0 (
        echo yt-dlp successfully installed.
    ) else (
        echo Failed to install yt-dlp.
        pause
        exit /b
    )
) 

cd dependencies
call universal-parameters.bat
cd ..
:: Check if %APPDATA%\Bat-Files exists, create if it doesn't
if not exist "%APPDATA%\Bat-Files" (
    echo Directory "%APPDATA%\Bat-Files" does not exist. Creating now...
    mkdir "%APPDATA%\Bat-Files"
) 
:: Check if %APPDATA%\Bat-Files\YouTube-Downloader exists, create if it doesn't
if not exist "%APPDATA%\Bat-Files\YouTube-Downloader" (
    echo Directory "%APPDATA%\Bat-Files\YouTube-Downloader" does not exist. Creating now...
    mkdir "%APPDATA%\Bat-Files\YouTube-Downloader"
)

rem Load settings if they exist
set "use_cookies=0"
set "browser_choice="
set "cookie_file="
set "output_enabled=1"
set "output_path=%USERPROFILE%\Desktop"
set "video_format=mp4"
set "audio_format=mp3"
if exist "%config_file%" (
    for /f "usebackq tokens=1,* delims==" %%a in ("%config_file%") do (
        if "%%a"=="use_cookies" set "use_cookies=%%b"
        if "%%a"=="browser_choice" set "browser_choice=%%b"
        if "%%a"=="cookie_file" set "cookie_file=%%b"
        if "%%a"=="output_enabled" set "output_enabled=%%b"
        if "%%a"=="output_path" set "output_path=%%b"
        if "%%a"=="video_format" set "video_format=%%b"
        if "%%a"=="audio_format" set "audio_format=%%b"
    )
)

:menu
cls
echo YouTube Downloader
echo ================
echo 1. Download Video (%video_format%)
echo 2. Download Audio (%audio_format%)
echo 3. Download Subtitles (srt)
echo 4. Settings
echo 5. Exit
echo.

if "%output_enabled%"=="1" (
    echo Dowloading to: %output_path%
) else (
    echo Custom output path is disabled. Downloading to same directory as the bat file.
)
if "%use_cookies%"=="1" (
    if defined browser_choice (
        echo Status: Using cookies from: %browser_choice%
    ) else if defined cookie_file (
        echo Status: Using cookies from file: %cookie_file%
    )
) else (
    echo Status: Not using cookies
)
echo.

set "choice="
set /p "choice=Enter your choice (1-5): "

if not defined choice goto invalid_choice
if "%choice%"=="5" exit /b
if "%choice%"=="4" goto settings

if "%choice%"=="1" (
    set "format=video"
    rem Set command based on selected video format
    if "%video_format%"=="mp4" (
        set "command=--merge-output-format mp4"
    ) else if "%video_format%"=="mkv" (
        set "command=--merge-output-format mkv"
    ) else if "%video_format%"=="mov" (
        set "command=--recode-video mov"
    ) else if "%video_format%"=="webm" (
        set "command=--merge-output-format webm"
    ) else if "%video_format%"=="avi" (
        set "command=--recode-video avi"
    )
) else if "%choice%"=="2" (
    set "format=audio"
    rem Set command based on selected audio format
    if "%audio_format%"=="mp3" (
        set "command=-f bestaudio --extract-audio --audio-format mp3"
    ) else if "%audio_format%"=="wav" (
        set "command=-f bestaudio --extract-audio --audio-format wav"
    ) else if "%audio_format%"=="aac" (
        set "command=-f bestaudio --extract-audio --audio-format aac"
    ) else if "%audio_format%"=="m4a" (
        set "command=-f bestaudio --extract-audio --audio-format m4a"
    ) else if "%audio_format%"=="ogg" (
        set "command=-f bestaudio --extract-audio --audio-format vorbis"
    )
) else if "%choice%"=="3" (
    set "format=subtitles"
    set "command=--write-subs --write-auto-subs --sub-format srt --sub-langs en --skip-download --convert-subs srt"
) else (
    goto invalid_choice
)

:get_link
cls
echo Download YouTube %format%
echo ======================
set "ytlink="
set /p "ytlink=Paste YouTube link (or type 'back' to return to menu): "

if not defined ytlink (
    echo Error: No link provided.
    timeout /t 2 >nul
    goto get_link
)

if /i "%ytlink%"=="back" goto menu

:download
rem Set output directory
if "%output_enabled%"=="1" (
    set "output_dir=%output_path%"
) else (
    set "output_dir=%USERPROFILE%\Desktop"
)

cd /d "%output_dir%"
echo.
echo Downloading to: %output_dir%
echo.

if "%choice%"=="3" (
    echo Attempting to download subtitles...
    echo Note: Will try official subtitles first, then auto-generated if none available.
    echo.
)

if "%use_cookies%"=="1" (
    if defined browser_choice (
        yt-dlp --cookies-from-browser %browser_choice% %command% "%ytlink%"
    ) else if defined cookie_file (
        yt-dlp --cookies "%cookie_file%" %command% "%ytlink%"
    )
) else (
    yt-dlp %command% "%ytlink%"
)

if errorlevel 1 (
    echo.
    echo Download failed. Please check your link and internet connection.
    echo Press any key to try again...
    pause >nul
    goto get_link
) else (
    echo.
    echo Download completed successfully!
    if "%choice%"=="3" (
        echo If no subtitles were found, either the video has no subtitles
        echo or they might be embedded in the video itself.
    )
    echo Press any key to return to menu...
    pause >nul
    goto menu
)

:save_settings
(
    echo use_cookies=%use_cookies%
    echo browser_choice=%browser_choice%
    echo cookie_file=%cookie_file%
    echo output_enabled=%output_enabled%
    echo output_path=%output_path%
    echo video_format=%video_format%
    echo audio_format=%audio_format%
) > "%config_file%"
goto :eof

:settings
cls
echo Settings
echo ========
echo 1. About Project
echo 2. Report Issue
echo 3. Cookie Settings
echo 4. Output Settings
echo 5. Video Format Settings
echo 6. Audio Format Settings
echo 7. Update YouTube Downloader to Latest Version
echo 8. Back to Main Menu
echo.

:settings_loop
set /p "settings_choice=Enter your choice (1-7): "

if "%settings_choice%"=="1" goto about
if "%settings_choice%"=="2" goto report_issue
if "%settings_choice%"=="3" goto cookie_settings
if "%settings_choice%"=="4" goto output_settings
if "%settings_choice%"=="5" goto video_format_settings
if "%settings_choice%"=="6" goto audio_format_settings
if "%settings_choice%"=="7" (
    @echo off
    start cmd /c powershell "irm '%programUpdater%' |iex"
    exit
)
if "%settings_choice%"=="8" goto menu

echo Invalid choice. Please try again.
timeout /t 2 >nul
goto settings_loop

:video_format_settings
cls
echo Video Format Settings
echo ====================
echo 1. MP4 (MPEG-4 Part 14)
echo 2. MKV (Matroska Video File)
echo 3. MOV (Apple QuickTime Movie)
echo 4. WEBM (Web Media File)
echo 5. AVI (Audio Video Interleave)
echo 6. Back to settings
echo.
echo Current Video Format: %video_format%
echo.

:video_format_loop
set /p "format_choice=Enter your choice (1-6): "

if "%format_choice%"=="1" (
    set "video_format=mp4"
    echo Video format set to: mp4
    echo.
) else if "%format_choice%"=="2" (
    set "video_format=mkv"
    echo Video format set to: mkv
    echo.
) else if "%format_choice%"=="3" (
    set "video_format=mov"
    echo Video format set to: mov
    echo.
) else if "%format_choice%"=="4" (
    set "video_format=webm"
    echo Video format set to: webm
    echo.
) else if "%format_choice%"=="5" (
    set "video_format=avi"
    echo Video format set to: avi
    echo.
) else if "%format_choice%"=="6" (
    goto settings
) else (
    echo Invalid choice. Please try again.
    goto video_format_loop
)

call :save_settings
goto video_format_loop

:audio_format_settings
cls
echo Audio Format Settings
echo ====================
echo 1. MP3 (MPEG-1 Audio Layer 3)
echo 2. WAV (Waveform Audio File Format)
echo 3. AAC (Advanced Audio Codec)
echo 4. M4A (MPEG-4 Audio)
echo 5. OGG (Ogg Vorbis)
echo 6. Back to settings
echo.
echo Current Audio Format: %audio_format%
echo.

:audio_format_loop
set /p "format_choice=Enter your choice (1-6): "

if "%format_choice%"=="1" (
    set "audio_format=mp3"
    echo Audio format set to: mp3
    echo.
) else if "%format_choice%"=="2" (
    set "audio_format=wav"
    echo Audio format set to: wav
    echo.
) else if "%format_choice%"=="3" (
    set "audio_format=aac"
    echo Audio format set to: aac
    echo.
) else if "%format_choice%"=="4" (
    set "audio_format=m4a"
    echo Audio format set to: m4a
    echo.
) else if "%format_choice%"=="5" (
    set "audio_format=ogg"
    echo Audio format set to: ogg
    echo.
) else if "%format_choice%"=="6" (
    goto settings
) else (
    echo Invalid choice. Please try again.
    goto audio_format_loop
)

call :save_settings
goto audio_format_loop

:cookie_settings
cls
echo Cookie Settings
echo ==============
echo 1. Toggle cookie usage
echo 2. Select browser for cookies
echo 3. Set cookie file path
echo 4. Back to settings
echo.
echo Current Status: 
if "%use_cookies%"=="1" (
    if defined browser_choice (
        echo Currently using cookies from: %browser_choice%
    ) else if defined cookie_file (
        echo Currently using cookies from file: %cookie_file%
    )
) else (
    echo Not using cookies
)
echo.

:cookie_settings_loop
set /p "cookie_choice=Enter your choice (1-4): "

if "%cookie_choice%"=="1" (
    if "%use_cookies%"=="1" (
        set "use_cookies=0"
        echo Cookies Disabled
        echo.
    ) else (
        if not defined browser_choice if not defined cookie_file (
            echo Please select a browser or set a cookie file first.
            goto cookie_settings
        )
        set "use_cookies=1"
        if defined browser_choice (
            echo Cookies Enabled. Currently using cookies from: %browser_choice%
            echo.
        ) else (
            echo Cookies Enabled. Currently using cookies from file: %cookie_file%
            echo.
        )
    )
    call :save_settings
    goto cookie_settings_loop
)

if "%cookie_choice%"=="2" (
    set "cookie_file="
    goto select_browser
)

if "%cookie_choice%"=="3" (
    set "browser_choice="
    goto set_cookie_file
)

if "%cookie_choice%"=="4" (
    goto settings
)

echo Invalid choice. Please try again.
echo.
goto cookie_settings_loop

:output_settings
cls
echo Output Settings
echo ==============
echo 1. Enable/Disable custom output path
echo 2. Set output path
echo 3. Back to settings
echo.
echo Current Status: 
if "%output_enabled%"=="1" (
    echo Custom output path is enabled: %output_path%
) else (
    echo Custom output path is disabled. Default path is the same directory as the BAT file.
)
echo.

:output_settings_loop
set /p "output_choice=Enter your choice (1-3): "

if "%output_choice%"=="1" (
    if "%output_enabled%"=="1" (
        set "output_enabled=0"
        echo Custom output path disabled. Default path will be used.
        echo.
    ) else (
        if not defined output_path (
            echo Please set an output path first.
            goto output_settings
        )
        set "output_enabled=1"
        echo Custom output path enabled: %output_path%
        echo.
    )
    call :save_settings
    goto output_settings_loop
)

if "%output_choice%"=="2" (
    goto set_output_path
)

if "%output_choice%"=="3" (
    goto settings
)

echo Invalid choice. Please try again.
echo.
goto output_settings_loop

:set_output_path
cls
echo Set Output Path
echo ==============
echo Enter the full path to the output directory
echo Example: C:\Path\To\Output
echo Tip: You can paste the path copied from Windows Explorer
echo Type 'back' to return to settings
echo.
set /p "input_path=Output path: "

if /i "%input_path%"=="back" goto output_settings

rem Remove quotes if present
set "output_path=%input_path:"=%"

rem Check if directory exists
if not exist "!output_path!" (
    echo Error: Directory not found: !output_path!
    set "output_path="
    echo Press any key to try again...
    pause >nul
    goto set_output_path
)

echo Output path set successfully to: !output_path!
call :save_settings
echo Press any key to return to settings...
pause >nul
goto output_settings

:select_browser
cls
echo Select Browser for Cookies
echo =========================
echo 1. Chrome (Legacy)
echo 2. Firefox
echo 3. Edge (Legacy)
echo 4. Back to settings
echo.

:select_browser_loop
set /p "browser_input=Enter your choice (1-4): "

if "%browser_input%"=="1" (
    set "browser_choice=chrome"
    echo Browser set to: !browser_choice!
    call :save_settings
    goto select_browser_loop
) else if "%browser_input%"=="2" (
    set "browser_choice=firefox"
    echo Browser set to: !browser_choice!
    call :save_settings
    goto select_browser_loop
) else if "%browser_input%"=="3" (
    set "browser_choice=edge"
    echo Browser set to: !browser_choice!
    call :save_settings
    goto select_browser_loop
) else if "%browser_input%"=="4" (
    goto cookie_settings
) else (
    echo Invalid choice. Please try again.
    echo.
    goto select_browser_loop
)

:set_cookie_file
cls
echo Set Cookie File Path
echo ===================
echo Enter the full path to your cookies file
echo Example: C:\Path\To\cookies.txt
echo Tip: You can paste the path copied from Windows Explorer
echo Type 'back' to return to settings
echo.
set /p "input_path=Cookie file path: "

if /i "%input_path%"=="back" goto cookie_settings

rem Remove quotes if present
set "cookie_file=%input_path:"=%"

rem Check if file exists
if not exist "!cookie_file!" (
    echo Error: File not found: !cookie_file!
    set "cookie_file="
    echo Press any key to try again...
    pause >nul
    goto set_cookie_file
)

echo Cookie file set successfully to: !cookie_file!
call :save_settings
echo Press any key to return to settings...
pause >nul
goto cookie_settings

:invalid_choice
echo.
echo Invalid choice. Please try again...
echo.
timeout /t 2 >nul
goto menu

:about
@echo off
cls
echo -----------------------------------------------------
echo           YOUTUBE DOWNLOADER - DOWNLOAD VIDEOS
echo -----------------------------------------------------
echo Author      : BenignPigeon
echo Version     : %programVersion%
echo GitHub      : https://github.com/BenignPigeon/Youtube-Downloader
echo -----------------------------------------------------
echo DESCRIPTION:
echo This tool allows you to download videos and audio from YouTube 
echo and other websites, with support for various formats, including:
echo - Video  : MP4, MKV, MOV, WEBM
echo - Audio  : MP3, M4A
echo -----------------------------------------------------
echo DEPENDENCIES:
echo This tool makes use of the following open-source software:
echo.
echo - yt-dlp (The most advanced youtube-dl fork) ^| - Python (PSF License)
echo - Icon: Papirus Dev Team (Iconpack)          ^| - Papirus Apps Icons
echo.
echo All credit goes to the respective developers and projects.
echo -----------------------------------------------------
echo Thank you for using YouTube Downloader! 
echo Created with care and plenty of echo statements.
echo.
echo Buy me a coffee at: https://buymeacoffee.com/benignpigeon
echo -----------------------------------------------------
pause
goto settings

:report_issue
::ADD ACTUAL GITHUB
start https://github.com/BenignPigeon/Youtube-Downloader/issues
goto settings
:comments

Features that should be added:

 1. Settings for Thumbnail Download
   - Allow the user to download video thumbnails.
   - Example:
     batch
     yt-dlp --write-thumbnail
     
 2. Settings for Metadata Embedding
   - Add an option to embed metadata (e.g., title, artist, etc.) into the downloaded file.
   - Example:
     batch
     yt-dlp --add-metadata
