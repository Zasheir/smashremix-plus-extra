@echo off
setlocal enabledelayedexpansion

REM Collect folder names
set "FOLDERS="
for /D %%F in (extra_characters\*) do (
    if defined FOLDERS (
        set "FOLDERS=!FOLDERS!, %%~nxF"
    ) else (
        set "FOLDERS=%%~nxF"
    )
)

echo Available options:
echo !FOLDERS!

REM Prompt for folder name
set /p FOLDERNAME="Type the character to inject: "

REM Check if folder exists
if not exist "extra_characters\%FOLDERNAME%\" (
    echo Folder "extra_characters\%FOLDERNAME%\" does not exist.
    @echo %cmdcmdline%|find /i """%~f0""">nul && pause
    exit /b 1
)

REM Collect and pass extra arguments
set "ARGS="
:collect_args
shift
if "%~1"=="" goto after_args
set "ARGS=%ARGS% %~1"
goto collect_args
:after_args

REM Run original build.bat with argument
call build.bat --single_character "%FOLDERNAME%" %ARGS%
if errorlevel 1 (
    @echo %cmdcmdline%|find /i """%~f0""">nul && pause
    exit /b 1
)
