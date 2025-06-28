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

echo "[+] Creating required directories"
install -d /usr/bin
install -d /usr/share/wayland-sessions
install -d /etc/xdg/hyprdrift/quickdrift-shell/

echo "-------------------------------"
echo "[+] Installing dependencies"
if ! command -v yay >/dev/null 2>&1; then
    echo "[-] yay is not installed for user '$SUDO_USER'. Please install it and re-run this script."
    exit 1
fi    
sudo -u "$SUDO_USER" yay -S cmake quickshell-git --needed

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
echo "[+] Installing quickdrift.service"
install -Dm644 system/services/quickdrift.service /etc/xdg/systemd/user/quickdrift.service


echo "-------------------------------"
echo "[+] Installing quickdrift-shell QML config"
cp -rf quickdrift-shell/* /etc/xdg/hyprdrift/quickdrift-shell/

echo "-------------------------------"
echo "[+] Installing Quickshell dev loop"
install -Dm755 system/scripts/quickshell-loop.sh /usr/bin/quickshell-loop

echo "-------------------------------"
echo "[+] Installation complete."
exit 0
