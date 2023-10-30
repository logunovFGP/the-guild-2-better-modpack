
SETLOCAL
@echo off 

echo Update mod ...
git pull

echo ++++++++++++++++++++++++++++++++
echo -------Available languages:-----
for /D %%d in (Translations/*) do echo %%d
echo --------------SELECT-------------
SET /P language=Choose your language: 
echo Copy translation ...
robocopy Translations/%language% . /xf .gitkeep /xf *.txt /log+:reforged-installer.log

echo Update done. Enjoy the Reforged!
ENDLOCAL
pause


