#!/bin/bash
cpu=$(ps -A -o %cpu | awk '{s+=$1} END {print s}')
cpu_int=$(printf "%.0f" $cpu)

# Choose icon based on CPU level
if [ "$cpu_int" -lt 20 ]; then
  icon="🐱"
elif [ "$cpu_int" -lt 50 ]; then
  icon="🐈"
else
  icon="🐆"
fi

sketchybar --set runcat label="$icon $cpu_int%"
