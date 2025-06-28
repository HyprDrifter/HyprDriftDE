# HyprDrift Desktop Environment

**HyprDrift** is a modular desktop environment built on top of [Hyprland](https://github.com/hyprwm/Hyprland), combining a powerful C++ backend with a modern QML-based shell.

### ✨ Key Features

- **Wayland-native** via Hyprland
- **Modular architecture** with a daemon (`drift`) and shell (`quickdrift-shell`)
- **Clean YAML-based theming** (tinted-theming spec)
- **Drag-and-drop tiling** support
- **Lightweight, flexible, and customizable**

### 🧱 Project Components

- `drift/` — system daemon managing sessions, settings, themes, apps
- `quickdrift-shell/` — QML frontend built on Quickshell
- `themes/` — unified theme definitions in YAML
- `install.sh` — portable POSIX-compliant installer

### 📦 Requirements

- Hyprland
- Qt6 (base + QML modules)
- Bash, `cliphist`, `pavucontrol`, `go-yq`, Nerd Font
- Optional: dropdown terminal support for all terminals


**HyprDrift** is built for simplicity, style, and speed — a modern Linux DE without the bloat.
