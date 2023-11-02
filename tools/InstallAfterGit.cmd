
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

git clone https://gitlab.com/fajeth-modpack/megamodpack-reforged.git MMP-Reforged-TMP

echo Remove Scripts folder ...
rmdir Scripts /s /q
echo Copy Mod into game folder ...
robocopy MMP-Reforged-TMP . /is /it /im /e /move /log:reforged-installer.log
rmdir MMP-Reforged-TMP /s /q

echo ++++++++++++++++++++++++++++++++
echo -------Available languages:-----
for /D %%d in (Translations/*) do echo %%d
echo --------------SELECT-------------
SET /P language=Choose your language: 
echo Copy translation ...
robocopy Translations/%language% . /is /it /im /e /xf .gitkeep /xf *.txt /log+:reforged-installer.log

echo Done. Enjoy the Reforged!
ENDLOCAL
pause
exit

