#!/bin/bash

# The Apple menu: a click opens it, leaving closes it, and each row runs its action
case "$SENDER" in
  mouse.exited.global) sketchybar --set apple popup.drawing=off; exit 0 ;;
  mouse.clicked) [ "$NAME" = apple ] && { sketchybar --set apple popup.drawing=toggle; exit 0; } ;;
esac

sketchybar --set apple popup.drawing=off
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
