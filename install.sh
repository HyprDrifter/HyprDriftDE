#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

INSTALL_AUR=true
INSTALL_SDDM=true
START_SERVICES=true
YAY_BUILD_DIR=""
TEMP_PATHS=()

usage() {
    cat <<'EOF'
Usage: sudo ./install.sh [options]

Options:
  --no-aur      Skip yay bootstrapping and AUR packages.
  --no-sddm     Do not install, enable, or start SDDM.
  --no-start    Enable services without starting them during installation.
  -h, --help    Show this help text.
EOF
}

cleanup() {
    local path

    if [[ -n "${YAY_BUILD_DIR:-}" && "$YAY_BUILD_DIR" == /tmp/hyprdrift-yay.* ]]; then
        rm -rf -- "$YAY_BUILD_DIR"
    fi

    for path in "${TEMP_PATHS[@]:-}"; do
        case "$path" in
            /etc/hyprdrift/.*.new.*)
                rm -rf -- "$path"
                ;;
        esac
    done
}

on_error() {
    local status=$?
    local line=$1
    local command=$2

    echo "[-] Installation failed at line $line while running: $command" >&2
    exit "$status"
}

trap cleanup EXIT
trap 'on_error "$LINENO" "$BASH_COMMAND"' ERR

while (($# > 0)); do
    case "$1" in
        --no-aur)
            INSTALL_AUR=false
            ;;
        --no-sddm)
            INSTALL_SDDM=false
            ;;
        --no-start)
            START_SERVICES=false
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "[-] Unknown option: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
    shift
done

if ((EUID != 0)); then
    echo "[-] Please run this script with sudo." >&2
    exit 1
fi

if [[ -z "${SUDO_USER:-}" || "$SUDO_USER" == "root" ]]; then
    echo "[-] Unable to identify the non-root user who invoked sudo." >&2
    exit 1
fi

if [[ ! -f /etc/arch-release ]] || ! command -v pacman >/dev/null 2>&1; then
    echo "[-] HyprDrift currently supports Arch Linux installations using pacman." >&2
    exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
    echo "[-] sudo is required to run build and AUR steps as the invoking user." >&2
    exit 1
fi

if ! getent passwd "$SUDO_USER" >/dev/null; then
    echo "[-] The invoking user '$SUDO_USER' does not exist." >&2
    exit 1
fi

INSTALL_USER=$SUDO_USER
INSTALL_USER_ID=$(id -u "$INSTALL_USER")
INSTALL_USER_ENTRY=$(getent passwd "$INSTALL_USER")
IFS=: read -r _ _ _ _ _ INSTALL_USER_HOME _ <<< "$INSTALL_USER_ENTRY"
INSTALL_USER_RUNTIME_DIR="/run/user/$INSTALL_USER_ID"

run_as_user() {
    sudo -u "$INSTALL_USER" \
        env \
        HOME="$INSTALL_USER_HOME" \
        USER="$INSTALL_USER" \
        LOGNAME="$INSTALL_USER" \
        "$@"
}

user_systemctl() {
    run_as_user \
        env \
        XDG_RUNTIME_DIR="$INSTALL_USER_RUNTIME_DIR" \
        DBUS_SESSION_BUS_ADDRESS="unix:path=$INSTALL_USER_RUNTIME_DIR/bus" \
        systemctl --user "$@"
}

install_user_hypr_defaults() {
    local installed_defaults=/etc/hyprdrift/hypr/.config
    local user_entrypoint="$INSTALL_USER_HOME/.config/hypr/hyprland.lua"

    run_as_user mkdir -p "$INSTALL_USER_HOME/.config"
    run_as_user cp -a --no-clobber "$installed_defaults/." "$INSTALL_USER_HOME/.config/"

    if [[ ! -f "$user_entrypoint" ]]; then
        echo "[-] Failed to install the user's Hyprland Lua configuration: $user_entrypoint" >&2
        return 1
    fi
}

validate_sources() {
    local source_path
    local required_sources=(
        "config/drift-config.yaml"
        "drift-daemon/CMakeLists.txt"
        "quickdrift-shell/shell.qml"
        "system/scripts/hyprdrift-session"
        "system/scripts/quickshell-loop.sh"
        "system/services/quickdrift.service"
        "system/session/hyprdrift.desktop"
        ".config/hypr/hyprland.lua"
    )

    for source_path in "${required_sources[@]}"; do
        if [[ ! -e "$SCRIPT_DIR/$source_path" ]]; then
            echo "[-] Required source file is missing: $source_path" >&2
            exit 1
        fi
    done

    bash -n "$SCRIPT_DIR/install.sh"
    bash -n "$SCRIPT_DIR/system/scripts/hyprdrift-session"
    bash -n "$SCRIPT_DIR/system/scripts/quickshell-loop.sh"
}

copy_source_tree() {
    local source_relative=$1
    local destination=$2
    local source_path="$SCRIPT_DIR/$source_relative"
    local tracked_file
    local relative_path
    local copied_any=false

    if git -C "$SCRIPT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        while IFS= read -r -d '' tracked_file; do
            relative_path=${tracked_file#"$source_relative"/}
            install -d -- "$(dirname -- "$destination/$relative_path")"
            cp -a -- "$SCRIPT_DIR/$tracked_file" "$destination/$relative_path"
            copied_any=true
        done < <(git -C "$SCRIPT_DIR" ls-files -z -- "$source_relative")

        if [[ "$copied_any" != true ]]; then
            echo "[-] No tracked files found under $source_relative." >&2
            return 1
        fi
    else
        cp -a -- "$source_path/." "$destination/"
    fi
}

replace_managed_directory() {
    local source_relative=$1
    local destination=$2
    local destination_parent
    local destination_name
    local stage
    local previous

    destination_parent=$(dirname -- "$destination")
    destination_name=$(basename -- "$destination")
    install -d -- "$destination_parent"

    stage=$(mktemp -d "$destination_parent/.${destination_name}.new.XXXXXX")
    TEMP_PATHS+=("$stage")
    copy_source_tree "$source_relative" "$stage"

    previous="$destination_parent/.${destination_name}.previous.$$"
    if [[ -e "$destination" ]]; then
        mv -- "$destination" "$previous"
    fi

    if mv -- "$stage" "$destination"; then
        if [[ -e "$previous" ]]; then
            rm -rf -- "$previous"
        fi
    else
        if [[ -e "$previous" ]]; then
            mv -- "$previous" "$destination"
        fi
        return 1
    fi
}

verify_command() {
    local command_name=$1

    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "[-] Required command is unavailable after installation: $command_name" >&2
        return 1
    fi
}

verify_installation() {
    local command_name
    local required_commands=(
        bash
        brightnessctl
        grim
        hyprctl
        Hyprland
        jq
        NetworkManager
        paplay
        playerctl
        qs
        satty
        slurp
        start-hyprland
        wl-copy
        wl-paste
    )

    if [[ "$INSTALL_AUR" == true ]]; then
        required_commands+=(wlogout)
    fi

    if [[ "$INSTALL_SDDM" == true ]]; then
        required_commands+=(sddm)
    fi

    for command_name in "${required_commands[@]}"; do
        verify_command "$command_name"
    done

    [[ -x /usr/bin/drift-daemon ]]
    [[ -x /usr/bin/hyprdrift-session ]]
    [[ -x /usr/lib/bluetooth/bluetoothd ]]
    [[ -f /usr/share/wayland-sessions/hyprdrift.desktop ]]
    [[ -f /etc/hyprdrift/quickdrift/shell.qml ]]
    [[ -f /etc/hyprdrift/hypr/.config/hypr/hyprland.lua ]]
    [[ -f /etc/systemd/user/quickdrift.service ]]
    [[ -f "$INSTALL_USER_HOME/.config/hypr/hyprland.lua" ]]

    bash -n /usr/bin/hyprdrift-session
    run_as_user \
        Hyprland --verify-config \
        --config "$INSTALL_USER_HOME/.config/hypr/hyprland.lua"
}

if [[ -t 1 && -n "${TERM:-}" ]]; then
    clear || true
fi

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

cd -- "$SCRIPT_DIR"
validate_sources

echo "[+] Installing official Arch dependencies"

# Official runtime and build dependencies. base-devel, git, and go are also
# required before yay can be built from the AUR.
repo_packages=(
    base-devel
    git
    go
    cmake
    gcc
    qt6-base
    qt6-declarative
    qt6-tools
    qt6-5compat
    quickshell
    hyprland
    hyprpaper
    hyprlock
    cliphist
    wl-clipboard
    snixembed
    hyprpolkitagent
    pavucontrol
    go-yq
    ttf-jetbrains-mono-nerd
    kitty
    htop
    pipewire
    pipewire-pulse
    wireplumber
    libpulse
    sound-theme-freedesktop
    networkmanager
    bluez
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    grim
    brightnessctl
    playerctl
    slurp
    satty
    jq
)

if [[ "$INSTALL_SDDM" == true ]]; then
    repo_packages+=(sddm)
fi

pacman -S --needed --noconfirm "${repo_packages[@]}"

quickshell_version=$(/usr/bin/qs --version 2>&1)
if [[ ! "$quickshell_version" =~ Quickshell[[:space:]]+0\.3\.[0-9]+ ]]; then
    echo "[-] HyprDrift requires Quickshell v0.3.x; found: $quickshell_version" >&2
    exit 1
fi

hyprland_version=$(pacman -Q hyprland | awk '{ print $2 }')
if (( $(vercmp "$hyprland_version" "0.55.0") < 0 )); then
    echo "[-] HyprDrift's Lua configuration requires Hyprland 0.55 or newer; found $hyprland_version." >&2
    exit 1
fi

if [[ "$INSTALL_AUR" == true ]]; then
    if ! command -v yay >/dev/null 2>&1; then
        echo "[-] yay is not installed for user '$INSTALL_USER'."

        if [[ ! -t 0 ]]; then
            echo "[-] Install yay first or rerun with --no-aur in a non-interactive environment." >&2
            exit 1
        fi

        read -rp "[?] Do you want to install yay now? [Y/n]: " confirm
        confirm=${confirm,,}
        if [[ ! "$confirm" =~ ^(yes|y|)$ ]]; then
            echo "[-] Aborting. Install yay or rerun with --no-aur."
            exit 1
        fi

        echo "[+] Building yay as $INSTALL_USER"
        YAY_BUILD_DIR=$(run_as_user mktemp -d /tmp/hyprdrift-yay.XXXXXX)
        run_as_user git clone https://aur.archlinux.org/yay.git "$YAY_BUILD_DIR"
        run_as_user bash -c 'cd -- "$1" && makepkg --noconfirm' bash "$YAY_BUILD_DIR"

        mapfile -t yay_package_files < <(
            run_as_user bash -c 'cd -- "$1" && makepkg --packagelist' bash "$YAY_BUILD_DIR"
        )
        if ((${#yay_package_files[@]} == 0)); then
            echo "[-] yay did not produce an installable package." >&2
            exit 1
        fi

        pacman -U --needed --noconfirm "${yay_package_files[@]}"
        rm -rf -- "$YAY_BUILD_DIR"
        YAY_BUILD_DIR=""
        verify_command yay
    fi

    echo "[+] Installing AUR dependencies"
    run_as_user yay -S --needed --noconfirm wlogout
else
    echo "[!] Skipping AUR dependencies; the Power button requires wlogout."
fi

echo "-------------------------------"
echo "[+] Building drift-daemon as $INSTALL_USER"
BUILD_DIR="$SCRIPT_DIR/build/drift-daemon"
run_as_user cmake \
    -S "$SCRIPT_DIR/drift-daemon" \
    -B "$BUILD_DIR" \
    -DCMAKE_BUILD_TYPE=Release
run_as_user cmake --build "$BUILD_DIR" --parallel

if [[ ! -x "$BUILD_DIR/drift-daemon" ]]; then
    echo "[-] drift-daemon build completed without producing the expected binary." >&2
    exit 1
fi

echo "-------------------------------"
echo "[+] Installing system files"
install -d /etc/hyprdrift/config/quickdrift
install -Dm755 "$SCRIPT_DIR/system/scripts/hyprdrift-session" /usr/bin/hyprdrift-session
install -Dm755 "$SCRIPT_DIR/system/scripts/quickshell-loop.sh" /usr/bin/quickshell-loop
install -Dm755 "$BUILD_DIR/drift-daemon" /usr/bin/drift-daemon
install -Dm644 "$SCRIPT_DIR/system/session/hyprdrift.desktop" /usr/share/wayland-sessions/hyprdrift.desktop
install -Dm644 "$SCRIPT_DIR/config/drift-config.yaml" /etc/hyprdrift/config/quickdrift/drift-config.yaml

# Install both unit locations to overwrite historical installations that may
# otherwise shadow the updated service definition.
install -Dm644 "$SCRIPT_DIR/system/services/quickdrift.service" /etc/xdg/systemd/user/quickdrift.service
install -Dm644 "$SCRIPT_DIR/system/services/quickdrift.service" /etc/systemd/user/quickdrift.service

echo "-------------------------------"
echo "[+] Replacing managed configuration trees"
replace_managed_directory ".config" "/etc/hyprdrift/hypr/.config"
replace_managed_directory "quickdrift-shell" "/etc/hyprdrift/quickdrift"
install_user_hypr_defaults

echo "-------------------------------"
echo "[+] Validating installed files"
verify_installation

echo "-------------------------------"
echo "[+] Enabling services"

system_service_action=(enable)
user_service_action=(enable)
if [[ "$START_SERVICES" == true ]]; then
    system_service_action+=(--now)
    user_service_action+=(--now)
fi

systemctl "${system_service_action[@]}" NetworkManager.service
systemctl "${system_service_action[@]}" bluetooth.service

if [[ -S "$INSTALL_USER_RUNTIME_DIR/bus" ]]; then
    user_systemctl daemon-reload
    user_systemctl enable quickdrift.service
    user_systemctl "${user_service_action[@]}" pipewire.service
    user_systemctl "${user_service_action[@]}" pipewire-pulse.service
    user_systemctl "${user_service_action[@]}" wireplumber.service
else
    echo "[!] No active user systemd bus for $INSTALL_USER; user-service activation was deferred."
    echo "[!] quickdrift.service will still be started by the HyprDrift session launcher."
fi

# SDDM is deliberately activated last, after every install and validation step.
if [[ "$INSTALL_SDDM" == true ]]; then
    echo "-------------------------------"
    if [[ "$START_SERVICES" == true ]]; then
        echo "[+] Enabling and starting SDDM"
    else
        echo "[+] Enabling SDDM without starting it"
    fi
    systemctl "${system_service_action[@]}" sddm.service
fi

echo "-------------------------------"
echo "[+] Installation complete!"
