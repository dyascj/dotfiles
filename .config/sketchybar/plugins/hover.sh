#!/bin/bash

# Menu rows light up with Ash's white wash under the mouse
color=0x00000000
[ "$SENDER" = mouse.entered ] && color=0x1affffff
sketchybar --set "$NAME" background.color=$color
