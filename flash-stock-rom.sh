#!/bin/bash
# =====================================================================
# flash-stock-rom.sh — Wraps a vendor "stock-rom" flash_all*.sh set.
# Expected to be copied into the extracted firmware folder (named
# 'stock-rom') and run from there, same as the original tool.
# =====================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

# TRRT_TOOL_HOME is exported by flash.sh when it launches this script
# from the Download/stock-rom copy; fall back to a sane default so the
# script also still works if a user runs it directly.
TRRT_TOOL_HOME="${TRRT_TOOL_HOME:-$HOME/Termux-Root-Recovery-Tool}"
if [ -f "$TRRT_TOOL_HOME/lib/common.sh" ]; then
    source "$TRRT_TOOL_HOME/lib/common.sh"
else
    # Minimal fallback so this script still runs stand-alone.
    C_RED="\033[1;31m"; C_GREEN="\033[1;92m"; C_YELLOW="\033[1;33m"; C_CYAN="\033[1;36m"; C_WHITE="\033[1;97m"; C_RESET="\033[0m"
    err()  { echo -e "${C_RED}✗ $*${C_RESET}"; }
    ok()   { echo -e "${C_GREEN}✓ $*${C_RESET}"; }
    warn() { echo -e "${C_YELLOW}⚠ $*${C_RESET}"; }
    info() { echo -e "${C_GREEN}► $*${C_RESET}"; }
    confirm() { read -r -p "$1 [y/N]: " a; [[ "$a" =~ ^[Yy] ]]; }
    term_width() { local w="${COLUMNS:-$(tput cols 2>/dev/null)}"; [ -z "$w" ] && w=50; (( w>72 )) && w=72; (( w<40 )) && w=40; echo "$w"; }
    hr() { local w="${1:-$(term_width)}" l; printf -v l '%*s' "$w" ''; echo -e "${C_CYAN}${l// /─}${C_RESET}"; }
    menu_start() { clear; local w; w=$(term_width); hr "$w"; echo -e "  ${C_YELLOW}★ ${C_WHITE}Termux Root Recovery Tool${C_RESET}"; [ -n "$1" ] && echo -e "  ${C_YELLOW}$1${C_RESET}"; hr "$w"; }
    menu_item() { printf "  %b%2s.%b %s  %b%s%b\n" "$C_WHITE" "$1" "$C_RESET" "$2" "${4:-$C_GREEN}" "$3" "$C_RESET"; }
    menu_end() { hr; }
    section() { hr; echo -e "${C_YELLOW}▸ $1${C_RESET}"; }
    goodbye() { ok "Thank you for using Termux Root Recovery Tool!"; exit 0; }
    go_home() { [ -x "$TRRT_TOOL_HOME/flash.sh" ] && exec "$TRRT_TOOL_HOME/flash.sh"; goodbye; }
fi

file1="flash_all.sh"
file2="flash_all_lock.sh"
file3="flash_all_except_data_storage.sh"

missing=0
for f in "$file1" "$file2" "$file3"; do
    if [ ! -f "$f" ]; then
        err "'$f' not found in $(pwd)."
        missing=1
    fi
done
if [ "$missing" -eq 1 ]; then
    warn "Rename your extracted firmware folder to 'stock-rom', copy it to your Download folder, and run this again."
    exit 1
fi

chmod +x "$file1" "$file2" "$file3"
ok "Vendor flash scripts found and made executable."

show_menu() {
    menu_start "Fastboot ROM Flashing Tool"
    menu_item "1" "💿" "Flash without locking bootloader"
    menu_item "2" "🔒" "Flash and lock bootloader" "$C_RED"
    menu_item "3" "💾" "Flash except data/storage"
    menu_item "4" "↩️" "Return to main menu" "$C_YELLOW"
    menu_item "5" "🚪" "Exit" "$C_RED"
    menu_end
}

while true; do
    show_menu
    read -r -p $'\033[1;36mChoice: \033[0m' choice
    case "$choice" in
        1)
            if confirm "This runs the vendor's own flash_all.sh (full stock ROM flash). Continue?"; then
                bash "$file1"
                ok "Flash operation finished — check the output above for vendor-reported errors."
            else
                warn "Cancelled."
            fi
            go_home
            ;;
        2)
            warn "Locking the bootloader after this flash will wipe the device and make it harder to flash/unlock again."
            if confirm "Run flash_all_lock.sh and lock the bootloader?"; then
                bash "$file2"
                ok "Flash operation finished — check the output above for vendor-reported errors."
            else
                warn "Cancelled."
            fi
            go_home
            ;;
        3)
            if confirm "Run flash_all_except_data_storage.sh (keeps your data/storage partition)?"; then
                bash "$file3"
                ok "Flash operation finished — check the output above for vendor-reported errors."
            else
                warn "Cancelled."
            fi
            go_home
            ;;
        4) go_home ;;
        5) goodbye ;;
        *) err "Invalid choice." ;;
    esac
done
