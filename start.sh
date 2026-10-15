#!/bin/bash
# =====================================================================
# start.sh — Splash screen + launcher menu
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
# Splash screen
# ---------------------------------------------------------------------
clear
echo -e "${C_CYAN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
echo -e "┃           ★ Repair A2Z Root Tool ★              ┃"
echo -e "┃               Android Edition                   ┃"
echo -e "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${C_RESET}"
sleep 0.4

echo -e "${C_GREEN}"
echo "    ████████╗██████╗   ██████╗   ████████╗"
echo "    ╚══██╔══╝██╔══██╗  ██╔══██╗  ╚══██╔══╝"
echo "       ██║   ██████╔╝  ██████╔╝     ██║  "
echo "       ██║   ██╔══██╗  ██╔══██╗     ██║   "
echo "       ██║   ██║  ██║  ██║  ██║     ██║   "
echo "       ╚═╝   ╚═╝  ╚═╝  ╚═╝  ╚═╝     ╚═╝"
echo "       Termux - Root - Recovery - Tool"
echo -e "${C_RESET}"
sleep 1

echo -e "${C_YELLOW}* ♻️ Initializing environment...${C_RESET}";            sleep 0.2
echo -e "${C_YELLOW}* 🔍 Checking Termux environment...${C_RESET}";         sleep 0.2
echo -e "${C_YELLOW}* ⚙️ Preparing ADB/Fastboot interface...${C_RESET}";    sleep 0.2
echo -e "${C_YELLOW}* ⏳ Loading UI engine...${C_RESET}";                   sleep 0.2

for i in 10 25 40 55 70 85 100; do
    bars=$((i / 5))
    printf "["
    for ((j = 0; j < bars; j++)); do printf "█"; done
    for ((j = bars; j < 20; j++)); do printf " "; done
    printf "] %s%%\r" "$i"
    sleep 0.08
done
echo
sleep 0.3

echo -e "${C_CYAN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
echo -e "┃  Developed By : Repair A2Z                      ┃"
echo -e "┃  YouTube      : @repaira2z                      ┃"
echo -e "┃  Instagram    : dineshpatel43642                ┃"
echo -e "┃  Telegram     : RepairA2Z / group                ┃"
echo -e "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${C_RESET}"
sleep 1

# ---------------------------------------------------------------------
# Start menu
# ---------------------------------------------------------------------
show_menu() {
    box_header "Welcome — choose an option to begin"
    echo -e "${C_BLUE}┌──────────────────────────────────────────────┐${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE}1. ${C_GREEN}Check requirements & launch tool          ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE}2. ${C_GREEN}Launch tool main menu                     ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE}3. ${C_GREEN}About developer                           ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE}4. ${C_RED}Exit                                      ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}└──────────────────────────────────────────────┘${C_RESET}"
}

show_about_menu() {
    box_header "★ Repair A2Z - About ★"
    echo -e "${C_BLUE}┌──────────────────────────────────────────────┐${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE}1. ${C_GREEN}YouTube - Repair A2Z                      ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE}2. ${C_GREEN}YouTube Mix                               ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE}3. ${C_GREEN}Instagram                                 ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE}4. ${C_GREEN}Facebook                                  ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE}5. ${C_GREEN}Telegram channel                          ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE}6. ${C_GREEN}Telegram group                            ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE}7. ${C_RED}Back                                      ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}└──────────────────────────────────────────────┘${C_RESET}"
}

while true; do
    show_menu
    read -r -p $'\033[1;36mChoice: \033[0m' start_choice

    case "$start_choice" in
        1)
            info "Checking requirements..."
            sleep 0.5
            exec "$SCRIPT_DIR/fixall.sh"
            ;;
        2)
            info "Launching main menu..."
            sleep 0.5
            exec "$SCRIPT_DIR/flash.sh"
            ;;
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
                    *) warn "Invalid option!"; sleep 0.5 ;;
                esac
            done
            ;;
        4)
            goodbye
            ;;
        *)
            warn "Invalid choice!"
            sleep 0.5
            ;;
    esac
done
