#!/bin/bash

# Icon
icon="󰘚"

# Check for NVIDIA
if command -v nvidia-smi &> /dev/null; then
    usage=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | head -n 1)
    echo "${usage}"

# Check for AMD using radeontop
elif command -v radeontop &> /dev/null; then
    usage=$(radeontop -d - -l 1 | grep -m1 'gpu' | awk '{print $2}')
    echo "$usage"

# Fallback
else
    echo "N/A"
fi
