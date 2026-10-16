#!/bin/bash
# =====================================================================
# start.sh — Splash screen + launcher menu
#
# Set TRRT_FAST=1 (or run non-interactively, e.g. piped/scripted) to
# skip the animated splash and jump straight to the menu — useful for
# repeated runs during a repair session where the intro gets old fast.
# =====================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1
source "$SCRIPT_DIR/lib/common.sh"

open_url() {
    local url="$1"
    if command -v termux-open-url >/dev/null 2>&1; then
        termux-open-url "$url"
    elif command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$url"
    else
        am start -a android.intent.action.VIEW -d "$url" >/dev/null 2>&1
    fi
}

# ---------------------------------------------------------------------
# Splash screen — skipped entirely in fast mode or non-interactive use
# ---------------------------------------------------------------------
if [ -t 1 ] && [ -z "${TRRT_FAST:-}" ]; then
    clear
    echo -e "${C_CYAN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
    echo -e "┃           ★ Repair A2Z Root Tool ★              ┃"
    echo -e "┃               Android Edition                   ┃"
    echo -e "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${C_RESET}"
    sleep 0.25

    echo -e "${C_GREEN}"
    echo "    ████████╗██████╗   ██████╗   ████████╗"
    echo "    ╚══██╔══╝██╔══██╗  ██╔══██╗  ╚══██╔══╝"
    echo "       ██║   ██████╔╝  ██████╔╝     ██║  "
    echo "       ██║   ██╔══██╗  ██╔══██╗     ██║   "
    echo "       ██║   ██║  ██║  ██║  ██║     ██║   "
    echo "       ╚═╝   ╚═╝  ╚═╝  ╚═╝  ╚═╝     ╚═╝"
    echo "       Termux - Root - Recovery - Tool"
    echo -e "${C_RESET}"
    sleep 0.4
    echo -e "${C_CYAN}(set TRRT_FAST=1 to skip this intro next time)${C_RESET}"

    echo -e "${C_YELLOW}* ♻️ Initializing environment...${C_RESET}";            sleep 0.1
    echo -e "${C_YELLOW}* 🔍 Checking Termux environment...${C_RESET}";         sleep 0.1
    echo -e "${C_YELLOW}* ⚙️ Preparing ADB/Fastboot interface...${C_RESET}";    sleep 0.1
    echo -e "${C_YELLOW}* ⏳ Loading UI engine...${C_RESET}";                   sleep 0.1

    for i in 20 45 70 100; do
        bars=$((i / 5))
        printf "["
        for ((j = 0; j < bars; j++)); do printf "█"; done
        for ((j = bars; j < 20; j++)); do printf " "; done
        printf "] %s%%\r" "$i"
        sleep 0.05
    done
    echo
    sleep 0.15

    echo -e "${C_CYAN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
    echo -e "┃  Developed By : Repair A2Z                      ┃"
    echo -e "┃  YouTube      : @repaira2z                      ┃"
    echo -e "┃  Instagram    : dineshpatel43642                ┃"
    echo -e "┃  Telegram     : RepairA2Z / group                ┃"
    echo -e "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${C_RESET}"
    sleep 0.5
fi

# ---------------------------------------------------------------------
# Start menu
# ---------------------------------------------------------------------
show_menu() {
    menu_start "Welcome — choose an option to begin"
    menu_item "1" "🚀" "Check requirements & launch tool"
    menu_item "2" "📋" "Launch tool main menu"
    menu_item "3" "ℹ️" "About developer"
    menu_item "4" "🚪" "Exit" "$C_RED"
    menu_end
}

show_about_menu() {
    menu_start "★ Repair A2Z - About ★"
    menu_item "1" "▶️" "YouTube - Repair A2Z"
    menu_item "2" "▶️" "YouTube Mix"
    menu_item "3" "📷" "Instagram"
    menu_item "4" "📘" "Facebook"
    menu_item "5" "✈️" "Telegram channel"
    menu_item "6" "✈️" "Telegram group"
    menu_item "7" "↩️" "Back" "$C_RED"
    menu_end
}

while true; do
    show_menu
    read -r -p $'\033[1;36mChoice: \033[0m' start_choice

    case "$start_choice" in
        1) exec "$SCRIPT_DIR/fixall.sh" ;;
        2) exec "$SCRIPT_DIR/flash.sh" ;;
        3)
            while true; do
                show_about_menu
                read -r -p $'\033[1;36mChoose: \033[0m' ab
                case "$ab" in
                    1) open_url "https://youtube.com/@repaira2z" ;;
                    2) open_url "https://youtube.com/@repaira2zmix" ;;
                    3) open_url "https://www.instagram.com/dineshpatel43642" ;;
                    4) open_url "https://m.facebook.com/Dines" ;;
                    5) open_url "https://t.me/RepairA2Z" ;;
                    6) open_url "https://t.me/repaira2zgroup" ;;
                    7) break ;;
                    *) warn "Invalid option!"; sleep 0.3 ;;
                esac
            done
            ;;
        4) goodbye ;;
        *) warn "Invalid choice!"; sleep 0.3 ;;
    esac
done
