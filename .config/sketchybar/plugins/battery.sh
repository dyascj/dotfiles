#!/bin/bash

batt=$(pmset -g batt)
pct=$(grep -Eo '[0-9]+%' <<<"$batt" | tr -d %)
[ -n "$pct" ] || exit 0 # no battery, desktop Mac

case $pct in
  100 | 9[0-9]) icon= ;;
  [6-8][0-9]) icon= ;;
  [3-5][0-9]) icon= ;;
  [1-2][0-9]) icon= ;;
  *) icon= ;;
esac

# Grey like the rest, rose only when it's low and unplugged
color=0xff5a5a5a
if grep -q 'AC Power' <<<"$batt"; then
  icon=
elif [ "$pct" -le 20 ]; then
  color=0xfff4a6b4
fi

sketchybar --set "$NAME" icon="$icon" icon.color=$color label="$pct%"
