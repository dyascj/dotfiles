#!/bin/bash

# INFO has the app name on a switch; on startup, ask macOS who's in front
app=$INFO
[ -n "$app" ] || app=$(lsappinfo info "$(lsappinfo front)" | head -1 | cut -d'"' -f2)

source "$CONFIG_DIR/helpers/icon_map.sh"
__icon_map "$app"
# The new app's name fades in, the way macOS swaps its bold app menu
sketchybar --set "$NAME" icon="$icon_result" label="$app" icon.color=0x00e6e6e6 label.color=0x00e6e6e6 \
  --animate tanh 15 --set "$NAME" icon.color=0xffe6e6e6 label.color=0xffe6e6e6
