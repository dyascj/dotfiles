#!/bin/bash

# Tiling or free. Free floats every window so it moves and resizes like stock
# macOS, tiling snaps them all back into the grid. Workspaces work either way.
#
# Tiling uses smart stacking: each new window splits the one it opened next to,
# turning the split the other way each time, so windows spiral into a grid
# (two side by side, the third under the second, ...) instead of thin strips.

FLAG="$HOME/.cache/aerospace/free"

case "$1" in
  toggle)
    if [ -e "$FLAG" ]; then
      rm "$FLAG"
      layout=tiling
    else
      mkdir -p "$(dirname "$FLAG")" && touch "$FLAG"
      layout=floating
    fi
    aerospace list-windows --all --format '%{window-id}' | while read -r id; do
      aerospace layout --window-id "$id" "$layout" 2>/dev/null
    done
    # Back in tiling, let the rules float what should float (Settings, say)
    [ "$layout" = tiling ] && aerospace run-callback --for-every-window on-window-detected
    [ "$layout" = tiling ] && "$0" tidy
    sketchybar --trigger aerospace_change
    ;;

  # A new window. AeroSpace puts it right after the focused window, in the same
  # container. Joining the two flips their split, once there are 3+ tiled windows.
  adopt)
    if [ -e "$FLAG" ]; then
      aerospace layout --window-id "$AEROSPACE_WINDOW_ID" floating
    else
      # Only the window id is passed in, so look up which workspace it landed on
      ws=$(aerospace list-windows --all --format '%{window-id} %{workspace}' | awk -v id="$AEROSPACE_WINDOW_ID" '$1 == id {print $2}')
      tiled=$(aerospace list-windows --workspace "$ws" --format '%{window-layout}' | grep -c '_tiles')
      if [ "$tiled" -ge 3 ]; then
        if aerospace test '%{window-layout}' = h_tiles; then
          aerospace join-with --window-id "$AEROSPACE_WINDOW_ID" left
        elif aerospace test '%{window-layout}' = v_tiles; then
          aerospace join-with --window-id "$AEROSPACE_WINDOW_ID" up
        fi
      fi
    fi
    ;;

  # Rebuild the focused workspace into the smart stack and even out the sizes
  tidy)
    aerospace flatten-workspace-tree
    ids=()
    while read -r id layout; do
      case $layout in h_tiles) dir=right ;; v_tiles) dir=down ;; *) continue ;; esac
      ids+=("$id")
    done < <(aerospace list-windows --workspace focused --format '%{window-id} %{window-layout}')
    # Working back from the second-to-last, join each window with everything after it
    for ((i = ${#ids[@]} - 2; i >= 1; i--)); do
      aerospace join-with --window-id "${ids[i]}" "$dir"
    done
    aerospace balance-sizes
    ;;

  status) if [ -e "$FLAG" ]; then echo free; else echo tiling; fi ;;
esac
exit 0
