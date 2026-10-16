#!/bin/bash
# =====================================================================
# usbfix.sh — USB / OTG / ADB-Fastboot troubleshooting tool
# =====================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1
source "$SCRIPT_DIR/lib/common.sh"

show_menu() {
    menu_start "USB OTG Fixing Tool"
    menu_item " 1" "🔌" "Check OTG device"
    menu_item " 2" "♻️" "Reinstall Termux:API"
    menu_item " 3" "♻️" "Reinstall ADB/Fastboot"
    menu_item " 4" "📵" "Stop ADB server"
    menu_item " 5" "🔁" "Start ADB server"
    menu_item " 6" "🔌" "Check ADB devices"
    menu_item " 7" "🔌" "Check fastboot devices"
    menu_item " 8" "⬇️" "Install android-tools (fastboot ROM)"
    menu_item " 9" "↩️" "Return to main menu" "$C_YELLOW"
    menu_item "10" "🚪" "Exit" "$C_RED"
    menu_end
}

while true; do
    show_menu
    read -r -p $'\033[1;36mChoice: \033[0m' choice

    case "$choice" in
        1)
            section "Connected Device in OTG Port Tester 🔗"
            info "Checking OTG & USB 🔌 port..."
            require_tool termux-usb && termux-usb -l
            ;;
        2)
            section "Termux:API Reinstallation"
            info "Reinstalling Termux:API..."
            yes | pkg uninstall termux-api >/dev/null 2>&1
            if pkg install termux-api -y; then
                ok "Termux:API reinstalled."
            else
                err "Termux:API reinstall failed — check your internet connection and storage space."
            fi
            ;;
        3)
            section "Remove & Reinstall ADB/Fastboot"
            info "Reinstalling termux-adb/fastboot..."
            yes | pkg uninstall termux-adb >/dev/null 2>&1
            bash "$SCRIPT_DIR/installadb.sh"
            ;;
        4)
            section "Stop ADB Server"
            info "Stopping ADB server..."
            require_tool termux-adb && run_step "Stopping ADB server" termux-adb kill-server
            ;;
        5)
            section "Start ADB Server"
            info "Starting ADB server..."
            require_tool termux-adb && run_step "Starting ADB server" termux-adb start-server
            ;;
        6)
            section "Search ADB Devices"
            require_tool termux-adb && run_step "Searching for ADB devices" termux-adb devices
            ;;
        7)
            section "Search Fastboot Devices"
            require_tool termux-fastboot && run_step "Searching for fastboot devices" termux-fastboot devices
            ;;
        8)
            section "Install android-tools"
            info "Installing android-tools (only needed for fastboot ROM flashing on some devices)..."
            if pkg install android-tools -y; then
                ok "android-tools installed."
            else
                err "Install failed — check your internet connection and storage space."
            fi
            ;;
        9) go_home ;;
        10) goodbye ;;
        *) err "Invalid choice." ;;
    esac

    echo
    if confirm "Return to the USB OTG Fix menu?"; then
        continue
    else
        goodbye
    fi
done
