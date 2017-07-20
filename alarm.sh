#!/bin/bash

# A script for setting an alarm within the terminal

<<"BRIEF"
  This alarm will operate using command line arguments.
  In absence (or excess) of arguments, alarm will display the "help" section.
  For option -t or --time, alarm will go off at time set. This will not take the seconds into account.
  For option -d or --duration, alarm will go off after set number of seconds have passed

BRIEF

tput reset

DISPLAYMSG="Time's Up!"

function displayHelp {
  echo "Type \`alarm -t hh:mm\` or \`alarm --time hh:mm\` for setting the time (24 hour clock) at which the alarm will go off"
  echo "Type \`alarm -d hh:mm\` or \`alarm --duration hh:mm\` for setting the time at which the alarm will go off"
}

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

function setDuration {
  timeFinal=$(echo "$hrs * 3600 + $min * 60" | bc)
  timeCurrent=$(echo "$(date +%H) * 3600 + $(date +%M) * 60 + $(date +%S)" | bc)              #  date +%H gives the current hours in 24-hour system
                                                                                #  date +%M gives the current minutes
  DURATION=$((timeFinal - timeCurrent))

  if [ "$DURATION" -lt 0 ]
  then
    DURATION=$((DURATION + 24 * 3600))
  fi
}

function alarmSet {
  if [ "$1" = "-t" ] || [ "$1" = "--test" ]
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
      DURATION=$((hrs * 3600 + min * 60))
    else
      echo "Not a valid duration of time"
      exit 1;
    fi

  fi
}

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

. ./views.sh

function countDown {
  secsLeft=$DURATION

  while ((secsLeft >= 0))
  do
    temp=$secsLeft
    hoursLeft=$((secsLeft / 3600))
    secsLeft=$((secsLeft % 3600))
    minsLeft=$((secsLeft / 60))
    secsLeft=$((secsLeft % 60))

    tput reset

    hoursLeft=$(printf "%02d" "$hoursLeft")
    minsLeft=$(printf "%02d" "$minsLeft")
    secsLeft=$(printf "%02d" "$secsLeft")
    printNum "$hoursLeft:$minsLeft:$secsLeft"

    sleep 1
    secsLeft=$temp
    ((secsLeft--))
  done
}

case $# in
  2)  resize -s $(tput lines) 114 > al_temp
      rm al_temp
      setMessage
      alarmSet $1 $2
      echo "Press return"
      read -n 1
      tput reset
      ;;

  *)  displayHelp
      exit 1
      ;;

esac

sleep $DURATION &
#showProgress
countDown
wait
echo $DISPLAYMSG
echo "Press return"
paplay /usr/share/sounds/ubuntu/ringtones/Alarm\ clock.ogg &

read -n 1
pkill paplay
exit 0
