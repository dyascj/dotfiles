#!/bin/sh

# Get CPU usage percentage (user + system)
CPU=$(top -l 2 -n 0 | grep "CPU usage" | tail -1 | awk '{print $3}' | sed 's/%//')

# Round to integer
CPU_INT=${CPU%.*}

# Choose icon based on CPU load
case "$CPU_INT" in
  [0-9]|[1-2][0-9]) ICON="󰻠" ;;      # low
  [3-5][0-9]) ICON="󰻠" ;;            # medium
  [6-7][0-9]) ICON="󰻠" ;;            # high
  *) ICON="󰻠" ;;                     # very high
esac

sketchybar --set "$NAME" icon="$ICON" label="${CPU_INT}%"
