#!/bin/bash

# Paints the five workspaces with their apps' icons, washes the focused one
# white, and shows whether windows are tiling or free

source "$CONFIG_DIR/helpers/icon_map.sh"

focused=$(aerospace list-workspaces --focused 2>/dev/null)
args=()
for ws in 1 2 3 4 5; do
  icons=""
  while IFS= read -r app; do
    [ -n "$app" ] || continue
    __icon_map "$app"
    icons+="$icon_result"
  done < <(aerospace list-windows --workspace "$ws" --format '%{app-name}' 2>/dev/null | sort -u)

  here=false
  [ "$ws" = "$focused" ] && here=true
  has_apps=off
  [ -n "$icons" ] && has_apps=on
  args+=(--set "space.$ws" background.drawing=$here icon.highlight=$here
    label.highlight=$here label="$icons" label.drawing=$has_apps)
done

# Grid when tiling, overlapping windows when free
if [ "$("$HOME/.config/aerospace/mode.sh" status)" = free ]; then
  args+=(--set layout icon=󰖲 --set layout.mode icon="Tiling mode")
else
  args+=(--set layout icon=󰕰 --set layout.mode icon="Free mode")
fi

sketchybar "${args[@]}"
