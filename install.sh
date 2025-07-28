#!/bin/bash

# ==============================================================================
# GNOME Change Wallpaper Installer
#
# This script automates the installation of a custom GNOME keyboard shortcut
# to change the desktop wallpaper. It copies necessary script files and
# wallpaper directories to the user's home directory and configures the
# GNOME gsettings for the custom shortcut.
#
# Author: Your Name (or leave blank if preferred)
# Version: 1.0.0
# Date: July 28, 2025
#
# Dependencies:
#   - GNOME Desktop Environment
#   - Python 3
#   - notify-send (for desktop notifications, optional)
#   - gsettings (part of dconf-gsettings-backend)
#
# Usage:
#   1. Make the script executable: chmod +x install.sh
#   2. Run the script: ./install.sh
#
# Important:
#   After successful installation, you might need to log out and log back in,
#   or restart GNOME Shell (Alt+F2 -> r -> Enter on Xorg) for the shortcut
#   to become active.
# ==============================================================================

# --- Project & Installation Configuration ---
# The expected root directory name of your project (case-sensitive)
PROJECT_ROOT_DIR="GnomeChangeWallpaper"
# Destination directory for scripts and wallpapers (user's home directory)
INSTALL_BASE_DIR="$HOME"
# Subdirectory within the project containing the wallpaper changing script
SCRIPTS_SUBDIR="Scripts"
# Subdirectory within the project containing wallpapers
WALLPAPERS_SUBDIR="Wallpapers"

# --- GNOME Shortcut Configuration ---
SHORTCUT_NAME="Change Wallpaper"
SHORTCUT_BINDING="<Control><Alt>w" # Default binding: Ctrl+Alt+W

# --- Desktop Notification Configuration ---
ENABLE_NOTIFICATIONS="true" # Set to "true" to enable, "false" to disable

# --- Helper Functions ---

# Function to send a desktop notification (if enabled and notify-send is available)
send_notification() {
    if [ "$ENABLE_NOTIFICATIONS" = "true" ] && command -v notify-send &> /dev/null; then
        notify-send "$1" "$2"
    fi
}

# Function to display an error message and exit the script
show_error_and_exit() {
    echo "Error: $1" >&2
    send_notification "Installation Failed" "$1"
    exit 1
}

# ==============================================================================
# --- Main Installation Process ---
# ==============================================================================

echo "Starting installation process for Gnome Change Wallpaper..."
send_notification "Gnome Change Wallpaper Installation" "Starting installation..."

# 1. Determine the absolute path to the project root directory.
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
PROJECT_BASE_PATH="$SCRIPT_DIR"

# Validate that the detected path matches the expected project root directory name.
if [[ "$(basename "$PROJECT_BASE_PATH")" != "$PROJECT_ROOT_DIR" ]]; then
    show_error_and_exit "Failed to determine project root correctly. Expected '$PROJECT_ROOT_DIR', but found '$(basename "$PROJECT_BASE_PATH")'. Ensure this script is run from within the '$PROJECT_ROOT_DIR' directory."
fi
echo "Project base path detected: $PROJECT_BASE_PATH"

# 2. Check if the source 'Scripts' folder exists within the project.
SOURCE_SCRIPTS_PATH="$PROJECT_BASE_PATH/$SCRIPTS_SUBDIR"
if [ ! -d "$SOURCE_SCRIPTS_PATH" ]; then
    show_error_and_exit "Source directory '$SOURCE_SCRIPTS_PATH' not found. Ensure the 'Scripts' folder exists in your project."
fi

# 3. Check if the source 'Wallpapers' folder exists within the project.
SOURCE_WALLPAPERS_PATH="$PROJECT_BASE_PATH/$WALLPAPERS_SUBDIR"
if [ ! -d "$SOURCE_WALLPAPERS_PATH" ]; then
    show_error_and_exit "Source directory '$SOURCE_WALLPAPERS_PATH' not found. Ensure the 'Wallpapers' folder exists in your project."
fi

# --- Copy project directories to the user's home if they don't exist ---

# 4. Copy the 'Scripts' folder to the user's home directory if it doesn't already exist.
DEST_SCRIPTS_PATH="$INSTALL_BASE_DIR/$SCRIPTS_SUBDIR"
if [ ! -d "$DEST_SCRIPTS_PATH" ]; then
    echo "Copying '$SCRIPTS_SUBDIR' to '$INSTALL_BASE_DIR/'..."
    cp -R "$SOURCE_SCRIPTS_PATH" "$INSTALL_BASE_DIR/" \
        || show_error_and_exit "Failed to copy '$SCRIPTS_SUBDIR' to '$INSTALL_BASE_DIR/'. Check file permissions."
else
    echo "Directory '$DEST_SCRIPTS_PATH' already exists. Skipping copy process."
fi

# 5. Copy the 'Wallpapers' folder to the user's home directory if it doesn't already exist.
DEST_WALLPAPERS_PATH="$INSTALL_BASE_DIR/$WALLPAPERS_SUBDIR"
if [ ! -d "$DEST_WALLPAPERS_PATH" ]; then
    echo "Copying '$WALLPAPERS_SUBDIR' to '$INSTALL_BASE_DIR/'..."
    cp -R "$SOURCE_WALLPAPERS_PATH" "$INSTALL_BASE_DIR/" \
        || show_error_and_exit "Failed to copy '$WALLPAPERS_SUBDIR' to '$INSTALL_BASE_DIR/'. Check file permissions."
else
    echo "Directory '$DEST_WALLPAPERS_PATH' already exists. Skipping copy process."
fi

# 6. Make the 'change_wallpaper.sh' script executable.
DEST_CHANGE_WALLPAPER_SCRIPT="$INSTALL_BASE_DIR/$SCRIPTS_SUBDIR/change_wallpaper.sh"
if [ -f "$DEST_CHANGE_WALLPAPER_SCRIPT" ]; then
    echo "Making '$DEST_CHANGE_WALLPAPER_SCRIPT' executable..."
    chmod +x "$DEST_CHANGE_WALLPAPER_SCRIPT" \
        || show_error_and_exit "Failed to make '$DEST_CHANGE_WALLPAPER_SCRIPT' executable. Check file permissions."
else
    show_error_and_exit "Could not find 'change_wallpaper.sh' at '$DEST_CHANGE_WALLPAPER_SCRIPT' after copying. Copy operation might have failed."
fi

# --- Create or Update Custom GNOME Keyboard Shortcut ---
echo "Creating/updating custom GNOME keyboard shortcut: '$SHORTCUT_NAME' with binding '$SHORTCUT_BINDING'..."

# The command executed by the shortcut will be the script we just copied and made executable.
SHORTCUT_COMMAND_FULL_PATH="$DEST_CHANGE_WALLPAPER_SCRIPT"

# GSettings variables related to the shortcut
GSETTINGS_SCHEMA_MEDIA_KEYS="org.gnome.settings-daemon.plugins.media-keys"
GSETTINGS_KEY_CUSTOM_BINDINGS="custom-keybindings"
NEW_SHORTCUT_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom-change-wallpaper/"
GSETTINGS_SCHEMA_CUSTOM_BINDING="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding"

# --- All GSettings operations related to custom-keybindings are handled by Python ---
# Using a "here document" (<< EOF) to pass a multi-line block of Python code to python3.
# No quotes on EOF ensure that Bash variables are expanded within the Python block.
python3 << EOF
import sys
import subprocess
import ast # For safer evaluation of gsettings output

# Pass Bash variables as Python variables
GSETTINGS_SCHEMA_MEDIA_KEYS = "$GSETTINGS_SCHEMA_MEDIA_KEYS"
GSETTINGS_KEY_CUSTOM_BINDINGS = "$GSETTINGS_KEY_CUSTOM_BINDINGS"
NEW_SHORTCUT_PATH = "$NEW_SHORTCUT_PATH"
SHORTCUT_NAME = "$SHORTCUT_NAME"
SHORTCUT_COMMAND_FULL_PATH = "$SHORTCUT_COMMAND_FULL_PATH"
SHORTCUT_BINDING = "$SHORTCUT_BINDING"
GSETTINGS_SCHEMA_CUSTOM_BINDING = "$GSETTINGS_SCHEMA_CUSTOM_BINDING"

# Function to safely get a gsettings value
def get_gsetting(schema, key):
    try:
        # Execute gsettings get command
        output = subprocess.check_output(['gsettings', 'get', schema, key], text=True, stderr=subprocess.DEVNULL).strip()
        # Remove '@as ' prefix if present (for array/list types)
        if output.startswith('@as '):
            output = output[4:]
        # Remove surrounding quotes if present for string types (handle both single and double quotes)
        if output.startswith("'") and output.endswith("'"):
            return output[1:-1]
        elif output.startswith('"') and output.endswith('"'):
            return output[1:-1]
        return output
    except subprocess.CalledProcessError:
        return "" # Return empty string on error or if key doesn't exist

# --- 1. Get the current list of custom keybindings ---
current_list_raw = get_gsetting(GSETTINGS_SCHEMA_MEDIA_KEYS, GSETTINGS_KEY_CUSTOM_BINDINGS)

current_paths = []
try:
    # Safely parse the Python list string (e.g., "['/path1/', '/path2/']")
    current_paths = ast.literal_eval(current_list_raw)
    if not isinstance(current_paths, list): # Ensure it's actually a list
        current_paths = []
except (SyntaxError, ValueError):
    current_paths = [] # Empty list if parsing fails

# --- 2. Check for an existing identical shortcut to avoid duplicates ---
skip_shortcut_creation = False
for path in current_paths:
    # Skip any empty paths that might exist due to malformed list (unlikely with literal_eval)
    if not path: continue

    # Construct the full schema path for individual custom keybindings
    full_path_schema = f'{GSETTINGS_SCHEMA_CUSTOM_BINDING}:{path}'
    existing_name = get_gsetting(full_path_schema, 'name')
    existing_command = get_gsetting(full_path_schema, 'command')
    existing_binding = get_gsetting(full_path_schema, 'binding')

    if (existing_name == SHORTCUT_NAME and
        existing_command == SHORTCUT_COMMAND_FULL_PATH and
        existing_binding == SHORTCUT_BINDING):
        sys.stderr.write(f'Warning: Similar shortcut already found at: {path}\n')
        sys.stderr.write(f'Name: "{existing_name}"\n')
        sys.stderr.write(f'Command: "{existing_command}"\n')
        sys.stderr.write(f'Binding: "{existing_binding}"\n')
        sys.stderr.write('Skipping shortcut creation as an exact match already exists.\n')
        skip_shortcut_creation = True
        break

if skip_shortcut_creation:
    sys.exit(0) # Exit successfully if shortcut is skipped

# --- 3. Add/Update the shortcut path in the list ---
shortcut_exists_in_list = False
if NEW_SHORTCUT_PATH in current_paths:
    shortcut_exists_in_list = True

if not shortcut_exists_in_list:
    sys.stdout.write('Adding new shortcut path to custom-keybindings list using Python.\n')
    current_paths.append(NEW_SHORTCUT_PATH)
    
    # Use repr() to get a Python-literal string representation of the list.
    # This format has been verified to work with gsettings 'set' command.
    gsettings_value_to_set = repr(current_paths)
    
    try:
        # Execute gsettings set command to update the list of custom keybindings
        # Schema and key are passed as separate arguments for robustness.
        subprocess.run(['gsettings', 'set', GSETTINGS_SCHEMA_MEDIA_KEYS, GSETTINGS_KEY_CUSTOM_BINDINGS, gsettings_value_to_set], 
                       check=True, text=True, stderr=subprocess.PIPE)
    except subprocess.CalledProcessError as e:
        sys.stderr.write(f'Error setting custom-keybindings list: {e.stderr}\n')
        sys.exit(1)
else:
    sys.stdout.write(f'Shortcut path "{NEW_SHORTCUT_PATH}" already exists in the custom-keybindings list. Updating existing entry.\n')

# --- 4. Set individual shortcut properties (name, command, binding) ---
try:
    subprocess.run(['gsettings', 'set', f'{GSETTINGS_SCHEMA_CUSTOM_BINDING}:{NEW_SHORTCUT_PATH}', 'name', SHORTCUT_NAME], 
                   check=True, text=True, stderr=subprocess.PIPE)
    subprocess.run(['gsettings', 'set', f'{GSETTINGS_SCHEMA_CUSTOM_BINDING}:{NEW_SHORTCUT_PATH}', 'command', SHORTCUT_COMMAND_FULL_PATH], 
                   check=True, text=True, stderr=subprocess.PIPE)
    subprocess.run(['gsettings', 'set', f'{GSETTINGS_SCHEMA_CUSTOM_BINDING}:{NEW_SHORTCUT_PATH}', 'binding', SHORTCUT_BINDING], 
                   check=True, text=True, stderr=subprocess.PIPE)
except subprocess.CalledProcessError as e:
    sys.stderr.write(f'Error setting shortcut properties: {e.stderr}\n')
    sys.exit(1)

sys.stdout.write('GNOME shortcut successfully created/updated!\n')
EOF

# Check the exit status of the Python script and handle errors if any.
if [ $? -ne 0 ]; then
    show_error_and_exit "GSettings operation failed."
fi

echo "----------------------------------------------------------------------"
echo "Important: To activate the shortcut, you may need to:"
echo "1. Reboot your computer."
echo "2. Or try to Press Ctrl+alt+W to change the wallpaper."
echo "----------------------------------------------------------------------"

# --- Final Installation Success Message ---
echo "Installation of Gnome Change Wallpaper finished successfully!"
send_notification "Gnome Change Wallpaper Installation" "Installation finished successfully!"