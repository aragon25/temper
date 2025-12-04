#!/bin/bash
function undo_changes(){
  userdel -f -r temper >/dev/null 2>&1
  deluser --group temper >/dev/null 2>&1
  udevadm control --reload-rules >/dev/null 2>&1
  udevadm trigger >/dev/null 2>&1
  systemctl stop temper.service >/dev/null 2>&1
  systemctl disable temper.service >/dev/null 2>&1
  rm -rf "/run/temper_temp" >/dev/null 2>&1
  exit 1
}
if [ -f "/usr/bin/temper" ]; then
  echo "add user and group \"temper\" and rules ..."
  if ! id "temper" >/dev/null 2>&1; then
    adduser temper --system --group --disabled-login --no-create-home >/dev/null 2>&1
    [ $? -ne 0 ] && undo_changes
  fi
  udevadm control --reload-rules >/dev/null 2>&1
  [ $? -ne 0 ] && undo_changes
  udevadm trigger >/dev/null 2>&1
  [ $? -ne 0 ] && undo_changes
  echo "Install temper service ..."
  systemctl daemon-reload >/dev/null 2>&1
  [ $? -ne 0 ] && undo_changes
  systemctl enable temper.service >/dev/null 2>&1
  [ $? -ne 0 ] && undo_changes
  systemctl start temper.service >/dev/null 2>&1
  [ $? -ne 0 ] && undo_changes
else
  undo_changes
fi
exit 0
