#!/bin/bash

devices=$( { lspci -mm -d ::0302; lspci -mm -d ::0300; } 2>/dev/null)
if command -v nvidia-smi >/dev/null 2>&1; then
    line=$(echo "$devices" | grep -m 1 '"NVIDIA')
fi
[ -z "$line" ] && line=$(echo "$devices" | head -n 1)

vendor=$(echo "$line" | awk -F'"' '{print $4}')
device=$(echo "$line" | awk -F'"' '{print $6}')

case "$vendor" in
NVIDIA*) vendor="NVIDIA" ;;
"Advanced Micro Devices"*) vendor="AMD" ;;
Intel*) vendor="Intel" ;;
esac

model=$(echo "$device" | sed -n 's/.*\[\(.*\)\].*/\1/p' | cut -d'/' -f1 | sed 's/ *$//')
[ -z "$model" ] && model="$device"

if [ -n "$model" ]; then
    echo "$vendor $model"
else
    nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -n 1 | grep . || echo "Unknown GPU"
fi
