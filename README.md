# Gnome Change Wallpaper

## 📖 Description

**Gnome Change Wallpaper** is a simple project that allows you to **randomly change your GNOME desktop wallpaper** quickly and easily. This project provides an automatic installation script to set up everything you need, including a **global keyboard shortcut (`Ctrl+Alt+W`)** for maximum convenience.

## ✨ Key Features

- **🎲 Random Wallpaper Change**: Automatically selects a random image from your wallpaper folder.
- **⚙️ Easy Installation**: Just run one script to copy the necessary files and set up the shortcut.
- **⌨️ Keyboard Shortcut**: Change your wallpaper anytime by pressing `Ctrl+Alt+W`.
- **🖼️ Multi-Format Support**: Supports `.jpg`, `.png`, and `.jpeg` files.
- **🔔 Desktop Notifications**: Get a desktop notification after the wallpaper is successfully changed (optional).
- **🔧 Flexible Configuration**: Various configuration options via the installation script.

## 🚀 How It Works

Once installed, the main script (`change_wallpaper.sh`) will:

1. Search for all images in the `~/Wallpapers` folder.
2. Randomly select one image.
3. Set the selected image as your GNOME desktop wallpaper.
4. Display a notification (if enabled).

The `install.sh` script will handle all the initial setup for you automatically.

## 📋 System Requirements

- **OS**: Linux with GNOME Desktop Environment
- **Shell**: Bash
- **Dependencies**:
  - `gsettings` (usually pre-installed on GNOME)
  - `notify-send` (for desktop notifications)
  - `readlink`, `dirname`, `cp`, `chmod` (standard Linux utilities)

## 🛠️ Installation

### 1. Clone the Repository

```bash
git clone https://github.com/tudeorangbiasa/GnomeChangeWallpaper.git
cd GnomeChangeWallpaper/
```

### 2. Run the Installation Script

```bash
chmod +x install.sh
./install.sh
```

### 3. Add Your Wallpapers

Place your favorite `.jpg`, `.png`, or `.jpeg` images into the `~/Wallpapers/` folder.

### 4. Done!

Press `Ctrl+Alt+W` anytime to get a new wallpaper!

## ⚙️ Configuration

You can customize several settings by editing the `install.sh` file before running it:

| Variable              | Default           | Description                              |
|-----------------------|-------------------|------------------------------------------|
| `SHORTCUT_BINDING`    | `<Control><Alt>w` | Keyboard shortcut combination            |
| `ENABLE_NOTIFICATIONS`| `true`            | Enable/disable desktop notifications     |
| `INSTALL_DIR`         | `$HOME`           | Installation target directory            |

## 📁 Project Structure

```
GnomeChangeWallpaper/
├── install.sh              # Main installation script
├── README.md               # Project documentation
├── Scripts/
│   └── change_wallpaper.sh # Wallpaper changer script
└── Wallpapers/             # Folder to store wallpapers
```

After installation, the structure in your home directory will look like this:
```
~/
├── Scripts/
│   └── change_wallpaper.sh
└── Wallpapers/
    └── (your wallpapers here)
```

## 🎯 Usage

### Via Keyboard Shortcut
- Press `Ctrl+Alt+W` to randomly change your wallpaper.

### Via Terminal
```bash
~/Scripts/change_wallpaper.sh
```

## 🔧 Troubleshooting

### Error: "Please run this script from inside the 'gnomeChangeWallpaper' directory"
**Solution**: Ensure you are running `install.sh` from within the cloned project directory.

### Shortcut not working
**Solution**: 
1. Check if the shortcut is registered: `gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings`
2. Restart GNOME Shell by pressing `Alt+F2`, typing `r`, and pressing Enter.

### No notifications appear
**Solution**: Ensure `notify-send` is installed:
```bash
sudo apt install libnotify-bin  # Ubuntu/Debian
sudo dnf install libnotify      # Fedora
```

## 🤝 Contributions

Contributions are always welcome! Please:

1. Fork this repository.
2. Create a new feature branch (`git checkout -b feature/AmazingFeature`).
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`).
4. Push to the branch (`git push origin feature/AmazingFeature`).
5. Open a Pull Request.

## 📝 License

This project is open source. Feel free to use and modify it as needed.

## 👨‍💻 Author

- **tudeorangbiasa** - *Initial work* - [GitHub](https://github.com/tudeorangbiasa)

## 🙏 Acknowledgments

- Thanks to the GNOME community for their comprehensive `gsettings` documentation.
- Inspired by various wallpaper changer scripts in the Linux community.

---

**Enjoy fresh wallpapers every time HEHEHA! 🎨**
