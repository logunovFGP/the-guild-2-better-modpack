
SETLOCAL
@echo off 

IF NOT EXIST GuildII.exe (
	cd ..
	IF NOT EXIST GuildII.exe (
		echo Could not find GuildII.exe in this folder or parent folder. Abort.
		pause
		exit
	)
	echo Found GuildII.exe in parent folder.
)

WHERE git >nul 2>nul
IF %ERRORLEVEL% NEQ 0 (
	echo This installer requires a functioning GIT client. 
	echo https://git-scm.com/download
	echo GIT could be installed by the windows package manager.
	echo Install GIT-Client [y/n]?
	SET /P installwingit=""
)
IF "%installwingit%"=="y" (
	echo Installing... When done, restart the installer to continue.
	winget install --id Git.Git -e --source winget
	exit
)

WHERE git >nul 2>nul
IF %ERRORLEVEL% NEQ 0 (
	ECHO GIT was not found, abort.
	pause
	exit
)

start cmd /K InstallAfterGit.cmd

ENDLOCAL
exit
