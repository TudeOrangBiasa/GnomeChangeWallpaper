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
SHORTCUT_COMMAND="$INSTALL_DIR/$SCRIPTS_SUBDIR/change_wallpaper.sh"
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
# It prints to stderr and sends a desktop notification (if enabled).
show_error_and_exit() {
    echo "Error: $1" >&2 # Send output to stderr
    send_notification "Installation Error" "$1"
    exit 1
}

# --- Script Execution ---

echo "Starting installation process for Gnome Change Wallpaper..."
send_notification "Gnome Change Wallpaper Installation" "Starting installation..."

# 1. Pastikan skrip dijalankan dari dalam direktori proyek yang benar.
# Ini memeriksa apakah kita berada di root proyek (gnomeChangeWallpaper).
CURRENT_DIR=$(pwd)
if [[ ! "$CURRENT_DIR" == *"/$PROJECT_ROOT_DIR"* ]]; then
    show_error_and_exit "Please run this script from inside the '$PROJECT_ROOT_DIR' directory or its subdirectories."
fi

# Dapatkan path absolut ke direktori root proyek (gnomeChangeWallpaper)
# Ini akan bekerja bahkan jika install.sh dijalankan dari sub-folder
PROJECT_BASE_PATH=$(dirname "$(dirname "$(readlink -f "$0")")")

echo "Project base path detected: $PROJECT_BASE_PATH"

# 2. Periksa apakah folder Scripts ada
SOURCE_SCRIPTS_PATH="$PROJECT_BASE_PATH/$SCRIPTS_SUBDIR"
if [ ! -d "$SOURCE_SCRIPTS_PATH" ]; then
    show_error_and_exit "Source directory '$SOURCE_SCRIPTS_PATH' not found. Ensure 'Scripts' folder is present."
fi

# 3. Periksa apakah folder Wallpapers ada
SOURCE_WALLPAPERS_PATH="$PROJECT_BASE_PATH/$WALLPAPERS_SUBDIR"
if [ ! -d "$SOURCE_WALLPAPERS_PATH" ]; then
    show_error_and_exit "Source directory '$SOURCE_WALLPAPERS_PATH' not found. Ensure 'Wallpapers' folder is present."
fi

# 4. Salin folder Scripts ke direktori home
echo "Copying '$SCRIPTS_SUBDIR' to '$INSTALL_DIR/'..."
cp -R "$SOURCE_SCRIPTS_PATH" "$INSTALL_DIR/" \
    || show_error_and_exit "Failed to copy '$SCRIPTS_SUBDIR' to '$INSTALL_DIR/'."

# 5. Salin folder Wallpapers ke direktori home
echo "Copying '$WALLPAPERS_SUBDIR' to '$INSTALL_DIR/'..."
cp -R "$SOURCE_WALLPAPERS_PATH" "$INSTALL_DIR/" \
    || show_error_and_exit "Failed to copy '$WALLPAPERS_SUBDIR' to '$INSTALL_DIR/'."

# 6. Jadikan skrip change_wallpaper.sh dapat dieksekusi
# Asumsi change_wallpaper.sh berada di ~/Scripts/
DEST_CHANGE_WALLPAPER_SCRIPT="$INSTALL_DIR/$SCRIPTS_SUBDIR/change_wallpaper.sh"
if [ -f "$DEST_CHANGE_WALLPAPER_SCRIPT" ]; then
    echo "Making '$DEST_CHANGE_WALLPAPER_SCRIPT' executable..."
    chmod +x "$DEST_CHANGE_WALLPAPER_SCRIPT" \
        || show_error_and_exit "Failed to make '$DEST_CHANGE_WALLPAPER_SCRIPT' executable."
else
    show_error_and_exit "Could not find 'change_wallpaper.sh' at '$DEST_CHANGE_WALLPAPER_SCRIPT' after copy."
fi

# --- Membuat Shortcut GNOME ---
echo "Creating GNOME custom keyboard shortcut: '$SHORTCUT_NAME' with binding '$SHORTCUT_BINDING'..."

# Mendapatkan daftar custom keybindings yang sudah ada
CURRENT_CUSTOM_KEYBINDINGS=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)

# Menentukan jalur unik untuk shortcut baru
NEW_SHORTCUT_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom-change-wallpaper/"

# Menambahkan jalur shortcut baru ke daftar yang sudah ada jika belum ada
if [[ ! "$CURRENT_CUSTOM_KEYBINDINGS" == *"$NEW_SHORTCUT_PATH"* ]]; then
    # Hapus kurung siku dan tambahkan jalur baru
    UPDATED_KEYBINDINGS=$(echo "$CURRENT_CUSTOM_KEYBINDINGS" | sed "s/]$/, '$NEW_SHORTCUT_PATH']/")
    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$UPDATED_KEYBINDINGS" \
        || show_error_and_exit "Failed to update custom-keybindings list."
else
    echo "Shortcut path already exists in custom-keybindings list. Updating existing entry."
fi

# Mengatur detail shortcut
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$NEW_SHORTCUT_PATH name "$SHORTCUT_NAME" \
    || show_error_and_exit "Failed to set shortcut name."
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$NEW_SHORTCUT_PATH command "$SHORTCUT_COMMAND" \
    || show_error_and_exit "Failed to set shortcut command."
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$NEW_SHORTCUT_PATH binding "$SHORTCUT_BINDING" \
    || show_error_and_exit "Failed to set shortcut binding."

echo "GNOME shortcut created/updated successfully!"
send_notification "Gnome Change Wallpaper Installation" "Scripts, Wallpapers, and a Ctrl+Alt+W shortcut have been installed!"

exit 0