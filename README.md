# Hypr Drift DE

**Hypr Drift Desktop Environment** is a responsive, animated, and modular desktop experience built on top of [Hyprland](https://github.com/hyprwm/Hyprland). It aims to deliver smooth, fluid visuals and a traditional desktop feel while staying lightweight and extensible.

Whether you want a minimalist tiling workflow or a polished, feature-rich DE, Hypr Drift adapts to your preferences.

---

## 🌟 Why Hypr Drift DE?

Hypr Drift is designed for users who want:

- **Smooth animations and responsive input** without sacrificing performance
- **Traditional desktop features** like alt-tab, minimizing, system tray, and wallpapers
- **Highly modular components** that can be swapped, extended, or removed
- **Clean configuration and theming** using YAML files with sensible defaults
- **Wayland-native experience** with modern features, built on Hyprland

Hypr Drift DE enhances Hyprland with the creature comforts of a full desktop environment—without the overhead.

---

## ✨ Key Features

- Animated and glossy UI (fully toggleable)
- Auto-tiling window manager with minimize and alt-tab
- Drop-down terminal and clipboard history integration
- Lock screen and wallpaper support
- D-Bus integration and IPC-based orchestration
- Shared YAML-based theming
- QML-based shell interface with modular components

---

## 🧩 Architecture Overview

Hypr Drift DE is built from modular components with clear separation of concerns:

### 🧠 Drift Daemon (`drift-daemon`) – C++ Backend
Handles system logic, state awareness, and coordination of frontend features. Key modules include:

- **Apps Manager** – Launching and indexing applications
- **Drift Core** – Session initialization and orchestrator
- **D-Bus Manager** – IPC and communication bridge
- **Logging** – Runtime logs and debugging output
- **Process Manager** – Background task tracking
- **Session Manager** – Ensures valid graphical session and exports session variables
- **Settings Manager** – Parses and applies user settings from YAML
- **Theme Manager** – Loads and propagates theme data
- **Wallpaper Manager** – Controls wallpapers across outputs

All modules ship with sensible defaults and can be modified independently.

---

### 🖼️ QuickDrift Shell (`quickdrift-shell`) – QML Frontend

A modular shell built using [Quickshell](https://github.com/quickqml/quickshell), written in QML/Qt. It provides the visible user interface and receives state updates from the daemon.

---

## 🧱 Dependencies

### Runtime Dependencies:
- [`hyprland`](https://github.com/hyprwm/Hyprland)
- [`hyprpaper`](https://github.com/hyprwm/hyprpaper)
- [`hyprlock`](https://github.com/hyprwm/hyprlock)
- [`cliphist`](https://github.com/sentriz/cliphist)
- [`tinted-theming`](https://github.com/tinted-theming)
- [`pavucontrol`](https://freedesktop.org/software/pulseaudio/pavucontrol/)
- A [Nerd Font](https://www.nerdfonts.com/) installed system-wide

### Build Dependencies:
- `qt6-base`, `qt6-declarative`, `qt6-tools`
- `cmake`
- `g++` or `clang++`

---

## 🔧 Installation

Clone the repo and run the installer script from inside the root directory:

```bash
git clone https://github.com/yourname/hyprdriftde.git
cd hyprdriftde
sudo ./install.sh
