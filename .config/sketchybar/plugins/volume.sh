#!/bin/bash

# Clicking opens Control Center (its click_script); hovering fades the wash in
case $SENDER in mouse.entered | mouse.exited) exec "$CONFIG_DIR/plugins/bar_hover.sh" ;; esac

# INFO has the new volume on volume_change; ask macOS on startup
vol=${INFO:-$(osascript -e 'output volume of (get volume settings)')}

case $vol in
  100 | [6-9][0-9]) icon=󰕾 ;;
  [3-5][0-9]) icon=󰖀 ;;
  [1-9] | [1-2][0-9]) icon=󰕿 ;;
  *) icon=󰝟 ;;
esac

sketchybar --set "$NAME" icon="$icon" label="$vol%"
