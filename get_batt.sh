#!/bin/zsh
# Print the current battery percentage as "NN%" (or nothing on desktops
# where AppleSmartBattery is absent).

/usr/sbin/ioreg -rn AppleSmartBattery -d 1 2>/dev/null | awk -F' = ' '
  /"CurrentCapacity"/ { printf "%s%%\n", $2; exit }
'
