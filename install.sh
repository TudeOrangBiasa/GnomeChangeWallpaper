
#!/bin/bash

# ==============================================================================
# GNOME Change Wallpaper Installer
# ------------------------------------------------------------------------------
# This script sets up a custom GNOME keyboard shortcut to change your desktop
# wallpaper. It copies required scripts and wallpapers to your home directory
# and configures GNOME settings for the shortcut.
# ------------------------------------------------------------------------------
# Author: Your Name
# Version: 1.0.0
# Date: July 28, 2025
# ------------------------------------------------------------------------------
# Requirements:
#   - GNOME Desktop Environment
#   - Python 3
#   - notify-send (optional, for notifications)
#   - gsettings (usually installed with GNOME)
# ------------------------------------------------------------------------------
# Usage:
#   chmod +x install.sh
#   ./install.sh
# ------------------------------------------------------------------------------
# After installation, you may need to log out/in or restart GNOME Shell for the
# shortcut to become active.
# ==============================================================================


# --- Project & Installation Configuration ---
PROJECT_ROOT_DIR="GnomeChangeWallpaper"      # Expected project root directory name
INSTALL_BASE_DIR="$HOME"                     # Destination: user's home directory
SCRIPTS_SUBDIR="Scripts"                     # Script folder name
WALLPAPERS_SUBDIR="Wallpapers"               # Wallpapers folder name


# --- GNOME Shortcut Configuration ---
SHORTCUT_NAME="Change Wallpaper"              # Shortcut name in GNOME
SHORTCUT_BINDING="<Control><Alt>w"            # Default binding: Ctrl+Alt+W


# --- Desktop Notification Configuration ---
ENABLE_NOTIFICATIONS="true"                   # "true" to enable notifications


# --- Helper Functions ---

# Send a desktop notification (if enabled and notify-send is available)
send_notification() {
    if [ "$ENABLE_NOTIFICATIONS" = "true" ] && command -v notify-send &> /dev/null; then
        notify-send "$1" "$2"
    fi
}

# Display an error message and exit
show_error_and_exit() {
    echo "Error: $1" >&2
    send_notification "Installation Failed" "$1"
    exit 1
}


# ==============================================================================
# Main Installation Process
# ==============================================================================

echo "Starting installation for Gnome Change Wallpaper..."
send_notification "Gnome Change Wallpaper Installation" "Starting installation..."

# 1. Get absolute path to project root
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
PROJECT_BASE_PATH="$SCRIPT_DIR"

# 2. Validate project root directory
if [[ "$(basename "$PROJECT_BASE_PATH")" != "$PROJECT_ROOT_DIR" ]]; then
    show_error_and_exit "Expected project root '$PROJECT_ROOT_DIR', but found '$(basename "$PROJECT_BASE_PATH")'. Run this script from inside '$PROJECT_ROOT_DIR'."
fi
echo "Project base path: $PROJECT_BASE_PATH"

# 3. Check source folders
SOURCE_SCRIPTS_PATH="$PROJECT_BASE_PATH/$SCRIPTS_SUBDIR"
SOURCE_WALLPAPERS_PATH="$PROJECT_BASE_PATH/$WALLPAPERS_SUBDIR"
if [ ! -d "$SOURCE_SCRIPTS_PATH" ]; then
    show_error_and_exit "Missing '$SOURCE_SCRIPTS_PATH'. Ensure 'Scripts' exists."
fi
if [ ! -d "$SOURCE_WALLPAPERS_PATH" ]; then
    show_error_and_exit "Missing '$SOURCE_WALLPAPERS_PATH'. Ensure 'Wallpapers' exists."
fi

# 4. Copy folders to home if needed
DEST_SCRIPTS_PATH="$INSTALL_BASE_DIR/$SCRIPTS_SUBDIR"
DEST_WALLPAPERS_PATH="$INSTALL_BASE_DIR/$WALLPAPERS_SUBDIR"
if [ ! -d "$DEST_SCRIPTS_PATH" ]; then
    echo "Copying '$SCRIPTS_SUBDIR' to home..."
    cp -R "$SOURCE_SCRIPTS_PATH" "$INSTALL_BASE_DIR/" || show_error_and_exit "Failed to copy '$SCRIPTS_SUBDIR'."
else
    echo "'$DEST_SCRIPTS_PATH' already exists. Skipping."
fi
if [ ! -d "$DEST_WALLPAPERS_PATH" ]; then
    echo "Copying '$WALLPAPERS_SUBDIR' to home..."
    cp -R "$SOURCE_WALLPAPERS_PATH" "$INSTALL_BASE_DIR/" || show_error_and_exit "Failed to copy '$WALLPAPERS_SUBDIR'."
else
    echo "'$DEST_WALLPAPERS_PATH' already exists. Skipping."
fi

# 5. Make change_wallpaper.sh executable
DEST_CHANGE_WALLPAPER_SCRIPT="$DEST_SCRIPTS_PATH/change_wallpaper.sh"
if [ -f "$DEST_CHANGE_WALLPAPER_SCRIPT" ]; then
    echo "Making '$DEST_CHANGE_WALLPAPER_SCRIPT' executable..."
    chmod +x "$DEST_CHANGE_WALLPAPER_SCRIPT" || show_error_and_exit "Failed to make script executable."
else
    show_error_and_exit "Missing 'change_wallpaper.sh' after copy."
fi

# 6. Create or update GNOME keyboard shortcut
echo "Configuring GNOME shortcut: '$SHORTCUT_NAME' ($SHORTCUT_BINDING)"
SHORTCUT_COMMAND_FULL_PATH="$DEST_CHANGE_WALLPAPER_SCRIPT"
GSETTINGS_SCHEMA_MEDIA_KEYS="org.gnome.settings-daemon.plugins.media-keys"
GSETTINGS_KEY_CUSTOM_BINDINGS="custom-keybindings"
NEW_SHORTCUT_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom-change-wallpaper/"
GSETTINGS_SCHEMA_CUSTOM_BINDING="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding"

python3 << EOF
import sys, subprocess, ast
GSETTINGS_SCHEMA_MEDIA_KEYS = "$GSETTINGS_SCHEMA_MEDIA_KEYS"
GSETTINGS_KEY_CUSTOM_BINDINGS = "$GSETTINGS_KEY_CUSTOM_BINDINGS"
NEW_SHORTCUT_PATH = "$NEW_SHORTCUT_PATH"
SHORTCUT_NAME = "$SHORTCUT_NAME"
SHORTCUT_COMMAND_FULL_PATH = "$SHORTCUT_COMMAND_FULL_PATH"
SHORTCUT_BINDING = "$SHORTCUT_BINDING"
GSETTINGS_SCHEMA_CUSTOM_BINDING = "$GSETTINGS_SCHEMA_CUSTOM_BINDING"

def get_gsetting(schema, key):
    try:
        output = subprocess.check_output(['gsettings', 'get', schema, key], text=True, stderr=subprocess.DEVNULL).strip()
        if output.startswith('@as '): output = output[4:]
        if output.startswith("'") and output.endswith("'"): return output[1:-1]
        if output.startswith('"') and output.endswith('"'): return output[1:-1]
        return output
    except subprocess.CalledProcessError:
        return ""

# 1. Get current custom keybindings
current_list_raw = get_gsetting(GSETTINGS_SCHEMA_MEDIA_KEYS, GSETTINGS_KEY_CUSTOM_BINDINGS)
try:
    current_paths = ast.literal_eval(current_list_raw)
    if not isinstance(current_paths, list): current_paths = []
except Exception:
    current_paths = []

# 2. Avoid duplicate shortcut
for path in current_paths:
    if not path: continue
    full_path_schema = f'{GSETTINGS_SCHEMA_CUSTOM_BINDING}:{path}'
    if (get_gsetting(full_path_schema, 'name') == SHORTCUT_NAME and
        get_gsetting(full_path_schema, 'command') == SHORTCUT_COMMAND_FULL_PATH and
        get_gsetting(full_path_schema, 'binding') == SHORTCUT_BINDING):
        sys.stderr.write(f'Warning: Shortcut already exists at: {path}\n')
        sys.exit(0)

# 3. Add shortcut path if missing
if NEW_SHORTCUT_PATH not in current_paths:
    current_paths.append(NEW_SHORTCUT_PATH)
    gsettings_value_to_set = repr(current_paths)
    try:
        subprocess.run(['gsettings', 'set', GSETTINGS_SCHEMA_MEDIA_KEYS, GSETTINGS_KEY_CUSTOM_BINDINGS, gsettings_value_to_set], check=True, text=True, stderr=subprocess.PIPE)
    except subprocess.CalledProcessError as e:
        sys.stderr.write(f'Error setting custom-keybindings list: {e.stderr}\n')
        sys.exit(1)

# 4. Set shortcut properties
try:
    subprocess.run(['gsettings', 'set', f'{GSETTINGS_SCHEMA_CUSTOM_BINDING}:{NEW_SHORTCUT_PATH}', 'name', SHORTCUT_NAME], check=True, text=True, stderr=subprocess.PIPE)
    subprocess.run(['gsettings', 'set', f'{GSETTINGS_SCHEMA_CUSTOM_BINDING}:{NEW_SHORTCUT_PATH}', 'command', SHORTCUT_COMMAND_FULL_PATH], check=True, text=True, stderr=subprocess.PIPE)
    subprocess.run(['gsettings', 'set', f'{GSETTINGS_SCHEMA_CUSTOM_BINDING}:{NEW_SHORTCUT_PATH}', 'binding', SHORTCUT_BINDING], check=True, text=True, stderr=subprocess.PIPE)
except subprocess.CalledProcessError as e:
    sys.stderr.write(f'Error setting shortcut properties: {e.stderr}\n')
    sys.exit(1)
sys.stdout.write('GNOME shortcut created/updated!\n')
EOF

if [ $? -ne 0 ]; then
    show_error_and_exit "GSettings operation failed."
fi

echo "----------------------------------------------------------------------"
echo "To activate the shortcut, you may need to:"
echo "1. Reboot your computer."
echo "2. Or press Ctrl+Alt+W to change the wallpaper."
echo "----------------------------------------------------------------------"

echo "Installation finished successfully!"
send_notification "Gnome Change Wallpaper Installation" "Installation finished successfully!"