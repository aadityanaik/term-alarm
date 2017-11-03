#!/bin/bash

#Runs initial setup for alarm script

echo "Starting config"

#check that the appropriate player is installed
if !(which play > /dev/null 2>&1)
then
  echo "You don't have play installed. This alarm requires you to have the sox package installed."
  echo "You can install play by typing \`sudo apt-get install sox\`"
  exit 1
fi

if !(dpkg -l coreutils > /dev/null 2>&1)
then
  echo "You don't have GNU coreutils installed."
  echo "Please install coreutils to continue."
  exit 1
fi

echo "This config file simply needs you to enter the path of the folder which will contain all of your alarm tones."
echo "If unsure regarding the directory name, you may want to look it up."
echo "Enter the directory name:"

read dirName

if [ -d "$dirName" ]
then
  echo "Cool."
else
  echo "Invalid directory path"
  exit 1
fi

echo "Thanks for going through the pain of configuring the alarm."
echo "If you need to edit any information, you may simply execute this script again."

echo "$dirName" > ~/.alarmconfig
