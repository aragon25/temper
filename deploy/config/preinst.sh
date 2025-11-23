#!/bin/bash
if [ "$(which temper)" != "" ] && [ "$1" == "install" ]; then
  echo "The command \"temper\" is already present. Can not install this."
  echo "File: \"$(which temper)\""
  exit 1
fi
exit 0
