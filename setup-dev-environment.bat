@echo off
REM Batch file wrapper to run PowerShell script with execution policy bypass
REM Usage: setup-dev-environment.bat [step]
REM Examples:
REM   setup-dev-environment.bat                    - Run all steps
REM   setup-dev-environment.bat backend             - Run only backend
REM   setup-dev-environment.bat mysql,backend       - Run multiple steps
REM Available steps: checkout, mysql, backend, frontend, transcriber, transcriber-new

echo Starting PrevCare Fullstack Dev Environment Setup...
echo.

if "%1"=="" (
    PowerShell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0setup-dev-environment.ps1"
) else (
    PowerShell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0setup-dev-environment.ps1" -Step "%1"
)

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Script encountered an error. Check the output above for details.
    pause
    exit /b %ERRORLEVEL%
)
pause

