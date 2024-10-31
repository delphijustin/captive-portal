#!/bin/bash
if [[ "$1" == "" ]]
then
echo "Adds a game into captive portal"
echo "Usage: offline-game.sh gamename"
echo "Replace gamename with a folder name to install the folder as a game"
exit 0
fi
if [[ -d "$1" ]]
then
GAMEDIR=user-$RANDOM-$RANDOM-$RANDOM-$RANDOM
read -p "Enter the HTML filename of the game : " GAMEFILE
if [[ "$GAMEFILE" == "$1"* ]]
echo "The game file cannot be in $1"
echo "Please don't include that in the path"
exit 1
fi
read -p "Enter a title for the game: " GAMECAP
mkdir /etc/captiveportal/games/custom-$GAMEDIR
cp -rv $1 /etc/captiveportal/games/custom-$GAMEDIR/
echo "games.push({\"caption\":\"$GAMECAP\",\"filename\":\"custom-$GAMEDIR/$GAMEFILE\"});" >> /etc/captiveportal/games.js
echo "UNINSTALLCMD=rm -rf /etc/captiveportal/games/custom-$GAMEDIR/*" > /etc/captiveportal/games/custom-$GAMEDIR.installer
exit 0
fi
if [[ -f "/etc/captiveportal/games/$1.installer" ]]
then
source /etc/captiveportal/games/$1.installer
if [[ -d $GAMEDIR ]]
then
read -p "Type YES in uppercase letters to remove game: $1"
$UNINSTALLCMD
exit 2
fi
$INSTALLCMD
echo "game.push({\"caption\":\"$GAMECAP\",\"filename\":\"$GAMEDIR$/GAMEFILE\"});" >> /etc/captiveportal/games.js
fi
exit 0
fi
echo "No installer or folder found for \"$1\""
