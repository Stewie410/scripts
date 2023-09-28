:: description

:: env
@echo off
setlocal EnableExtensions EnableDelayedExpansion

:: globals
set "callers=%~nx0"

:: run
call :func :main %*
if not "!err!."=="." (
    call :func :notify "!err!"
    exit /b 1
)
exit /b 0

:: infrastructure
:func <label> [arg [arg ...]]
    set "callers=%1`!callers!"
    call %*
    set "callers=!callers:*`=!"
exit /b

:main
    set "_gather="
    set "remaining="

	set "action=all"

    for %%a in (%*) do (
        if defined remaining (
            set "remaining=!remaining! %%a"
        ) else if defined _gather (
            set "!_gather!=%%~a"
            set "_gather"
        ) else (
            set "_"="%%~a"
            if "!_!"=="--" (
                set "remaining="
            ) else if "!_:~0,2!"=="--" (
                set "_=!_:~2!"
                if "!_!"=="help" (
                    call :show_help
                    exit /b 0
                ) else if "!_!"=="winsock" (
					set "action=winsock"
				) else if "!_!"=="tcp" (
					set "action=tcp"
				) else if "!_!"=="ip" (
					set "action=ip"
				) else if "!_!"=="all" (
					set "action=all"
				)
            ) else if "!_:~0,1!"=="-" (
                set "_=!_:~1!"
                if "!_!"=="h" (
                    call :show_help
                    exit /b 0
                ) else if "!_!"=="w" (
					set "action=winsock"
				) else if "!_!"=="t" (
					set "action=tcp"
				) else if "!_!"=="i" (
					set "action=ip"
				) else if "!_!"=="a" (
					set "action=all"
				)
            ) else (
                1>&2 echo(ERROR: Unexpected argument: %%~a
            )
        )
    )
    set "_gather="

	call :is_admin
	if errorlevel neq 0 (
		call :log %~nx0 requires administrator priviledges
		exit /b 1
	)

	if "!action!"=="winsock" (
		call :func :reset_winsock
	) else if "!action!"=="tcp" (
		call :func :reset_tcp
	) else if "!action!"=="ip" (
		call :func :reset_ip
	) else (
		call :func :reset_winsock
		call :func :reset_tcp
		call :func :reset_ip
	)
exit /b 0

:log <message>
    for /F "delims=`" %%a in ("!callers!") do set "_name=%%a"
    echo(!name:~0,20!^|%*
exit /b

:show_help
    echo(description
    echo(
    echo(USAGE: %~nx0 [OPTIONS]
    echo(
    echo(OPTIONS:
    echo(    -h, --help                	Show this help message
	echo(	 -w, --winsock				Reset Windows Socket service
	echo(	 -t, --tcp					Reset TCP service
	echo(	 -i, --ip					Reset IP service
	echo(	 -a, --all					Reset Wisock, TCP & IP service (default)
exit /b

:is_admin
	>nul 2>&1 net session
exit /b

:reset_winsock
	netsh winsock reset
exit /b

:reset_tcp
	netsh int tcp reset
exit /b

:reset_ip
	netsh int ip reset
exit /b