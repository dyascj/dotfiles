#!/bin/bash

# Tailscale: white when connected and grey when off, with the exit node's
# city beside it. The popup switches it, copies IPs and picks an exit node.

[ "$SENDER" = mouse.exited.global ] && { sketchybar --set tailscale popup.drawing=off; exit 0; }

source "$CONFIG_DIR/helpers/ash.sh"
TS=/Applications/Tailscale.app/Contents/MacOS/Tailscale # the app is its own CLI

json=$("$TS" status --json 2>/dev/null)
exit_node=$(jq -r '[.Peer[]? | select(.ExitNode)][0].DNSName // empty' <<<"$json")

case "$1" in
  power)
    if [ "$(jq -r .BackendState <<<"$json")" = Running ]; then "$TS" down; else "$TS" up; fi ;;
  # Off turns it on with the exit node Tailscale suggests, on turns it off
  exit)
    if [ -n "$exit_node" ]; then
      "$TS" set --exit-node=
    else
      "$TS" set --exit-node="$("$TS" exit-node suggest | awk '/^Suggested/ {print $4}')"
    fi ;;
  copy) printf %s "$2" | pbcopy; sketchybar --set tailscale popup.drawing=off; exit 0 ;;
esac
[ -n "$1" ] && json=$("$TS" status --json 2>/dev/null)

state=$(jq -r .BackendState <<<"$json")
exit_node=$(jq -r '[.Peer[]? | select(.ExitNode)][0].DNSName // empty' <<<"$json")
city=${exit_node%%.*}  # us-chi-wg-307.mullvad.ts.net. -> us-chi
city=${city%%-wg-*}

color=$DIM
[ "$state" = Running ] && color=$TEXT
sketchybar --set tailscale icon.color=$color label="$city" label.drawing="$([ -n "$city" ] && echo on || echo off)"

# The popup is only rebuilt when it's opened or one of its rows is used
[ "$SENDER" = mouse.clicked ] || exit 0

sketchybar --set tailscale.power label="$([ "$state" = Running ] && echo Connected || echo Off)" \
  --set tailscale.self label="$(jq -r '.Self.TailscaleIPs[0] // "-"' <<<"$json")"

# Everything below "This Mac" is rebuilt, since popup rows can't be reordered
sketchybar --remove '/tailscale\.list\..*/' >/dev/null 2>&1

# Your own devices, online first. Mullvad's hundreds of exit nodes stay out.
i=0
while IFS=$'\t' read -r name ip online; do
  i=$((i + 1))
  [ "$online" = true ] || ip=offline
  menu_row tailscale "tailscale.list.peer$i" "$name" "$ip" "\"$CONFIG_DIR/plugins/tailscale.sh\" copy $ip"
done < <(jq -r '[.Peer[]? | select(.ExitNodeOption | not)] | sort_by(.Online | not)[]
  | [(.DNSName | split(".")[0]), .TailscaleIPs[0], .Online] | @tsv' <<<"$json")

menu_sep tailscale tailscale.list.sep
menu_row tailscale tailscale.list.exit "Exit node" "${city:-Off}" "\"$CONFIG_DIR/plugins/tailscale.sh\" exit"
menu_row tailscale tailscale.list.open "Open Tailscale…" "" "sketchybar --set tailscale popup.drawing=off; open -a Tailscale"
menu_sep tailscale tailscale.list.bottom "$CLEAR"

[ "$NAME" = tailscale ] && sketchybar --set tailscale popup.drawing=toggle
