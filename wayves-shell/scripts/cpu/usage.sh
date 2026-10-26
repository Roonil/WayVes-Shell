#!/bin/bash

sample() {
    read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
    idleNow=$((idle + iowait))
    totalNow=$((user + nice + system + idle + iowait + irq + softirq + steal))
}

echoUsage() {
    local prevIdle=$idleNow prevTotal=$totalNow
    sample
    local total=$((totalNow - prevTotal))
    ((total > 0)) || return
    local tenths=$((1000 * (total - (idleNow - prevIdle)) / total))
    percentage="$((tenths / 10)).$((tenths % 10))"

    echo "$percentage"
    echo -e "progress=$percentage" | timeout 1 tee /tmp/WayVes/cpu_usage > /dev/null
}

sample
sleep 0.25
echoUsage
while sleep 2; do echoUsage; done
