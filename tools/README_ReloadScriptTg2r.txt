# ReloadScriptTg2r #

Author: ThreeOfMe (threeofme@posteo.ch)

This program is free software. It is distributed as-is and as-available. 
It comes without any warranty, to the extent permitted by applicable law. 


## About ReloadScriptTg2r ##

This tool utilizes a debug interface of TG2R. 
It forces the game to reload scripts during a running game.


## Who should use ReloadScriptTg2r? ##

Modders of TG2R can use the tool to reload scripts they are working on. 

Testers of TG2R-Mods can use the tool to update savegames to the latest 
version.


## Config.ini ##

Since the tool uses the debug interface of TG2R, you will need to activate this.
Add the following lines to the end of your config.ini (make sure not to duplicate
the DEBUG block or the parameters):

[DEBUG]
AID = 1
ScriptDebugger = 1


## Usage ##

The ReloadScriptTg2r.exe needs to be placed in a subfolder of the game, 
i.e. "Scripts/ReloadScriptTg2r.exe" or "tools/ReloadScriptTg2r.exe".

If you don't care about specific scripts you can simply start the program as it is. 
This will start a console and update all files matching "*.lua" in your Scripts folder.

If you want to update specific scripts you can specify these as parameters to the 
program via the console. Here is an example call to update scripts with "hottea" in 
their name and scripts in the folder "Library/" from console:

    ./ReloadScriptTg2r.exe *hottea*.lua Library/*.lua

You could probably even link this up with your favorite LUA editor to reload any script 
that you save with changes. Just make sure that the working directory of the program 
is still a direct subfolder of the game (yes, there are neater ways to handle this by 
passing the path as parameter -- but that's for later). 


Final Note: It may be obvious, but the game needs to be running for this to have any effect.
