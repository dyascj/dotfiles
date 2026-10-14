#!/bin/bash

# A menu button with nothing to fill in (the layout menu). Rows also call it
# as `popup.sh close <menu>` so the menu remembers it was closed.
source "$CONFIG_DIR/helpers/ash.sh"

if [ "$1" = close ]; then
  menu_close "$2"
  exit 0
fi
menu_event "$NAME" "$SENDER"
exit 0
