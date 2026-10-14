#!/bin/bash

# Ash, written as sketchybar's 0xAARRGGBB, and the pieces popup menus are built from.
# Sourced by sketchybarrc and by any plugin that builds menu rows.

TEXT=0xffe6e6e6
DIM=0xff5a5a5a
WASH=0x1affffff     # 10% white, Ash's selection
HOVER=0x0dffffff    # 5% white, Ash's hover
HAIRLINE=0x12ffffff # 7% white, Ash's borders
CLEAR=0x00000000

MENU_WIDTH=260

# The Control Center helper, built from helpers/ccctl.swift by sketchybarrc
CCCTL="$HOME/.cache/sketchybar/ccctl"

# Popups are black glass: a touch darker than the bar so text reads, thin enough
# that the blurred desktop still shows through
POPUP=(popup.background.color=0xb3000000 popup.blur_radius=40
  popup.background.corner_radius=10 popup.background.border_width=1
  popup.background.border_color=$HAIRLINE popup.height=1 popup.y_offset=6)

# A row: title on the left, grey detail on the right, washed white under the mouse
menu_row() { # parent name title detail click_script
  sketchybar --add item "$2" "popup.$1" \
    --set "$2" width=$MENU_WIDTH padding_left=6 padding_right=6 \
      icon="$3" icon.font="SF Mono:Medium:12.0" icon.color=$TEXT \
      icon.width=150 icon.padding_left=10 icon.padding_right=0 \
      label="$4" label.color=$DIM label.align=right \
      label.width=$((MENU_WIDTH - 160)) label.padding_left=0 label.padding_right=10 \
      background.color=$CLEAR background.height=24 background.corner_radius=6 \
      script="$CONFIG_DIR/plugins/hover.sh" \
      click_script="sketchybar --set $2 background.color=$CLEAR; $5" \
    --subscribe "$2" mouse.entered mouse.exited
}

# A hairline between groups of rows, or empty space when the color is clear
menu_sep() { # parent name [color]
  sketchybar --add item "$2" "popup.$1" \
    --set "$2" width=$MENU_WIDTH padding_left=12 padding_right=12 icon.drawing=off \
      label=" " label.font="SF Mono:Regular:6.0" \
      background.color="${3:-$HAIRLINE}" background.height=1
}

# A grey heading over a group of rows, with an optional detail on the right
menu_label() { # parent name title [detail]
  sketchybar --add item "$2" "popup.$1" \
    --set "$2" width=$MENU_WIDTH padding_left=6 padding_right=6 \
      icon="$3" icon.font="SF Mono:Semibold:11.0" icon.color=$DIM \
      icon.width=150 icon.padding_left=10 icon.padding_right=0 \
      label="$4" label.font="SF Mono:Medium:11.0" label.color=$DIM label.align=right \
      label.width=$((MENU_WIDTH - 160)) label.padding_left=0 label.padding_right=10 \
      background.color=$CLEAR background.height=22
}

# Menu buttons behave like the real menu bar. A click opens the menu and lights
# the button with the 10% wash; with a menu open, hovering another button
# switches to it; leaving the bar closes it. Hover alone fades in the 5% wash.
MENU_STATE="${TMPDIR:-/tmp}/sketchybar-open-menu"

menu_open() { # name
  local other
  other=$(cat "$MENU_STATE" 2>/dev/null)
  echo "$1" >"$MENU_STATE"
  [ -n "$other" ] && [ "$other" != "$1" ] &&
    sketchybar --set "$other" popup.drawing=off background.color=$CLEAR
  sketchybar --set "$1" popup.drawing=on --animate tanh 8 --set "$1" background.color=$WASH
}

menu_close() { # name [wash left behind, the hover one if the mouse is still on it]
  [ "$(cat "$MENU_STATE" 2>/dev/null)" = "$1" ] && rm -f "$MENU_STATE"
  sketchybar --set "$1" popup.drawing=off --animate tanh 10 --set "$1" background.color="${2:-$CLEAR}"
}

# Handles a menu button's mouse events. Succeeds when it just opened the menu,
# so the caller knows to fill it in.
menu_event() { # name sender
  local open
  open=$(cat "$MENU_STATE" 2>/dev/null)
  case $2 in
    mouse.clicked)
      if [ "$open" = "$1" ]; then menu_close "$1" $HOVER; return 1; fi
      menu_open "$1" ;;
    mouse.entered)
      if [ -n "$open" ] && [ "$open" != "$1" ]; then menu_open "$1"; return 0; fi
      [ "$open" = "$1" ] || sketchybar --animate tanh 10 --set "$1" background.color=$HOVER
      return 1 ;;
    mouse.exited)
      [ "$open" = "$1" ] || sketchybar --animate tanh 10 --set "$1" background.color=$CLEAR
      return 1 ;;
    mouse.exited.global)
      [ "$open" = "$1" ] && menu_close "$1"
      return 1 ;;
    *) return 1 ;;
  esac
}

# The look every menu button shares: a rounded wash behind it, clear at rest
MENU_BUTTON=(background.color=$CLEAR background.height=24 background.corner_radius=7
  background.drawing=on icon.padding_left=8 icon.padding_right=8)
