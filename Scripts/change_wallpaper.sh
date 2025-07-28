#!/bin/bash

# --- Configuration ---
# Define your wallpaper directory
WALLPAPER_DIR="$HOME/Wallpapers"

# Wallpaper display options: "zoom", "stretched", "scaled", "wallpaper", "center"
PICTURE_OPTIONS="zoom"

# Enable or disable desktop notifications: "true" or "false"
# Set to "true" to show notifications, "false" to hide them.
ENABLE_NOTIFICATIONS="false" 

# --- Main Functions ---

# Function to display a desktop notification (if enabled)
send_notification() {
    if [ "$ENABLE_NOTIFICATIONS" = "true" ]; then
        notify-send "$1" "$2"
    fi
}

# Function to display an error message and exit
# It prints to stderr and sends a desktop notification (if enabled).
show_error_and_exit() {
    echo "Error: $1" >&2 # Send output to stderr
    send_notification "Wallpaper Script Error" "$1"
    exit 1
}

# --- Script Execution ---

# 1. Ensure the wallpaper directory exists.
# If the directory is not found, an error message is displayed, and the script exits.
if [ ! -d "$WALLPAPER_DIR" ]; then
    show_error_and_exit "Wallpaper directory '$WALLPAPER_DIR' not found. Please create or adjust the directory path."
fi

# 2. Get a random image file from the directory.
# This command finds all files, then filters for common image extensions (case-insensitive),
# and finally picks one randomly using 'shuf -n 1'.
NEW_WALLPAPER=$(find "$WALLPAPER_DIR" -type f | grep -iE '\.(jpg|png|jpeg)$' | shuf -n 1)

# 3. Check if a wallpaper was successfully found.
# If no images are found, an error message is displayed, and the script exits.
if [ -z "$NEW_WALLPAPER" ]; then
    show_error_and_exit "No wallpapers found in '$WALLPAPER_DIR'. Please add some images (jpg, png, jpeg)."
fi

# 4. Set the new wallpaper using gsettings for GNOME desktop.
# The 'file://' prefix is crucial for picture URIs.
# Each 'gsettings' command is followed by '|| show_error_and_exit' to catch potential failures
# and provide immediate feedback via notification.
gsettings set org.gnome.desktop.background picture-uri "file://$NEW_WALLPAPER" \
    || show_error_and_exit "Failed to set primary wallpaper URI."

gsettings set org.gnome.desktop.background picture-uri-dark "file://$NEW_WALLPAPER" \
    || show_error_and_exit "Failed to set dark theme wallpaper URI."

gsettings set org.gnome.desktop.background picture-options "$PICTURE_OPTIONS" \
    || show_error_and_exit "Failed to set picture options."

# 5. Notify the user of a successful wallpaper change (if notifications are enabled).
# Displays a desktop notification showing the name of the new wallpaper.
send_notification "Wallpaper Changed Successfully" "New wallpaper: $(basename "$NEW_WALLPAPER")"

# Exit with a success status code.
exit 0