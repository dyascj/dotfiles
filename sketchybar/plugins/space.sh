#!/bin/sh

# Coffee colors
ACTIVE_COLOR=0xffe6b55a     # golden accent
INACTIVE_COLOR=0xff7a6a52   # muted

if [ "$SELECTED" = "true" ]; then
  sketchybar --set "$NAME" background.drawing=on \
                           icon.color=$ACTIVE_COLOR
else
  sketchybar --set "$NAME" background.drawing=off \
                           icon.color=$INACTIVE_COLOR
fi
