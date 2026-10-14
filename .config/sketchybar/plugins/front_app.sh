#!/bin/bash

# INFO has the app name on a switch; on startup, ask macOS who's in front
app=$INFO
[ -n "$app" ] || app=$(lsappinfo info "$(lsappinfo front)" | head -1 | cut -d'"' -f2)

source "$CONFIG_DIR/helpers/icon_map.sh"
__icon_map "$app"
sketchybar --set "$NAME" icon="$icon_result" label="$app"
