@echo off
setlocal EnableExtensions EnableDelayedExpansion

>nul 2>&1 net session
if errorlevel eq 0 exit /b 0

set "vbs=%TEMP%\getadmin.vbs"

> "!vbs!" echo(Set UAC = CreateObject^("Shell.Application"^)
>> "!vbs!" echo(UAC.ShellExecute "%~s0", "", "", "runas", 1

call "!vbs!"
exit /b