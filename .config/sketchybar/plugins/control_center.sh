#!/bin/bash

# Control Center: the stock switches, brightness and volume sliders, every sound
# output with AirPods battery (and a tap to connect them), and what's playing.
# Called with no argument it refreshes, with one it flips that control first.

source "$CONFIG_DIR/helpers/ash.sh"
me="$CONFIG_DIR/plugins/control_center.sh"

case "$NAME:$SENDER" in
  control_center:mouse.exited.global) sketchybar --set control_center popup.drawing=off; exit 0 ;;
  cc.volume:mouse.clicked) osascript -e "set volume output volume $PERCENTAGE"; exit 0 ;;
  cc.volume:volume_change) sketchybar --set cc.volume slider.percentage="$INFO" --set cc.sound label="$INFO%"; exit 0 ;;
  cc.brightness:mouse.clicked) "$CCCTL" brightness "$PERCENTAGE"; sketchybar --set cc.display label="$PERCENTAGE%"; exit 0 ;;
  control_center:mouse.clicked) sketchybar --set control_center popup.drawing=toggle ;; # open first, fill in after
esac

wifi_dev=$(networksetup -listallhardwareports | awk '/Wi-Fi/ {getline; print $2}')
close="sketchybar --set control_center popup.drawing=off"

case "$1" in
  wifi)
    if networksetup -getairportpower "$wifi_dev" | grep -q On; then power=off; else power=on; fi
    networksetup -setairportpower "$wifi_dev" $power ;;
  bluetooth) "$CCCTL" bluetooth toggle ;;
  # Off, Contacts Only, Everyone, round again. Handoff blinks while AirDrop restarts.
  airdrop)
    case $("$CCCTL" airdrop) in off) next=contacts ;; contacts) next=everyone ;; *) next=off ;; esac
    "$CCCTL" airdrop $next ;;
  # Focus runs through a Shortcut, the only way in macOS allows
  focus)
    $close
    if shortcuts list | grep -qx "Toggle Focus"; then
      shortcuts run "Toggle Focus"
    else
      open "x-apple.systempreferences:com.apple.Focus-Settings.extension"
    fi
    exit 0 ;;
  dark) osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to not dark mode' ;;
  output) "$CCCTL" output "$2" ;;
  # Connect AirPods, wait for them to turn up as a sound output, then switch to them
  connect)
    name=$("$CCCTL" airpods | awk -F'\t' -v a="$2" '$2 == a {print $1}')
    "$CCCTL" connect "$2"
    for _ in 1 2 3 4 5 6 7 8 9 10; do
      uid=$("$CCCTL" outputs | awk -F'\t' -v n="$name" '$1 == n {print $2}')
      [ -n "$uid" ] && { "$CCCTL" output "$uid"; break; }
      sleep 1
    done ;;
  media) "$CCCTL" media "$2" ;;
esac

on_off() { if [ "$1" = true ]; then echo On; else echo Off; fi; }

airdrop=$("$CCCTL" airdrop)
case $airdrop in contacts) airdrop="Contacts" ;; everyone) airdrop="Everyone" ;; *) airdrop="Off" ;; esac
dark=$([ "$(defaults read -g AppleInterfaceStyle 2>/dev/null)" = Dark ] && echo true)
brightness=$("$CCCTL" brightness)
volume=$(osascript -e 'output volume of (get volume settings)')

sketchybar --set cc.wifi label="$(networksetup -getairportpower "$wifi_dev" | awk '{print $NF}')" \
  --set cc.bluetooth label="$("$CCCTL" bluetooth | sed 's/on/On/;s/off/Off/')" \
  --set cc.airdrop label="$airdrop" \
  --set cc.dark label="$(on_off "$dark")" \
  --set cc.display label="$brightness%" --set cc.brightness slider.percentage="$brightness" \
  --set cc.sound label="$volume%" --set cc.volume slider.percentage="$volume"

# Everything after the sliders is rebuilt, since popup rows can't be reordered
sketchybar --remove '/cc\.list\..*/' >/dev/null 2>&1

menu_label control_center cc.list.outputs "Output"
outputs=$("$CCCTL" outputs)
airpods=$("$CCCTL" airpods)
i=0
while IFS=$'\t' read -r name uid current _; do
  i=$((i + 1))
  # AirPods show their battery, the lower bud for a pair
  battery=$(awk -F'\t' -v n="$name" '$1 == n && $3 == 1 {print $4}' <<<"$airpods" |
    tr '/' '\n' | grep -v -- - | sort -n | head -1)
  detail=${battery:+$battery%}
  [ "$current" = 1 ] && detail="$detail ✓"
  menu_row control_center "cc.list.out$i" "$name" "${detail# }" "\"$me\" output $uid"
done <<<"$outputs"

# AirPods that aren't a sound output yet get a row that connects them
while IFS=$'\t' read -r name address connected battery; do
  [ -n "$address" ] || continue
  awk -F'\t' -v n="$name" '$1 == n {found = 1} END {exit !found}' <<<"$outputs" && continue
  i=$((i + 1))
  detail=Connect
  [ "$connected" = 1 ] && [ "$battery" != - ] && detail="${battery%%/*}% Connect"
  menu_row control_center "cc.list.out$i" "$name" "$detail" "\"$me\" connect $address"
done <<<"$airpods"

# Now playing, with play/pause on the song and a row to skip
IFS=$'\t' read -r title artist _ playing < <("$CCCTL" nowplaying)
if [ -n "$title" ]; then
  menu_sep control_center cc.list.sep
  menu_label control_center cc.list.playing "Now Playing" "$([ "$playing" = 1 ] && echo Playing || echo Paused)"
  menu_row control_center cc.list.song "$title" "$artist" "\"$me\" media toggle"
  menu_row control_center cc.list.next "Next" "⏭" "\"$me\" media next"
fi
menu_sep control_center cc.list.bottom "$CLEAR"
