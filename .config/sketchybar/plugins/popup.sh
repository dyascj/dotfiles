#!/bin/bash

# A button that opens its popup on click and closes it when the mouse leaves
case "$SENDER" in
  mouse.clicked) sketchybar --set "$NAME" popup.drawing=toggle ;;
  mouse.exited.global) sketchybar --set "$NAME" popup.drawing=off ;;
esac
