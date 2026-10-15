#!/bin/bash
# =====================================================================
# usbfix.sh — USB / OTG / ADB-Fastboot troubleshooting tool
# =====================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1
source "$SCRIPT_DIR/lib/common.sh"

show_menu() {
    box_header "USB OTG Fixing Tool"
    section "What would you like to do?"
    echo -e "${C_BLUE}┌──────────────────────────────────────────────┐${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE} 1. ${C_GREEN}🔌 Check OTG device                      ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE} 2. ${C_GREEN}♻️  Reinstall Termux:API                  ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE} 3. ${C_GREEN}♻️  Reinstall ADB/Fastboot                ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE} 4. ${C_GREEN}📵 Stop ADB server                       ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE} 5. ${C_GREEN}🔁 Start ADB server                      ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE} 6. ${C_GREEN}🔌 Check ADB devices                     ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE} 7. ${C_GREEN}🔌 Check fastboot devices                ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE} 8. ${C_GREEN}⬇️  Install android-tools ${C_MAGENTA}(fastboot ROM)  ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE} 9. ${C_YELLOW}↩️  Return to main menu                   ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE}10. ${C_RED}🚪 Exit                                  ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}└──────────────────────────────────────────────┘${C_RESET}"
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
