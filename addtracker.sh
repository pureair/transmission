#!/bin/bash
# https://github.com/oilervoss/transmission

# Below is a command that will get a list of trackers with one tracker per line
# command can be 'cat /some/path/trackers.txt' for a static list
LIVE_TRACKERS_LIST_CMD='curl -fs --url https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_all_http.txt' 

TRANSMISSION_REMOTE='/usr/bin/transmission-remote'

TORRENTS=$($TRANSMISSION_REMOTE -l 2>/dev/null)
if [ $? -ne 0 ]; then
  echo -e "\n\e[0;91;1mFail on transmission. Aborting.\n\e[0m"
  exit 1
fi

if [ $# -eq 0 ]; then
    echo -e "\n\e[31mThis script expects one or more parameters\e[0m"
    echo -e "\e[0;36maddtracker \t\t- list current torrents "
    echo -e "addtracker \$n1 \$n2...\t- add trackers to torrent of number \$n1 and \$n2"
    echo -e "addtracker \$s1 \$s2...\t- add trackers to first torrent with part of name \$s1 and \$s2"
    echo -e "addtracker .\t\t- add trackers to all torrents"
    echo -e "Names are case insensitive "
    echo -e "\n\e[0;32;1mCurrent torrents:\e[0;32m"
    echo "$TORRENTS" | sed -nr 's:(^.{4}).{64}:\1:p'
    echo -e "\n\e[0m"
    exit 1
fi

TRACKER_LIST=`$LIVE_TRACKERS_LIST_CMD`
if [ $? -ne 0 ] || [ -z "$TRACKER_LIST" ]; then
	TRACKER_LIST="http://retracker.mgts.by:80/announce
http://tracker.city9x.com:2710/announce
http://0d.kebhana.mx:443/announce
http://retracker.telecom.by:80/announce
http://open.acgnxtracker.com:80/announce
http://alpha.torrenttracker.nl:443/announce
http://tracker2.itzmx.com:6961/announce
http://tracker.vanitycore.co:6969/announce
http://tracker.torrentyorg.pl:80/announce
http://tracker.tfile.me:80/announce
http://tracker.mg64.net:6881/announce
http://tracker.internetwarriors.net:1337/announce
http://tracker.electro-torrent.pl:80/announce
http://t.nyaatracker.com:80/announce
http://share.camoe.cn:8080/announce
http://open.acgtracker.com:1096/announce
http://omg.wtftrackr.pw:1337/announce
http://mgtracker.org:6969/announce
http://fxtt.ru:80/announce
http://bt.dl1234.com:80/announce
http://agusiq-torrents.pl:6969/announce
http://104.238.198.186:8000/announce"

fi

while [ $# -ne 0 ]; do

  PARAMETER="$1"
  [ "$PARAMETER" = "." ] && PARAMETER=" "

  if [ ! -z "${PARAMETER//[0-9]}" ] ; then
    PARAMETER=$(echo "$TORRENTS" | \
      sed -nr '1d;/^Sum:/d;s:(^.{4}).{64}:\1:p' | \
      grep -i "$PARAMETER" | \
      sed -nr 's:(^.{4}).*:\1:;s: ::gp')

    if [ ! -z "$PARAMETER" ] && [ -z ${PARAMETER//[0-9]} ] ; then
      NUMBERCHECK=1
      echo -e "\n\e[0;32;1mI found the following torrent:\e[0;32m"
      echo "$TORRENTS" | sed -nr 's:(^.{4}).{64}:\1:p' | grep -i "$1"
    else
      NUMBERCHECK=0
    fi
  else
    NUMBERCHECK=$(echo "$TORRENTS" | \
      sed -nr '1d;/^Sum:/d;s: :0:g;s:^(....).*:\1:p' | \
      grep $(echo 0000$PARAMETER | sed -nr 's:.*([0-9]{4}$):\1:p'))

  fi

  if [ ${NUMBERCHECK:-0} -eq 0 ]; then
    echo -e "\n\e[0;31;1mI didn't find a torrent with the text/number: \e[21m$1"
    echo -e "\e[0m"
    shift
    continue
  fi

  for TORRENT in $PARAMETER; do
    echo -ne "\n\e[0;1;4;32mFor the Torrent: \e[0;4;32m"
    $TRANSMISSION_REMOTE -t $TORRENT -i | sed -nr 's/ *Name: ?(.*)/\1/p'
    echo "$TRACKER_LIST" | while read TRACKER
    do
      if [ ! -z "$TRACKER" ]; then
        echo -ne "\e[0;36;1mAdding $TRACKER\e[0;36m"
        $TRANSMISSION_REMOTE -t $TORRENT -td $TRACKER 1>/dev/null 2>&1 
        if [ $? -eq 0 ]; then
          echo -e " -> \e[32mSuccess! "
        else
          echo -e " - \e[31m< Failed > "
        fi
      fi
    done
  done
  
  shift 
done

echo -e "\e[0m"
