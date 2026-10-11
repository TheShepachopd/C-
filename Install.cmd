@echo off
setlocal
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -STA -File "%~dp0Install.ps1"
set "installExitCode=%ERRORLEVEL%"
if not "%installExitCode%"=="0" (
    echo.
    echo Installation could not be completed. See the error message above.
    pause
)
exit /b %installExitCode%
