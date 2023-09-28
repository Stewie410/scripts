:: Pad out animation frame(s) for osu!skins

@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "callers=%~nx0"

:: run
call :func :main %* || exit /b 1
exit /b 0

:func <label> [arg [arg ...]]
    set "callers=%1`!callers!"
    call %*
    set "callers=!callers:*`=!"
exit /b

:main
	set "defaults[type]=png"
	set "defaults[basename]=animation"
	set "defaults[iframes]=1"
	set "defaults[offset]=2"

	set "settings[type]=!defaults[type]!"
	set "settings[path]=!defaults[path]!"
	set "settings[iframes]=!defaults[iframes]!"
	set "settings[offset]=!defaults[offset]!"

    set "_gather="
    set "remaining="

    for %%a in (%*) do (
        if defined remaining (
            set "remaining=!remaining! %%a"
        ) else if defined _gather (
            set "!_gather!=%%~a"
            set "_gather"
        ) else (
            set "_"="%%~a"
            if "!_!"=="--" (
                set "remaining= "
            ) else if "!_:~0,2!"=="--" (
                set "_=!_:~2!"
                if "!_!"=="help" (
                    call :show_help
                    exit /b 0
                ) else if "!_!"=="type" (
					set "_gather=settings[type]"
				) else if "!_!"=="basename" (
					set "_gather=settings[basename]"
				) else if "!_!"=="initial-frames" (
					set "_gather=settings[iframes]"
				) else if "!_!"=="offset" (
					set "_gather=settings[offset]"
				) else if "!_!"=="@2x" (
					set "settings[2x]=1"
				)
            ) else if "!_:~0,1!"=="-" (
                set "_=!_:~1!"
                if "!_!"=="h" (
                    call :show_help
                    exit /b 0
                ) else if "!_!"=="t" (
					set "_gather=settings[type]"
				) else if "!_!"=="b" (
					set "_gather=settings[basename]"
				) else if "!_!"=="i" (
					set "_gather=settings[iframes]"
				) else if "!_!"=="o" (
					set "_gather=settings[offset]"
				) else if "!_!"=="2" (
					set "settings[2x]=1"
				)
            ) else (
                1>&2 echo(ERROR: Unexpected argument: %%~a
            )
        )
    )
    set "_gather="

	if "!settings[type]:~0,1!"=="." set "settings[type]=!settings[type]:~1!"
	if "!settings[offset]:~0,1!"=="-" set "settings[offset]=!settings[offset]:~1!"
	if "!settings[iframes]:~0,1!"=="-" set "settings[iframes]=!settings[iframes]:~1!"

	:: validate
	if "!remaining:~2!."=="." (
		1>&2 call :log No animation path specified
		exit /b 1
	) else (
		set "settings[path]=!remaining:~2!"
	)

	if "!settings[path]:~-1!"=="\" (
		set "settings[path]=!settings[path]:~0,-1!"
	)

	if "!settings[type]:~0,1!"=="." (
		set "settings[type]=!settings[type]:~1!"
	)

	call :validate_settings || exit /b 1
	call :func :find_and_pad
exit /b

:log <message>
    for /F "delims=`" %%a in ("!callers!") do set "_name=%%a"
    echo(!name:~0,20!^|%*
exit /b

:show_help
    echo(Pad out animation frame(s) for osu!skins
    echo(
    echo(USAGE: %~nx0 [OPTIONS] PATH
    echo(
    echo(OPTIONS:
    echo(    -h, --help					Show this help message
	echo(	 -2, --@2x					Include animation files with the "@2x" suffix
	echo(    -b, --basename NAME		Specify the basename of the animation file(s)
	echo(								(default: !defaults[basename]!)
	echo(    -t, --type EXTENSION		Specify the animation extension
	echo(								(default: !defaults[type]!)
	echo(    -i, --initial-frames NUM	Specify the current/initial number of frames
	echo(								(default: !defaults[iframes])
	echo(    -o, --offset NUM			Specify the numer of offset for padding
	echo(    							To duplicate the existing frames, offset should be 2
	echo(    							(default: !defaults[offset]!)
exit /b

:validate_settings
	if not exist "!settings[path]!\" (
		1>&2 call :log Cannot locate animation path: !settings[path]!
		exit /b 1
	)

	set /a "found=0"
	for /f %%f in ('dir /b "!settings[path]!\!settings[basename]!*.!settings[type]!"') do (
		set /a "found=!found!+1"
	)
	if found lss 1 (
		1>&2 call :log Cannot locate animation frame(s): !settings[path]!\!settings[basename]!*.!settings[type]!
	)
	set "found="

	if !settings[offset]! leq 2 (
		1>&2 call :log Offset must be at least 2
		exit /b 1
	)

	if !settings[iframes]! lss 1 (
		1>&1 call :log Must be at least 1 frame
	)
exit /b

:find_and_pad
	pushd "!settings[path]!" || exit /b 1
	call :func :space_files ".!settings[type]!"
	call :func :dupe_files ".!settings[type]!"
	if defined settings[2x] (
		call :func :space_files "@2x.!settings[type]!"
		call :func :dupe_files "@2x.!settings[type]!"
	)
	popd || exit /b 1
exit /b 0

:space_files <suffix>
	for /l %%i in (!settings[iframes]!, -1, 0) do (
		set /a offset=i * settings[offset]
		>nul 2>&1 ren "!settings[basename]!-%%i%~2" "!settings[basename]!-!offset!%~2"
	)
exit /b 0

:dupe_files <extension>
	set /a final_count=settings[iframes] * settings[offset] - 2
	for /l %%i in (0, 1, !final_count!) do (
		if exist "!settings[basename]!-%%i%~2" (
			set /a offset=%%i + 1
			if not exist "!settings[basename]!-!offset!%~2" (
				>nul 2>&1 copy /y "!settings[basename]!-%%i%~2" "!settings[basename]!-!offset!%~2"
			)
		)
	)
exit /b