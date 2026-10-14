#!/bin/bash

# Paints the five workspaces with their apps' icons, washes the focused one
# white, and shows whether windows are tiling or free

source "$CONFIG_DIR/helpers/icon_map.sh"
source "$CONFIG_DIR/helpers/ash.sh"

focused=$(aerospace list-workspaces --focused 2>/dev/null)
args=()
for ws in 1 2 3 4 5; do
  icons=""
  while IFS= read -r app; do
    [ -n "$app" ] || continue
    __icon_map "$app"
    icons+="$icon_result"
  done < <(aerospace list-windows --workspace "$ws" --format '%{app-name}' 2>/dev/null | sort -u)

  # Colors rather than highlight flags, so the switch crossfades instead of snapping
  if [ "$ws" = "$focused" ]; then wash=$WASH ink=$TEXT; else wash=$CLEAR ink=$DIM; fi
  has_apps=off
  [ -n "$icons" ] && has_apps=on
  args+=(--set "space.$ws" background.color=$wash icon.color=$ink label.color=$ink
    label="$icons" label.drawing=$has_apps)
done

# Grid when tiling, overlapping windows when free
if [ "$("$HOME/.config/aerospace/mode.sh" status)" = free ]; then
  args+=(--set layout icon=󰖲 --set layout.mode icon="Tiling mode")
else
  args+=(--set layout icon=󰕰 --set layout.mode icon="Free mode")
fi

sketchybar --animate tanh 12 "${args[@]}"
