#!/bin/bash

# --- Configuration ---
# Nama folder utama proyek Anda setelah di-clone
PROJECT_ROOT_DIR="gnomeChangeWallpaper"

# Direktori tujuan untuk Scripts dan Wallpapers (home directory user)
INSTALL_DIR="$HOME"

# Nama sub-direktori tempat skrip wallpaper berada di dalam proyek Anda
SCRIPTS_SUBDIR="Scripts"
# Nama sub-direktori tempat wallpaper berada di dalam proyek Anda
WALLPAPERS_SUBDIR="Wallpapers"

# Konfigurasi Shortcut GNOME
SHORTCUT_NAME="Change Wallpaper"
# SHORTCUT_COMMAND akan didefinisikan setelah path skrip ditemukan
SHORTCUT_BINDING="<Control><Alt>w" # Ctrl+Alt+W

# Enable or disable desktop notifications: "true" or "false"
ENABLE_NOTIFICATIONS="true" 

# --- Functions ---

# Function to display a desktop notification (if enabled)
send_notification() {
    if [ "$ENABLE_NOTIFICATIONS" = "true" ]; then
        notify-send "$1" "$2"
    fi
}

# Function to display an error message and exit
# It prints to stderr and validates if notify-send is available before trying to use it.
show_error_and_exit() {
    echo "Error: $1" >&2 # Send output to stderr
    # Check if notify-send exists before calling it
    if command -v notify-send &> /dev/null && [ "$ENABLE_NOTIFICATIONS" = "true" ]; then
        notify-send "Installation Error" "$1"
    fi
    exit 1
}

# --- Script Execution ---

echo "Starting installation process for Gnome Change Wallpaper..."
send_notification "Gnome Change Wallpaper Installation" "Starting installation..."

# 1. Determine the absolute path to the project root directory.
# This method is more robust as it finds the directory where install.sh itself resides,
# then goes up to the project root.
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
# Assuming install.sh is directly inside PROJECT_ROOT_DIR, we need to go one level up.
# If install.sh is in a subdirectory (e.g., inside 'Installer' folder), adjust PROJECT_BASE_PATH
# to go up more levels as needed.
PROJECT_BASE_PATH=$(dirname "$SCRIPT_DIR") 

# Validate that the determined path matches our expected project root name
if [[ "$(basename "$PROJECT_BASE_PATH")" != "$PROJECT_ROOT_DIR" ]]; then
    show_error_and_exit "Could not reliably determine project root. Expected '$PROJECT_ROOT_DIR', but found '$(basename "$PROJECT_BASE_PATH")'. Please ensure '$PROJECT_ROOT_DIR' is the parent directory of install.sh."
fi

echo "Project base path detected: $PROJECT_BASE_PATH"


# 2. Periksa apakah folder Scripts ada di sumber.
SOURCE_SCRIPTS_PATH="$PROJECT_BASE_PATH/$SCRIPTS_SUBDIR"
if [ ! -d "$SOURCE_SCRIPTS_PATH" ]; then
    show_error_and_exit "Source directory '$SOURCE_SCRIPTS_PATH' not found. Ensure 'Scripts' folder is present in your project."
fi

# 3. Periksa apakah folder Wallpapers ada di sumber.
SOURCE_WALLPAPERS_PATH="$PROJECT_BASE_PATH/$WALLPAPERS_SUBDIR"
if [ ! -d "$SOURCE_WALLPAPERS_PATH" ]; then
    show_error_and_exit "Source directory '$SOURCE_WALLPAPERS_PATH' not found. Ensure 'Wallpapers' folder is present in your project."
fi

# --- Salin folder jika belum ada di direktori home ---

# 4. Salin folder Scripts ke direktori home jika belum ada.
DEST_SCRIPTS_PATH="$INSTALL_DIR/$SCRIPTS_SUBDIR"
if [ ! -d "$DEST_SCRIPTS_PATH" ]; then
    echo "Copying '$SCRIPTS_SUBDIR' to '$INSTALL_DIR/'..."
    cp -R "$SOURCE_SCRIPTS_PATH" "$INSTALL_DIR/" \
        || show_error_and_exit "Failed to copy '$SCRIPTS_SUBDIR' to '$INSTALL_DIR/'. Check permissions."
else
    echo "Directory '$DEST_SCRIPTS_PATH' already exists. Skipping copy."
fi

# 5. Salin folder Wallpapers ke direktori home jika belum ada.
DEST_WALLPAPERS_PATH="$INSTALL_DIR/$WALLPAPERS_SUBDIR"
if [ ! -d "$DEST_WALLPAPERS_PATH" ]; then
    echo "Copying '$WALLPAPERS_SUBDIR' to '$INSTALL_DIR/'..."
    cp -R "$SOURCE_WALLPAPERS_PATH" "$INSTALL_DIR/" \
        || show_error_and_exit "Failed to copy '$WALLPAPERS_SUBDIR' to '$INSTALL_DIR/'. Check permissions."
else
    echo "Directory '$DEST_WALLPAPERS_PATH' already exists. Skipping copy."
fi

# 6. Jadikan skrip change_wallpaper.sh dapat dieksekusi.
# Skrip ini seharusnya sudah berada di ~/Scripts/
DEST_CHANGE_WALLPAPER_SCRIPT="$INSTALL_DIR/$SCRIPTS_SUBDIR/change_wallpaper.sh"
if [ -f "$DEST_CHANGE_WALLPAPER_SCRIPT" ]; then
    echo "Making '$DEST_CHANGE_WALLPAPER_SCRIPT' executable..."
    chmod +x "$DEST_CHANGE_WALLPAPER_SCRIPT" \
        || show_error_and_exit "Failed to make '$DEST_CHANGE_WALLPAPER_SCRIPT' executable. Check file permissions."
else
    show_error_and_exit "Could not find 'change_wallpaper.sh' at '$DEST_CHANGE_WALLPAPER_SCRIPT' after copy. Copy operation might have failed."
fi

# --- Membuat Shortcut GNOME ---
echo "Creating GNOME custom keyboard shortcut: '$SHORTCUT_NAME' with binding '$SHORTCUT_BINDING'..."

# Define the command for the shortcut, now that we know the script's final location
SHORTCUT_COMMAND="$DEST_CHANGE_WALLPAPER_SCRIPT"

# Get existing custom keybindings
CURRENT_CUSTOM_KEYBINDINGS=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings) \
    || show_error_and_exit "Failed to retrieve existing custom keybindings from gsettings."

# Define a unique path for the new shortcut
NEW_SHORTCUT_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom-change-wallpaper/"

# Add the new shortcut path to the existing list if it's not already there
if [[ ! "$CURRENT_CUSTOM_KEYBINDINGS" == *"$NEW_SHORTCUT_PATH"* ]]; then
    # Remove the trailing ']' and append the new path, then re-add ']'
    UPDATED_KEYBINDINGS=$(echo "$CURRENT_CUSTOM_KEYBINDINGS" | sed "s/]$/, '$NEW_SHORTCUT_PATH']/")
    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$UPDATED_KEYBINDINGS" \
        || show_error_and_exit "Failed to update custom-keybindings list in gsettings."
    echo "Added new shortcut path to custom-keybindings list."
else
    echo "Shortcut path '$NEW_SHORTCUT_PATH' already exists in custom-keybindings list. Updating existing entry."
fi

# Set the shortcut details
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$NEW_SHORTCUT_PATH name "$SHORTCUT_NAME" \
    || show_error_and_exit "Failed to set shortcut name in gsettings."
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$NEW_SHORTCUT_PATH command "$SHORTCUT_COMMAND" \
    || show_error_and_exit "Failed to set shortcut command in gsettings."
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$NEW_SHORTCUT_PATH binding "$SHORTCUT_BINDING" \
    || show_error_and_exit "Failed to set shortcut binding in gsettings."

echo "GNOME shortcut created/updated successfully!"
send_notification "Gnome Change Wallpaper Installation" "Scripts, Wallpapers, and a Ctrl+Alt+W shortcut have been installed!"

exit 0