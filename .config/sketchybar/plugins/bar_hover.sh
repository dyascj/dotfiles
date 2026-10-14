#!/bin/bash

# Clickable things on the bar fade in Ash's 5% wash under the mouse.
# The focused workspace keeps its 10% wash.
source "$CONFIG_DIR/helpers/ash.sh"

case $NAME in
  space.*) sketchybar --query "$NAME" | grep -q "\"color\": \"$WASH\"" && exit 0 ;;
esac
color=$CLEAR
[ "$SENDER" = mouse.entered ] && color=$HOVER
sketchybar --animate tanh 10 --set "$NAME" background.color=$color
