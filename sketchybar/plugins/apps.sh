#!/bin/bash

# Menu bar apps display for SketchyBar
# Shows specific background/menu bar apps with native icons and hover tooltips

PLUGIN_DIR="$CONFIG_DIR/plugins"

# Source the icon map for native app icons
source "$PLUGIN_DIR/icon_map.sh"

# Colors from coffee theme
ICON_COLOR="0xfffbe6b2"
ACCENT_COLOR="0xffe6b55a"
INACTIVE_COLOR="0xff7a6a52"
HIGHLIGHT_BG="0xff3a2d21"
BAR_COLOR="0xf0211c16"

# ========================================
# CONFIGURE YOUR MENU BAR APPS HERE
# ========================================
MENU_BAR_APPS=(
    "Claude"
    "Mullvad VPN"
    "Superwhisper"
)
# ========================================

# Get the app icon using the icon map
get_app_icon() {
    __icon_map "$1"
    if [[ -n "$icon_result" ]]; then
        echo "$icon_result"
    else
        echo ":default:"
    fi
}

# Sanitize app name for use as sketchybar item name
sanitize_name() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -cd '[:alnum:]_'
}

# Check if an app is running
is_app_running() {
    pgrep -xq "$1" 2>/dev/null || pgrep -fq "$1.app" 2>/dev/null
}

# Handle mouse events for tooltips
if [[ "$SENDER" == "mouse.entered" ]]; then
    sketchybar --set "$NAME" popup.drawing=on
    exit 0
elif [[ "$SENDER" == "mouse.exited" ]]; then
    sketchybar --set "$NAME" popup.drawing=off
    exit 0
fi

# Create/update menu bar app items
update_apps() {
    for app_name in "${MENU_BAR_APPS[@]}"; do
        item_name="app.$(sanitize_name "$app_name")"
        icon=$(get_app_icon "$app_name")

        # Check if app is running (dim if not)
        if pgrep -qi "$(echo "$app_name" | tr ' ' '.')" 2>/dev/null || \
           osascript -e "tell application \"System Events\" to (name of processes) contains \"$app_name\"" 2>/dev/null | grep -q "true"; then
            icon_color="$ICON_COLOR"
        else
            icon_color="$INACTIVE_COLOR"
        fi

        # Check if item already exists
        if sketchybar --query "$item_name" &>/dev/null; then
            # Just update color
            sketchybar --set "$item_name" icon.color="$icon_color"
        else
            # Create new item
            sketchybar --add item "$item_name" left \
                --set "$item_name" \
                    icon="$icon" \
                    icon.font="sketchybar-app-font:Regular:16.0" \
                    icon.color="$icon_color" \
                    icon.padding_left=4 \
                    icon.padding_right=4 \
                    label.drawing=off \
                    background.color="$HIGHLIGHT_BG" \
                    background.corner_radius=6 \
                    background.height=26 \
                    background.drawing=off \
                    click_script="open -a '$app_name'" \
                    script="$PLUGIN_DIR/apps.sh" \
                    popup.align=center \
                    popup.background.color="$BAR_COLOR" \
                    popup.background.corner_radius=8 \
                    popup.background.border_color="$HIGHLIGHT_BG" \
                    popup.background.border_width=1 \
                    popup.drawing=off \
                --subscribe "$item_name" mouse.entered mouse.exited \
                --move "$item_name" after running_apps

            # Add tooltip
            sketchybar --add item "${item_name}.tooltip" popup."$item_name" \
                --set "${item_name}.tooltip" \
                    icon.drawing=off \
                    label="$app_name" \
                    label.font="Hack Nerd Font:Regular:12.0" \
                    label.color="$ICON_COLOR" \
                    label.padding_left=10 \
                    label.padding_right=10 \
                    background.drawing=off
        fi
    done
}

update_apps
