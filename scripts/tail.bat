@echo off
REM Usage: tail.bat filename [number_of_lines]

set FILE=%1
set LINES=%2
if "%LINES%"=="" set LINES=10

powershell -Command "Get-Content -Path '%FILE%' -Tail %LINES%"