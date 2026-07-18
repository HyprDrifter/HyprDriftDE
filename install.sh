#!/usr/bin/env bash
clear
echo " "
echo " _   _                    ____       _  __ _     ____  _____ "
echo "| | | |_   _ _ __  _ __  |  _ \ _ __(_)/ _| |_  |  _ \| ____|"
echo "| |_| | | | | '_ \| '__| | | | | '__| | |_| __| | | | |  _|  "
echo "|  _  | |_| | |_) | |    | |_| | |  | |  _| |_  | |_| | |___ "
echo "|_| |_|\__, | .__/|_|    |____/|_|  |_|_|  \__| |____/|_____|"
echo "       |___/|_|                                              "
echo
echo
echo "[+] HyprDrift Installer"
echo "-------------------------------"

if [ -z "$SUDO_USER" ]; then
    echo "[-] Please run this script with sudo."
    exit 1
fi

user_systemctl() {
    local user_id
    local user_home
    user_id=$(id -u "$SUDO_USER")
    user_home=$(getent passwd "$SUDO_USER" | awk -F: '{ print $6 }')

    sudo -u "$SUDO_USER" \
        HOME="$user_home" \
        XDG_RUNTIME_DIR="/run/user/$user_id" \
        DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$user_id/bus" \
        systemctl --user "$@"
}

echo "[+] Creating required directories"
install -d /usr/bin
install -d /usr/share/wayland-sessions
install -d /etc/hyprdrift/quickdrift/
install -d /etc/hyprdrift/driftdaemon/
install -d /etc/hyprdrift/hypr/
install -d /etc/hyprdrift/config/
install -d /etc/hyprdrift/config/quickdrift/
install -d /etc/hyprdrift/config/driftdaemon/

echo "-------------------------------"
echo "[+] Installing dependencies"

# Install every dependency available from the official Arch repositories first.
# base-devel and git are also required to build yay when it is not installed.
repo_packages=(
    base-devel
    git
    cmake
    gcc
    qt6-base
    qt6-declarative
    qt6-tools
    qt6-5compat
    qt5-base
    qt5-declarative
    qt5-tools
    qt5-graphicaleffects
    quickshell
    hyprland
    hyprpaper
    hyprlock
    cliphist
    wl-clipboard
    snixembed
    hyprpolkitagent
    pavucontrol
    sddm
    go-yq
    ttf-jetbrains-mono-nerd
    kitty
    htop
    pipewire
    pipewire-pulse
    wireplumber
    sound-theme-freedesktop
)

if ! pacman -S --needed --noconfirm "${repo_packages[@]}"; then
    echo "[-] Failed to install dependencies from the official Arch repositories."
    exit 1
fi

if ! command -v yay >/dev/null 2>&1; then
    echo "[-] yay is not installed for user '$SUDO_USER'."
    read -rp "[?] Do you want to install yay now? [Y/n]: " confirm
    confirm=${confirm,,} # to lowercase
    if [[ "$confirm" =~ ^(yes|y|)$ ]]; then
        echo "[+] Installing yay..."
        sudo -u "$SUDO_USER" bash -c '
            cd /tmp || exit 1
            git clone https://aur.archlinux.org/yay.git
            cd yay || exit 1
            makepkg -si --noconfirm
        '
    else
        echo "[-] Aborting. Please install yay and re-run the script."
        exit 1
    fi
fi

# Install only packages that are not provided by the official repositories.
aur_packages=(
    wlogout
)

if ! sudo -u "$SUDO_USER" yay -S --needed --noconfirm "${aur_packages[@]}"; then
    echo "[-] Failed to install AUR dependencies."
    exit 1
fi

# Optional: Warn if no Nerd Font found
if ! fc-list | grep -qi "nerd"; then
    echo "[!] Warning: No Nerd Font found. Please install one (e.g., 'ttf-jetbrains-mono-nerd')"
fi

echo "-------------------------------"
echo "[+] Installing session files and scripts"
install -Dm755 system/scripts/hyprdrift-session /usr/bin/hyprdrift-session
install -Dm644 system/session/hyprdrift.desktop /usr/share/wayland-sessions/hyprdrift.desktop

echo "-------------------------------"
echo "[+] Building drift-daemon"
cmake -B drift-daemon/build -S drift-daemon 
make -C drift-daemon/build

echo "-------------------------------"
echo "[+] Installing backend daemon"
install -Dm755 drift-daemon/build/drift-daemon /usr/bin/drift-daemon

echo "-------------------------------"
echo "[+] Installing configs"
cp -rf config/drift-config.yaml /etc/hyprdrift/config/quickdrift/drift-config.yaml
cp -rf .config /etc/hyprdrift/hypr/

echo "-------------------------------"
echo "[+] Installing quickdrift.service"
# /etc/systemd/user has higher lookup priority than /etc/xdg/systemd/user.
# Keep both copies synchronized so an older shadow unit cannot survive an update.
install -Dm644 system/services/quickdrift.service /etc/xdg/systemd/user/quickdrift.service
install -Dm644 system/services/quickdrift.service /etc/systemd/user/quickdrift.service

echo "-------------------------------"
echo "[+] Installing quickdrift-shell QML config"
cp -rf quickdrift-shell/* /etc/hyprdrift/quickdrift/

echo "-------------------------------"
echo "[+] Installing Quickshell dev loop"
install -Dm755 system/scripts/quickshell-loop.sh /usr/bin/quickshell-loop

echo "-------------------------------"
echo "[+] Enabling services"
user_systemctl daemon-reload
user_systemctl enable quickdrift.service
user_systemctl enable --now pipewire.service
user_systemctl enable --now pipewire-pulse.service
user_systemctl enable --now wireplumber.service

echo "-------------------------------"
echo "[+] Enabling and starting SDDM"
systemctl enable --now sddm.service

echo "-------------------------------"
echo "[+] Installation complete!"
exit 0
