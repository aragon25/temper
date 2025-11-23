#!/bin/bash
systemctl stop temper.service >/dev/null 2>&1
systemctl disable temper.service >/dev/null 2>&1
exit 0
