#!/bin/sh

# Catppuccin Mocha colors
ACTIVE_COLOR=0xffcba6f7     # mauve (accent)
INACTIVE_COLOR=0xff6c7086   # overlay0

if [ "$SELECTED" = "true" ]; then
  sketchybar --set "$NAME" background.drawing=on \
                           icon.color=$ACTIVE_COLOR
else
  sketchybar --set "$NAME" background.drawing=off \
                           icon.color=$INACTIVE_COLOR
fi
