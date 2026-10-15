#!/bin/bash
# =====================================================================
# flashAB.sh — A/B partition device flashing tool
# =====================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1
source "$SCRIPT_DIR/lib/common.sh"

flash_slot_pair() {
    # flash_slot_pair "label" "partition_a" "partition_b" [extra flags...]
    local label="$1" part_a="$2" part_b="$3"; shift 3
    flash_one "$label (slot A: $part_a)" "$part_a" "$@"
    if confirm "Also flash slot B ($part_b) now?"; then
        flash_one "$label (slot B: $part_b)" "$part_b" "$@"
    else
        info "Skipped slot B."
    fi
}

show_menu() {
    box_header "🆎 A/B Partition Device Tool"
    section "What would you like to do?"
    echo -e "${C_BLUE}┌──────────────────────────────────────────────┐${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE} 1. ${C_GREEN}Flash boot (current slot)                ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE} 2. ${C_GREEN}Flash init_boot (current slot)           ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE} 3. ${C_GREEN}Flash vendor_boot (current slot)         ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE} 4. ${C_GREEN}Flash recovery (current slot)            ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE} 5. ${C_GREEN}Check active slot 🆎                      ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE} 6. ${C_GREEN}Flash boot 🅰️ + optional 🅱️                ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE} 7. ${C_GREEN}Flash boot 🅱️ only                        ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE} 8. ${C_GREEN}Flash init_boot 🅰️ + optional 🅱️           ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE} 9. ${C_GREEN}Flash init_boot 🅱️ only                   ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE}10. ${C_GREEN}Flash recovery 🅰️ + optional 🅱️            ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE}11. ${C_GREEN}Flash recovery 🅱️ only                    ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE}12. ${C_GREEN}Flash zip (ADB sideload)                 ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE}13. ${C_GREEN}Boot TWRP recovery (one-time boot)       ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE}14. ${C_GREEN}Flash vbmeta 🅰️ + optional 🅱️              ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE}15. ${C_GREEN}Flash vbmeta 🅱️ only                      ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE}16. ${C_GREEN}Activate slot 🅰️                          ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE}17. ${C_GREEN}Activate slot 🅱️                          ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE}18. ${C_GREEN}Flash vendor_boot 🅰️ + optional 🅱️         ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE}19. ${C_GREEN}Flash vendor_boot 🅱️ only                 ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE}20. ${C_YELLOW}↩️  Return to main menu                   ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE}21. ${C_RED}🚪 Exit                                  ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}└──────────────────────────────────────────────┘${C_RESET}"
}

while true; do
    show_menu
    read -r -p $'\033[1;36mChoice: \033[0m' choice

    case "$choice" in
        1)  section "Boot Flash Operation";        flash_one "boot image" boot ;;
        2)  section "init_boot Flash Operation";   flash_one "init_boot image" init_boot ;;
        3)  section "vendor_boot Flash Operation"; flash_one "vendor_boot image" vendor_boot ;;
        4)
            section "Recovery Flash Operation"
            flash_one "recovery image" recovery
            offer_vbmeta
            ;;
        5)
            section "Active Slot Check"
            require_tool termux-fastboot && run_step "Checking active slot" termux-fastboot getvar current-slot
            ;;
        6)  section "Boot A/B Flash Operation";        flash_slot_pair "boot image" boot_a boot_b ;;
        7)  section "Boot_b Flash Operation";          flash_one "boot image (slot B)" boot_b ;;
        8)  section "init_boot A/B Flash Operation";   flash_slot_pair "init_boot image" init_boot_a init_boot_b ;;
        9)  section "init_boot_b Flash Operation";     flash_one "init_boot image (slot B)" init_boot_b ;;
        10) section "Recovery A/B Flash Operation";    flash_slot_pair "recovery image" recovery_a recovery_b ;;
        11) section "Recovery_b Flash Operation";      flash_one "recovery image (slot B)" recovery_b ;;
        12)
            section "ADB Sideload Operation"
            require_tool termux-adb || { press_enter; continue; }
            prompt_path "zip file" romname
            require_file "$romname" || { press_enter; continue; }
            checksum_offer "$romname"
            if confirm "Sideload '$romname' now?"; then
                run_step "Sideloading" termux-adb sideload "$romname"
            else
                warn "Skipped."
            fi
            ;;
        13)
            section "Boot TWRP Recovery (one-time)"
            require_tool termux-fastboot || { press_enter; continue; }
            prompt_path "recovery image" romname
            require_file "$romname" || { press_enter; continue; }
            run_step "Booting recovery (temporary, not flashed)" termux-fastboot boot "$romname"
            ;;
        14) section "vbmeta A/B Flash Operation";  flash_slot_pair "vbmeta" vbmeta_a vbmeta_b --disable-verity --disable-verification ;;
        15)
            section "vbmeta_b Flash Operation"
            flash_one "vbmeta (slot B)" vbmeta_b --disable-verity --disable-verification
            ;;
        16)
            section "Activate Slot A"
            require_tool termux-fastboot && run_step "Activating slot A" termux-fastboot set_active a
            ;;
        17)
            section "Activate Slot B"
            require_tool termux-fastboot && run_step "Activating slot B" termux-fastboot set_active b
            ;;
        18) section "vendor_boot A/B Flash Operation"; flash_slot_pair "vendor_boot" vendor_boot_a vendor_boot_b ;;
        19)
            section "vendor_boot_b Flash Operation"
            flash_one "vendor_boot (slot B)" vendor_boot_b
            ;;
        20) go_home ;;
        21) goodbye ;;
        *) err "Invalid choice." ;;
    esac

    echo
    if confirm "Return to the A/B Partition menu?"; then
        continue
    else
        goodbye
    fi
done
