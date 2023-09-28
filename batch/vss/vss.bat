:: Generate & mount/unmount a read-only VSC image
:: Requires vshadow.exe to be in PATH or current path

:: env
@echo off
setlocal EnableExtensions EnableDelayedExpansion

>nul 2>&1 net session
if errorlevel neq 0 (
	1>&2 echo %~nx0 requires administrator priviledges
	exit /b 1
)

if defined _callback (
	call :callback
) else if /i "%~1"=="--cu" (
	call :cleanup
)

call :main
exit /b

:main
	set "_src=!SYSTEMDRIVE!"
	set "_dst=!VSS!:"
	set "_callback=%~dpnx0"
	set "_tmp=!TMP!\vsstmp.cmd"

	pushd "%~dp0" || exit /b 1
	vshadow.exe -script="!_tmp!" -exec "!_callback!" -p "!_src!"
	del /f "!_tmp!"
	popd
exit /b

:cleanup
	pushd "%~dp0"
	for /f "Tokens=1*" %%a in ('type "%TEMP%\%USERNAME%_vss.id") do (
		echo y | vshadow.exe -ds="%%~a"
	)
	del /f "%TEMP%\%USERNAME%_vss.id"
	popd
exit /b

:callback
	setlocal
	pushd "%~dp0"
	call "%_tmp%"
	vshadow.exe -el="%SHADOW_ID_!%,%_dst%"
	> "%TEMP%\%USERNAME%_vss.id" echo %SHADOW_ID_1%
	popd
exit /b