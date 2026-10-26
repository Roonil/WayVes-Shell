#!/bin/bash

echoTemperature(){
temp=$(sensors | grep -E 'Tctl|Tdie' | awk -F'+' '{print $2}' | awk -F'°' '{print $1}')
  echo "$temp"
  echo -e "progress=$temp" | timeout 1 tee /tmp/WayVes/cpu_temp > /dev/null
}

echoTemperature
while sleep 2; do echoTemperature; done
