#!/bin/bash

echoUsage() {
    read -r usage total percentage < <(awk '/^MemTotal:/ { t = $2 } /^MemAvailable:/ { a = $2 }
        END { printf "%d %d %.2f\n", (t - a) / 1024, t / 1024, (t - a) / t * 100 }' /proc/meminfo)
    echo "$usage $total"
    echo -e "progress=$percentage" | timeout 1 tee /tmp/WayVes/memory_usage > /dev/null
}

echoUsage
while sleep 2; do echoUsage; done
