# Aether Astrum

Modern file manager for AetherDE, built with Vala, GTK4, and LibAdwaita.

[![Translation status](https://hosted.weblate.org/widget/nuros/astrum/svg-badge.svg?native=1)](https://hosted.weblate.org/projects/nuros/astrum/)

## Features

- Clean, modern GNOME HIG-compliant interface
- List and grid view modes
- Search files in current folder
- Bookmarks support
- Copy, cut, paste operations
- Show/hide hidden files
- Move to trash
- Rename files and folders
- File properties dialog
- Keyboard shortcuts

## Building

### Dependencies

- Vala (>= 0.56)
- Meson (>= 0.62)
- GLib (>= 2.76)
- GTK4 (>= 4.12)
- LibAdwaita (>= 1.4)

### Arch Linux

```bash
sudo pacman -S vala meson libadwaita
```

### Build

```bash
meson setup build
meson compile -C build
```

### Run (development)

```bash
GSETTINGS_SCHEMA_DIR=./data ./build/src/astrum 
```

### Install

```bash
meson install -C build
```

## Keyboard Shortcuts

- `Alt+Left` — Go back
- `Alt+Right` — Go forward
- `Alt+Up` — Go to parent folder
- `F5` / `Ctrl+R` — Refresh
- `Ctrl+Shift+N` — New folder
- `Ctrl+C` — Copy
- `Ctrl+X` — Cut
- `Ctrl+V` — Paste
- `Ctrl+A` — Select all
- `F2` — Rename
- `Delete` — Move to trash
- `Alt+Return` — Properties
- `Ctrl+L` — Focus location bar
- `Ctrl+F` — Search
- `Ctrl+H` — Toggle hidden files
- `Ctrl+Alt+T` — Open terminal
- `Ctrl+Q` — Quit

## License

GPL-3.0-or-later

## Author

AnmiTaliDev <anmitalidev@nuros.org>
