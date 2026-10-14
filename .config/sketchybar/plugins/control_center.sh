#!/bin/bash

# Control Center, laid out like Apple's: switches up top, Display and Sound
# sliders with every sound output (AirPods show battery, a tap connects them),
# what's playing, then Dark Mode, screenshots and mirroring.
# Called with an argument it flips that control first, then refreshes.

source "$CONFIG_DIR/helpers/ash.sh"
me="$CONFIG_DIR/plugins/control_center.sh"

# The button: hover, open, switch and close like the real menu bar. Refresh
# only when it just opened. Clicking the volume icon opens it too.
if { [ "$NAME" = control_center ] || [ "$NAME" = volume ]; } && [ "${SENDER#mouse.}" != "$SENDER" ]; then
  if [ "$NAME" = volume ]; then
    [ "$(cat "$MENU_STATE" 2>/dev/null)" = control_center ] && { menu_close control_center; exit 0; }
    menu_open control_center
  else
    menu_event control_center "$SENDER" || exit 0
  fi
  NAME=control_center SENDER=refresh
fi
ON=󰔡
OFF=󰨙

case "$NAME:$SENDER" in
  cc.volume:mouse.clicked) osascript -e "set volume output volume $PERCENTAGE"; exit 0 ;;
  cc.volume:volume_change) sketchybar --set cc.volume slider.percentage="$INFO" --set cc.sound label="$INFO%"; exit 0 ;;
  cc.brightness:brightness_change) sketchybar --set cc.brightness slider.percentage="$INFO" --set cc.display label="$INFO%"; exit 0 ;;
  cc.brightness:mouse.clicked) "$CCCTL" brightness "$PERCENTAGE"; sketchybar --set cc.display label="$PERCENTAGE%"; exit 0 ;;
esac

close="menu_close control_center"
wifi_dev() { networksetup -listallhardwareports | awk '/Wi-Fi/ {getline; print $2}'; }

case "$1" in
  wifi)
    dev=$(wifi_dev)
    if networksetup -getairportpower "$dev" | grep -q On; then power=off; else power=on; fi
    networksetup -setairportpower "$dev" $power ;;
  bluetooth) "$CCCTL" bluetooth toggle ;;
  # Click turns AirDrop on (Contacts) or off, right-click opens it to Everyone.
  # Handoff blinks for a moment while AirDrop restarts.
  airdrop)
    if [ "$BUTTON" = right ]; then
      "$CCCTL" airdrop everyone
    elif [ "$("$CCCTL" airdrop)" = off ]; then
      "$CCCTL" airdrop contacts
    else
      "$CCCTL" airdrop off
    fi ;;
  # Focus runs through a Shortcut named Toggle Focus, the only way macOS allows
  focus)
    if shortcuts list | grep -qx "Toggle Focus"; then
      shortcuts run "Toggle Focus"
    else
      $close
      open -a Shortcuts
      exit 0
    fi ;;
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

# Ask everything at once, so a refresh takes as long as the slowest answer
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
networksetup -getairportpower "$(wifi_dev)" >"$tmp/wifi" &
"$CCCTL" bluetooth >"$tmp/bluetooth" &
"$CCCTL" airdrop >"$tmp/airdrop" &
shortcuts list >"$tmp/shortcuts" &
"$CCCTL" brightness >"$tmp/brightness" 2>/dev/null &
osascript -e 'output volume of (get volume settings)' >"$tmp/volume" &
"$CCCTL" outputs >"$tmp/outputs" &
"$CCCTL" airpods >"$tmp/airpods" &
"$CCCTL" nowplaying >"$tmp/playing" 2>/dev/null &
defaults read -g AppleInterfaceStyle >"$tmp/dark" 2>/dev/null &
wait

# A switch: white name and switch when on, grey when off
args=()
switch() { # item on|off
  if [ "$2" = on ]; then
    args+=(--set "$1" icon.color=$TEXT label="$ON" label.color=$TEXT)
  else
    args+=(--set "$1" icon.color=$DIM label="$OFF" label.color=$DIM)
  fi
}

switch cc.wifi "$(grep -q 'On$' "$tmp/wifi" && echo on)"
switch cc.bluetooth "$(cat "$tmp/bluetooth")"
airdrop=$(cat "$tmp/airdrop")
switch cc.airdrop "$([ "$airdrop" != off ] && echo on)"
args+=(--set cc.airdrop icon="AirDrop$([ "$airdrop" = everyone ] && echo ' · Everyone')")
if grep -qx "Toggle Focus" "$tmp/shortcuts"; then
  args+=(--set cc.focus icon.color=$TEXT label="Toggle" label.color=$DIM label.font="SF Mono:Medium:12.0")
else
  args+=(--set cc.focus icon.color=$DIM label="Set up" label.color=$DIM label.font="SF Mono:Medium:12.0")
fi

brightness=$(cat "$tmp/brightness")
if [ -n "$brightness" ]; then
  args+=(--set cc.display label="$brightness%" --set cc.brightness drawing=on slider.percentage="$brightness")
else
  args+=(--set cc.display label="-" --set cc.brightness drawing=off) # a display that can't be dimmed
fi
volume=$(cat "$tmp/volume")
args+=(--set cc.sound label="$volume%" --set cc.volume slider.percentage="$volume")

# Sound outputs, then AirPods that aren't one yet. Each row is name, detail and
# action split by $US: tabs would collapse an empty detail and shift the fields.
US=$'\x1f'
rows=()
while IFS=$'\t' read -r name uid current _; do
  [ -n "$uid" ] || continue
  battery=$(awk -F'\t' -v n="$name" '$1 == n && $3 == 1 {print $4}' "$tmp/airpods" |
    tr '/' '\n' | grep -v -- - | sort -n | head -1) # the lower bud for a pair
  detail=${battery:+$battery%}
  [ "$current" = 1 ] && detail="$detail ✓"
  rows+=("$name$US${detail# }$US\"$me\" output \"$uid\"")
done <"$tmp/outputs"
while IFS=$'\t' read -r name address connected battery; do
  [ -n "$address" ] || continue
  awk -F'\t' -v n="$name" '$1 == n {found = 1} END {exit !found}' "$tmp/outputs" && continue
  detail=Connect
  [ "$connected" = 1 ] && [ "$battery" != - ] && detail="${battery%%/*}% Connect"
  rows+=("$name$US$detail$US\"$me\" connect $address")
done <"$tmp/airpods"

title=$(cut -f1 "$tmp/playing")
artist=$(cut -f2 "$tmp/playing") # can be empty
playing=$(cut -f4 "$tmp/playing")

# Rebuild the rows under the sliders only when the set of rows changes.
# Popup rows can't be reordered, so a change means removing and re-adding them.
shape=$(printf '%s\n' "${rows[@]}" | cut -d "$US" -f1,3; [ -n "$title" ] && echo playing)
shape_file="$HOME/.cache/sketchybar/control_center.shape"
if [ "$shape" != "$(cat "$shape_file" 2>/dev/null)" ] ||
  ! sketchybar --query cc.list.bottom >/dev/null 2>&1; then
  sketchybar --remove '/cc\.list\..*/' >/dev/null 2>&1
  i=0
  for row in "${rows[@]}"; do
    i=$((i + 1))
    IFS=$US read -r name detail action <<<"$row"
    menu_row control_center "cc.list.out$i" "$name" "$detail" "$action"
  done
  if [ -n "$title" ]; then
    menu_sep control_center cc.list.playsep
    menu_label control_center cc.list.playing "Now Playing"
    menu_row control_center cc.list.song "" "" "\"$me\" media toggle"
    menu_row control_center cc.list.next "Next" "⏭" "\"$me\" media next"
  fi
  menu_sep control_center cc.list.sep
  menu_row control_center cc.list.dark "Dark Mode" "" "\"$me\" dark"
  sketchybar --set cc.list.dark label.font="Hack Nerd Font:Regular:16.0"
  shut="\"$CONFIG_DIR/plugins/popup.sh\" close control_center"
  menu_row control_center cc.list.capture "Capture Screen" "" "$shut; open -a Screenshot"
  menu_row control_center cc.list.mirror "Screen Mirroring" "" \
    "$shut; open x-apple.systempreferences:com.apple.Displays-Settings.extension"
  menu_sep control_center cc.list.bottom "$CLEAR"
  mkdir -p "$(dirname "$shape_file")" && printf '%s' "$shape" >"$shape_file"
fi

# Fill in what changes between refreshes: checkmarks, battery, the song
i=0
for row in "${rows[@]}"; do
  i=$((i + 1))
  IFS=$US read -r _ detail _ <<<"$row"
  args+=(--set "cc.list.out$i" label="$detail")
done
[ -n "$title" ] && args+=(--set cc.list.playing label="$([ "$playing" = 1 ] && echo Playing || echo Paused)"
  --set cc.list.song icon="$title" label="$artist")
switch cc.list.dark "$([ "$(cat "$tmp/dark")" = Dark ] && echo on)"

sketchybar "${args[@]}"
