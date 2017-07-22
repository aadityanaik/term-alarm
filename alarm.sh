#!/bin/bash

# A script for setting an alarm within the terminal

#ISSUES:
#Alarm inaccurate for large time interval
#tested to be off by 8 seconds for an alarm set for 10 minutes
#
#User cannot select his own alarm tone
#setup file to be created to give the user a choice for his tunes

<<"BRIEF"
  This alarm will operate using command line arguments.
  In absence (or excess) of arguments, alarm will display the "help" section.
  For option -t or --time, alarm will go off at time set. This will not take the seconds into account.
  For option -d or --duration, alarm will go off after set number of seconds have passed

BRIEF

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
  DURATION=$((timeFinal - timeCurrent))


  if [ "$DURATION" -lt 0 ]
  then
    DURATION=$((DURATION + 24 * 3600))
  fi
}

#sets alarm based on entered input
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
path=$(dirname "$(readlink -f "$0")")

#refers to the "views.sh" script which must be in the same path
. $path/views.sh

#display countdown ie time left in hh:mm:ss
function countDown {
  secsLeft=$DURATION
  secsFinal=$((DURATION + `(date +%s)`))

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
      printNum "$hoursLeft:$minsLeft:$secsLeft"
      secsLeft=$temp
      ((secsLeft--))
    fi

  done
}


#main part of the script
case $# in
  2)  resize -s $(tput lines) 114 > /dev/null 2>&1
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
echo $DISPLAYMSG
echo "Press return"
paplay /usr/share/sounds/ubuntu/ringtones/Alarm\ clock.ogg &

read -n 1
pkill paplay
exit 0
