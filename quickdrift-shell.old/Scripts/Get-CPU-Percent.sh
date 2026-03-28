#!/bin/bash

info=$(top -bn1 | grep "Cpu(s)" | awk '{printf "%d\n", 100 - $8}')

echo "$info"
fi
