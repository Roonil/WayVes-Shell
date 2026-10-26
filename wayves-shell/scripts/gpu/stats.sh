#!/bin/bash

exec 3< <(nvidia-smi -i 0 --query-gpu=temperature.gpu,clocks.gr,memory.used,utilization.gpu --format=csv,noheader,nounits -l 2)
smi=$!
trap 'kill "$smi" 2>/dev/null' EXIT
trap 'exit' TERM INT HUP

while IFS=', ' read -r temp freq mem usage <&3; do
    echo "$temp $freq $mem $usage"
    echo -e "progress=$temp" | timeout 1 tee /tmp/WayVes/gpu_temp > /dev/null
    echo -e "progress=$usage" | timeout 1 tee /tmp/WayVes/gpu_usage > /dev/null
done
