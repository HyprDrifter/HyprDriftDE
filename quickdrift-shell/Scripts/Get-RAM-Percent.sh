#!/bin/bash

usage=$(free | awk '/Mem:/ { printf("%.1f", $3/1024/1024) }')

echo "$usage"
