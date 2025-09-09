#!/bin/bash

###############################################################################
# GNOME Wallpaper Changer Script
#
# Randomly selects an image from a specified directory and sets it as the
# GNOME desktop wallpaper. Optionally sends desktop notifications.
#
# Usage:
#   - Configure WALLPAPER_DIR to point to your wallpapers folder.
#   - Optionally enable notifications.
###############################################################################

# --- User Configuration ---

WALLPAPER_DIR="$HOME/Wallpapers"      # Directory containing wallpaper images
PICTURE_OPTIONS="zoom"                # GNOME wallpaper display mode
ENABLE_NOTIFICATIONS="false"          # "true" to enable desktop notifications

# --- Utility Functions ---

# Sends a desktop notification if enabled
send_notification() {
    if [[ "$ENABLE_NOTIFICATIONS" == "true" ]]; then
        notify-send "$1" "$2"
    fi
}

# Prints error to stderr, sends notification, and exits
show_error_and_exit() {
    echo "Error: $1" >&2
    send_notification "Wallpaper Script Error" "$1"
    exit 1
}

# --- Main Script ---

# 1. Verify wallpaper directory exists
if [[ ! -d "$WALLPAPER_DIR" ]]; then
    show_error_and_exit "Wallpaper directory '$WALLPAPER_DIR' not found. Please create it or update the path."
fi

# 2. Select a random image file (jpg, jpeg, png)
NEW_WALLPAPER=$(find "$WALLPAPER_DIR" -type f -iregex '.*\.\(jpg\|jpeg\|png\)$' | shuf -n 1)

# 3. Ensure an image was found
if [[ -z "$NEW_WALLPAPER" ]]; then
    show_error_and_exit "No image files found in '$WALLPAPER_DIR'. Please add jpg, jpeg, or png files."
fi

# 4. Set wallpaper using GNOME gsettings
if ! gsettings set org.gnome.desktop.background picture-uri "file://$NEW_WALLPAPER"; then
    show_error_and_exit "Failed to set primary wallpaper URI."
fi

if ! gsettings set org.gnome.desktop.background picture-uri-dark "file://$NEW_WALLPAPER"; then
    show_error_and_exit "Failed to set dark theme wallpaper URI."
fi

if ! gsettings set org.gnome.desktop.background picture-options "$PICTURE_OPTIONS"; then
    show_error_and_exit "Failed to set wallpaper display options."
fi

# 5. Notify user of success
send_notification "Wallpaper Changed" "New wallpaper: $(basename "$NEW_WALLPAPER")"
# Optional: Uncomment the line below for console output
#echo "Wallpaper changed to: $NEW_WALLPAPER"

exit 0