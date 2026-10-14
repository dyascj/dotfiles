#!/bin/bash

# The Apple menu: the button behaves like the real one (see menu_event),
# and each row closes the menu and runs its action
source "$CONFIG_DIR/helpers/ash.sh"

if [ "$NAME" = apple ]; then
  menu_event apple "$SENDER"
  exit 0
fi

menu_close apple
case "$1" in
  about) open -a "About This Mac" ;;
  settings) open -a "System Settings" ;;
  appstore) open -a "App Store" ;;
  # Pressing the real shortcut needs Accessibility, Activity Monitor doesn't
  forcequit) osascript -e 'tell application "System Events" to key code 53 using {command down, option down}' ||
    open -a "Activity Monitor" ;;
  sleep) pmset sleepnow ;;
  # loginwindow asks to confirm these, same as the real menu
  restart) osascript -e 'tell application "loginwindow" to «event aevtrrst»' ;;
  shutdown) osascript -e 'tell application "loginwindow" to «event aevtrsdn»' ;;
  logout) osascript -e 'tell application "loginwindow" to «event aevtlogo»' ;;
  # Sleeping the display locks it, since the password is asked for immediately
  lock) pmset displaysleepnow ;;
esac
