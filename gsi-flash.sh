#!/bin/bash
# =====================================================================
# gsi-flash.sh — GSI (Generic System Image) ROM flashing tool
# =====================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1
source "$SCRIPT_DIR/lib/common.sh"

show_menu() {
    box_header "°GSI ROM Flashing Tool°"
    section "What would you like to do?"
    echo -e "${C_BLUE}┌──────────────────────────────────────────────┐${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE} 1. ${C_GREEN}Check fastboot device                    ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE} 2. ${C_GREEN}Flash VBMETA                             ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE} 3. ${C_GREEN}Fastboot to FastbootD                    ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE} 4. ${C_GREEN}Check userspace for GSI                  ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE} 5. ${C_RED}Erase system 📵                          ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE} 6. ${C_RED}Delete logical partition 🅰️               ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE} 7. ${C_RED}Delete logical partition 🅱️               ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE} 8. ${C_GREEN}Flash GSI system image                   ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE} 9. ${C_GREEN}Fastboot to recovery                     ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE}10. ${C_RED}Reset device via cmd ${C_MAGENTA}(not for Xiaomi)    ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE}11. ${C_YELLOW}↩️  Return to main menu                   ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE}12. ${C_RED}🚪 Exit                                  ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}└──────────────────────────────────────────────┘${C_RESET}"
}

while true; do
    show_menu
    read -r -p $'\033[1;36mChoice: \033[0m' choice

    case "$choice" in
        1)
            section "Searching Fastboot Device"
            require_tool termux-fastboot && run_step "Checking fastboot devices" termux-fastboot devices
            offer_vbmeta
            ;;
        2)
            section "VBMETA Flash Operation"
            flash_one "vbmeta image" vbmeta --disable-verity --disable-verification
            ;;
        7)
            section "Delete Logical Partition B"
            require_tool termux-fastboot || { press_enter; continue; }
            if danger_confirm "delete the product_b logical partition"; then
                run_step "Deleting product_b partition" termux-fastboot delete-logical-partition product_b
            else
                warn "Skipped."
            fi
            ;;
        6)
            section "Delete Logical Partition A"
            require_tool termux-fastboot || { press_enter; continue; }
            if danger_confirm "delete the product_a logical partition"; then
                run_step "Deleting product_a partition" termux-fastboot delete-logical-partition product_a
            else
                warn "Skipped."
            fi
            ;;
        8)
            section "GSI System Image Flash Operation"
            flash_one "GSI system image" system
            ;;
        3)
            section "Fastboot to FastbootD"
            require_tool termux-fastboot && run_step "Rebooting to FastbootD" termux-fastboot reboot fastboot
            ;;
        9)
            section "Fastboot to Recovery"
            require_tool termux-fastboot && run_step "Rebooting to recovery" termux-fastboot reboot recovery
            ;;
        4)
            section "Check Userspace for GSI"
            require_tool termux-fastboot && run_step "Checking userspace flag" termux-fastboot getvar is-userspace
            ;;
        5)
            section "Erase System Operation"
            require_tool termux-fastboot || { press_enter; continue; }
            if danger_confirm "erase the system partition — the device will not boot until a new system image is flashed"; then
                run_step "Erasing system partition" termux-fastboot erase system
            else
                warn "Skipped."
            fi
            ;;
        11) go_home ;;
        10)
            section "Device Reset Operation"
            warn "WARNING: Not recommended for Xiaomi devices."
            require_tool termux-fastboot || { press_enter; continue; }
            if danger_confirm "perform a full data wipe (fastboot -w) on this device"; then
                run_step "Resetting device" termux-fastboot -w
            else
                warn "Skipped."
            fi
            ;;
        12) goodbye ;;
        *) err "Invalid choice." ;;
    esac

    echo
    if confirm "Return to the GSI Flash menu?"; then
        continue
    else
        goodbye
    fi
done
