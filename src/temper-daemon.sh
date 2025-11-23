#!/bin/bash
##############################################
##                                          ##
##  auto-reboot-service                     ##
##                                          ##
##############################################

#get some variables
SCRIPT_TITLE="temper-daemon"
SCRIPT_VERSION="1.1"
SCRIPTDIR="$(readlink -f "$0")"
SCRIPTNAME="$(basename "$SCRIPTDIR")"
SCRIPTDIR="$(dirname "$SCRIPTDIR")"
EXITCODE=0

#!!!RUN RESTRICTIONS!!!
#only for raspberry pi (rpi5|rpi4|rpi3|all) can combined!
raspi=""
#only for Raspbian OS (bookworm|bullseye|all) can combined!
rasos=""
#only for cpu architecture (i386|armhf|amd64|arm64) can combined!
cpuarch=""
#only for os architecture (32|64) can NOT combined!
bsarch=""
#this aptpaks need to be installed!
aptpaks=( python3 python3-serial )

#check commands
for i in "$@"
do
  case $i in
    --service)
    [ "$CMD" == "" ] && CMD="service" || CMD="help"
    shift # past argument
    ;;
    -v|--version)
    [ "$CMD" == "" ] && CMD="version" || CMD="help"
    shift # past argument
    ;;
    -h|--help)
    CMD="help"
    shift # past argument
    ;;
    *)
    if [ "$i" != "" ]
    then
      echo "Unknown option: $i"
      exit 1
    fi
    ;;
  esac
done
[ "$CMD" == "" ] && CMD="help"

function do_check_start() {
  #check if superuser
  if [ $UID -ne 0 ]; then
    echo "Please run this script with Superuser privileges!"
    exit 1
  fi
  #check if raspberry pi 
  if [ "$raspi" != "" ]; then
    raspi_v="$(tr -d '\0' 2>/dev/null < /proc/device-tree/model)"
    local raspi_res="false"
    [[ "$raspi_v" =~ "Raspberry Pi" ]] && [[ "$raspi" =~ "all" ]] && raspi_res="true"
    [[ "$raspi_v" =~ "Raspberry Pi 3" ]] && [[ "$raspi" =~ "rpi3" ]] && raspi_res="true"
    [[ "$raspi_v" =~ "Raspberry Pi 4" ]] && [[ "$raspi" =~ "rpi4" ]] && raspi_res="true"
    [[ "$raspi_v" =~ "Raspberry Pi 5" ]] && [[ "$raspi" =~ "rpi5" ]] && raspi_res="true"
    if [ "$raspi_res" == "false" ]; then
      echo "This Device seems not to be an Raspberry Pi ($raspi)! Can not continue with this script!"
      exit 1
    fi
  fi
  #check if raspbian
  if [ "$rasos" != "" ]
  then
    rasos_v="$(lsb_release -d -s 2>/dev/null)"
    [ -f /etc/rpi-issue ] && rasos_v="Raspbian ${rasos_v}"
    local rasos_res="false"
    [[ "$rasos_v" =~ "Raspbian" ]] && [[ "$rasos" =~ "all" ]] && rasos_res="true"
    [[ "$rasos_v" =~ "Raspbian" ]] && [[ "$rasos_v" =~ "bullseye" ]] && [[ "$rasos" =~ "bullseye" ]] && rasos_res="true"
    [[ "$rasos_v" =~ "Raspbian" ]] && [[ "$rasos_v" =~ "bookworm" ]] && [[ "$rasos" =~ "bookworm" ]] && rasos_res="true"
    if [ "$rasos_res" == "false" ]; then
      echo "You need to run Raspbian OS ($rasos) to run this script! Can not continue with this script!"
      exit 1
    fi
  fi
  #check cpu architecture
  if [ "$cpuarch" != "" ]; then
    cpuarch_v="$(dpkg --print-architecture 2>/dev/null)"
    if [[ ! "$cpuarch" =~ "$cpuarch_v" ]]; then
      echo "Your CPU Architecture ($cpuarch_v) is not supported! Can not continue with this script!"
      exit 1
    fi
  fi
  #check os architecture
  if [ "$bsarch" == "32" ] || [ "$bsarch" == "64" ]; then
    bsarch_v="$(getconf LONG_BIT 2>/dev/null)"
    if [ "$bsarch" != "$bsarch_v" ]; then
      echo "Your OS Architecture ($bsarch_v) is not supported! Can not continue with this script!"
      exit 1
    fi
  fi
  #check apt paks
  local apt
  local apt_res
  IFS=$' '
  if [ "${#aptpaks[@]}" != "0" ]; then
    for apt in ${aptpaks[@]}; do
      [[ ! "$(dpkg -s $apt 2>/dev/null)" =~ "Status: install" ]] && apt_res="${apt_res}${apt}, "
    done
    if [ "$apt_res" != "" ]; then
      echo "Not installed apt paks: ${apt_res%?%?}! Can not continue with this script!"
      exit 1
    fi
  fi
  unset IFS
}

function cmd_service() {
  local entry
  local test
  local temper_ids_active
  local temper_id
  local temper_temp_C
  local temper_temp_F
  while true; do
    if [ "$(which temper)" != "" ]; then
      temper_ids_active=""
      test=""
      entry=""
      if [ ! -d "/run/temper_temp" ]; then
        rm -f "/run/temper_temp"
        mkdir -p "/run/temper_temp"
      fi
      shopt -s lastpipe; temper | while IFS= read -r line; do
        temper_id="$(echo \"$line\" | grep -ow -E [a-Z0-9]+:[a-Z0-9]+)"
        temper_temp_C="$(echo \"$line\" | grep -ow -E [-.0-9]+C)"
        temper_temp_F="$(echo \"$line\" | grep -ow -E [-.0-9]+F)"
        temper_ids_active="${temper_ids_active}${temper_id}"
        echo "$temper_temp_C $temper_temp_F" > "/run/temper_temp/$temper_id"
      done
      unset IFS
      IFS=$'\n'
      test=($(find "/run/temper_temp" -maxdepth 1 -type f ))
      if [ "${#test[@]}" != "0" ]; then
        for entry in ${test[@]}; do
          if [[ ! "${temper_ids_active}" =~ "$(basename "$entry")" ]]; then
            rm -f "$entry"
          fi
        done
      fi
      unset IFS
    else
      echo "temper was not found!"
      exit 1
    fi
    sleep 10
  done
}

function cmd_print_version() {
  echo "$SCRIPT_TITLE v$SCRIPT_VERSION"
}

function cmd_print_help() {
  echo "Usage: $(basename ""$0"") [OPTION]"
  echo "$SCRIPT_TITLE v$SCRIPT_VERSION"
  echo " "
  echo "Get Temperatures from temper devices every 10sec. and"
  echo "saves them in /run/temper_temp folder."
  echo " "
  echo "-v, --version           print version info and exit"
  echo "-h, --help              print this help and exit"
  echo " "
  echo "Only one option at same time is allowed!"
  echo " "
  echo "Author: aragon25 <aragon25.01@web.de>"
}

[ "$CMD" != "version" ] && [ "$CMD" != "help" ] &&  do_check_start
[[ "$CMD" == "version" ]] && cmd_print_version
[[ "$CMD" == "help" ]] && cmd_print_help
[[ "$CMD" == "service" ]] && cmd_service

exit $EXITCODE
