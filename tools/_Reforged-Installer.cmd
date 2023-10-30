
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

git clone https://gitlab.com/fajeth-modpack/megamodpack-reforged.git MMP-Reforged-TMP

echo Remove Scripts folder ...
rmdir Scripts /s /q
echo Copy Mod into game folder ...
robocopy MMP-Reforged-TMP . /e /move /log:reforged-installer.log
rmdir MMP-Reforged-TMP /s /q

echo ++++++++++++++++++++++++++++++++
echo -------Available languages:-----
for /D %%d in (Translations/*) do echo %%d
echo --------------SELECT-------------
SET /P language=Choose your language: 
echo Copy translation ...
robocopy Translations/%language% . /xf .gitkeep /xf *.txt /log+:reforged-installer.log

echo Done. Enjoy the Reforged!
ENDLOCAL
pause

