#!/bin/bash

# A script for setting an alarm within the terminal

#ISSUES:
#Does not work on BSD-bash
#No interactive mode

<<"BRIEF"
  This alarm will operate using command line arguments.
  In absence (or excess) of arguments, alarm will display the "help" section.
  For option -t or --time, alarm will go off at time set. This will not take the seconds into account.
  For option -d or --duration, alarm will go off after set number of seconds have passed

BRIEF

#verify that initial setup has taken place
if ls ~/.alarmconfig > /dev/null 2>&1
then
  continue
else
  echo "Run the setup script"
  exit 1
fi

#Defining colours as per the ascii escape characters
RED="\e[31;1m"
GREEN="\e[32;1m"
CYAN="\e[36;1m"
YELLOW="\e[33;1m"
NC="\e[0m"

#To clear the screen completely
tput reset

#Default message
DISPLAYMSG="Time's Up!"

#Will be called when wrong input detected
function displayHelp {
  echo "Type \`alarm -t hh:mm\` or \`alarm --time hh:mm\` for setting the time (24 hour clock) at which the alarm will go off"
  echo "Type \`alarm -d hh:mm\` or \`alarm --duration hh:mm\` for setting the time at which the alarm will go off"
}

#makes sure that the time entered is valid
function verifyTime {                                                         #  This verifies whether entered time is valid or not
  min=${1##*:}
  hrs=${1%:*}

  if [ ${#hrs} -eq 2 ] && [ $hrs -lt 24 ] && [ $hrs -ge 0 ]
  then
    if [ ${#min} -eq 2 ] && [ $min -lt 60 ] && [ $min -ge 0 ]
    then
      return 0
    else
      return 1
    fi
  else
    return 1
  fi
}

#makes sure that the duration of time entered is valid
function verifyDuration {                                                         #  This verifies whether entered time is valid or not
  min=${1##*:}
  hrs=${1%:*}

  if [ ${#hrs} -eq 2 ] && [ $hrs -ge 0 ]
  then
    if [ ${#min} -eq 2 ] && [ $min -lt 60 ] && [ $min -ge 0 ]
    then
      return 0
    else
      return 1
    fi
  else
    return 1
  fi
}

#fixes the duration for which to sleep
function setDuration {
  timeFinal=$(echo "$hrs * 3600 + $min * 60" | bc)
  timeCurrent=$(echo "$(date +%H) * 3600 + $(date +%M) * 60 + $(date +%S)" | bc)              #  date +%H gives the current hours in 24-hour system
                                                                                #  date +%M gives the current minutes
  timeLeft=$((timeFinal - timeCurrent))

  if [ "$timeLeft" -lt 0 ]
  then
    timeLeft=$((timeLeft + 24 * 3600))
  fi

  temp=$timeLeft
  hrs=$((temp / 3600))
  temp=$((temp % 3600))
  min=$((temp / 60))
  secs=$((temp % 60))
  DURATION="${hrs}h ${min}m ${secs}s"
}

#sets alarm based on entered input
function alarmSet {
  if [ "$1" = "-t" ] || [ "$1" = "--time" ]
  then
    time="$2"
    if verifyTime $time
    then
      setDuration
    else
      echo "Not a valid time"
      exit 1;
    fi

  elif [ "$1" = "-d" ] || [ "$1" = "--duration" ]
  then
    duration="$2"
    if verifyDuration $duration
    then
      DURATION="${hrs}h ${min}m"
      secs=0
      timeLeft=$((hrs * 3600 + min * 60))
    else
      echo "Not a valid duration of time"
      exit 1;
    fi

  else

    displayHelp

  fi
}

#for user to set custom message
#can't take multiline messages
function setMessage {
  echo "Do you want to display a message?y/n"
  read ANS
  if [ "$ANS" = "y" ]
  then
    echo "Type your message"
    read DISPLAYMSG

  else
    echo "Default message will be displayed"
  fi
}

#gets the current path of said script
path=$(realpath .) #$(dirname "$(readlink -f "$0")")

#refers to the "views.sh" script which must be in the same path
. $path/views.sh

#this_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
#source $this_dir/views.sh

#display countdown ie time left in hh:mm:ss

#more accurate
#<<"TRIAL1"
function countDown {
  secsLeft=$timeLeft
  secsFinal=$((timeLeft + `(date +%s)`))

  while ((secsLeft >= 0))
  do
    tallySecs=$((secsFinal - `date +%s`))
    if((tallySecs < 0))
    then
      tallySecs=$((tallySecs + 24 * 3600))
    fi
    if(( $tallySecs == $secsLeft ))
    then
      temp=$secsLeft
      hoursLeft=$((secsLeft / 3600))
      secsLeft=$((secsLeft % 3600))
      minsLeft=$((secsLeft / 60))
      secsLeft=$((secsLeft % 60))

      tput reset

      hoursLeft=$(printf "%02d" "$hoursLeft")
      minsLeft=$(printf "%02d" "$minsLeft")
      secsLeft=$(printf "%02d" "$secsLeft")
      if [ "$minsLeft" -lt 1 ]
      then
        COLOUR="$RED"
      elif [ "$minsLeft" -lt 10 ]
      then
        COLOUR="$YELLOW"
      else
        COLOUR="$CYAN"
      fi
      printNum "$hoursLeft:$minsLeft:$secsLeft" "$COLOUR"
      secsLeft=$temp
      ((secsLeft--))
    fi

  done
}

#for interactive mode
function interact {
	resize -s $(tput lines) 114 > /dev/null 2>&1

	echo "Interactive mode-"
	echo "Enter the time duration you want to be woken up after in hh:mm"

	read DURATN

	alarmSet "-t" "$DURATN"

	toneDir=$(cat ~/.alarmconfig)
  echo -e "${GREEN}"
  ls $toneDir
  echo -e "${NC}"
  echo -e "\n\nSelect your alarm tone"
  read tone
  setMessage
  echo "Press return"
  read -n 1
}

#main part of the script
case $# in
	0)	interact
			;;

  2)  resize -s $(tput lines) 114 > /dev/null 2>&1
      toneDir=$(cat ~/.alarmconfig)
      echo -e "${GREEN}"
      ls $toneDir
      echo -e "${NC}"
      echo -e "\n\nSelect your alarm tone"
      read tone
      setMessage
      echo "Press return"
      read -n 1
      tput reset
      alarmSet $1 $2
      ;;

  *)  displayHelp
      exit 1
      ;;

esac

#sleep for set interval of time
(sleep $DURATION) &
#showProgress
countDown
wait
tput reset
echo $DISPLAYMSG
echo "Press return"
play -q "$toneDir/$tone" &

read -n 1
pkill play
exit 0
