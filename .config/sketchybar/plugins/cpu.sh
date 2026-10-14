#!/bin/bash

# Total CPU across every core, as a share of the whole machine
load=$(ps -A -o %cpu | awk -v cores="$(sysctl -n hw.ncpu)" '{s += $1} END {printf "%d", s / cores}')
sketchybar --set "$NAME" label="$load%"
