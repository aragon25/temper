#!/bin/bash
userdel -f -r temper >/dev/null 2>&1
deluser --group temper >/dev/null 2>&1
udevadm control --reload-rules >/dev/null 2>&1
udevadm trigger >/dev/null 2>&1
systemctl daemon-reload >/dev/null 2>&1
rm -rf "/run/temper_temp" >/dev/null 2>&1
exit 0
