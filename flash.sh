#!/bin/bash
# =====================================================================
# flash.sh — Main menu: Flash • Recovery • Root • Customize • Sideload
# =====================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1
source "$SCRIPT_DIR/lib/common.sh"

show_menu() {
    box_header "Flash • Recovery • Root • Customize • Sideload"
    section "What would you like to do?"
    echo -e "${C_BLUE}┌──────────────────────────────────────────────┐${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE} 1. ${C_GREEN}💿 Flash Recovery                        ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE} 2. ${C_GREEN}📀 Flash VBMETA                          ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE} 3. ${C_GREEN}💿 Flash Boot image                      ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE} 4. ${C_GREEN}📀 Flash init_boot image                 ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE} 5. ${C_GREEN}📀 Flash vendor_boot image               ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE} 6. ${C_GREEN}💿 Flash super_empty image               ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE} 7. ${C_GREEN}🔌 Check fastboot devices                ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE} 8. ${C_GREEN}🔌 Check ADB devices                     ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE} 9. ${C_GREEN}🔃 Reboot to fastboot mode               ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE}10. ${C_GREEN}♻️  Reboot to recovery mode               ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE}11. ${C_GREEN}🔛 Reboot system ${C_MAGENTA}(from fastboot)        ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE}12. ${C_GREEN}📁 Flash zip (ADB sideload)              ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE}13. ${C_GREEN}📂 Flash fastboot ROM                    ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE}14. ${C_GREEN}☯️  Flash GSI ROM ${C_MAGENTA}(dynamic partition)     ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE}15. ${C_GREEN}🆎 A/B partition tool                    ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE}16. ${C_GREEN}📵 Fix USB not working                   ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE}17. ${C_YELLOW}🔓 Bootloader unlock ${C_MAGENTA}(coming soon)       ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE}18. ${C_GREEN}🔐 FRP remove ${C_MAGENTA}(experimental)             ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE}19. ${C_GREEN}⬇️  Firmware content extractor tool       ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE}20. ${C_GREEN}📝 Run a manual command                  ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE}21. ${C_GREEN}🔎 MTK BROM/Preloader detect ${C_MAGENTA}(read-only)  ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}│ ${C_WHITE}22. ${C_RED}🚪 Exit                                  ${C_BLUE}│${C_RESET}"
    echo -e "${C_BLUE}└──────────────────────────────────────────────┘${C_RESET}"
}

while true; do
    show_menu
    read -r -p $'\033[1;36mChoice: \033[0m' choice

    case "$choice" in
        1)
            section "Recovery Flash Operation"
            flash_one "recovery image" recovery
            offer_vbmeta
            ;;
        2)
            section "VBMETA Flash Operation"
            flash_one "vbmeta image" vbmeta --disable-verity --disable-verification
            ;;
        3)
            section "Boot Image Flash Operation"
            flash_one "boot image" boot
            ;;
        4)
            section "init_boot Flash Operation"
            flash_one "init_boot image" init_boot
            offer_vbmeta
            ;;
        5)
            section "vendor_boot Flash Operation"
            flash_one "vendor_boot image" vendor_boot
            offer_vbmeta
            ;;
        6)
            section "super_empty Flash Operation"
            require_tool termux-fastboot || { press_enter; continue; }
            prompt_path "super_empty.img" romname
            require_file "$romname" || { press_enter; continue; }
            checksum_offer "$romname"
            if danger_confirm "wipe and recreate the super partition layout using '$romname'"; then
                run_step "Flashing super_empty" termux-fastboot wipe-super "$romname"
                offer_vbmeta
            else
                warn "Skipped."
            fi
            ;;
        7)
            section "Searching Fastboot Devices"
            require_tool termux-fastboot && run_step "Checking fastboot devices" termux-fastboot devices
            ;;
        8)
            section "Searching ADB Devices"
            require_tool termux-adb && run_step "Checking ADB devices" termux-adb devices
            ;;
        9)
            section "Reboot to Fastboot"
            require_tool termux-adb && run_step "Rebooting to fastboot mode" termux-adb reboot bootloader
            ;;
        10)
            section "Reboot to Recovery"
            require_tool termux-adb && run_step "Rebooting to recovery mode" termux-adb reboot recovery
            ;;
        11)
            section "System Reboot"
            require_tool termux-fastboot && run_step "Rebooting to system" termux-fastboot reboot
            ;;
        12)
            section "ADB Sideload Operation"
            require_tool termux-adb || { press_enter; continue; }
            prompt_path "update/magisk/ROM zip" romname
            require_file "$romname" || { press_enter; continue; }
            checksum_offer "$romname"
            if confirm "Sideload '$romname' now?"; then
                run_step "Sideloading" termux-adb sideload "$romname"
            else
                warn "Skipped."
            fi
            ;;
        13)
            section "Stock ROM Flash Operation"
            info "Launching Stock ROM Flashing Utility..."
            dest_dir="/storage/emulated/0/Download/stock-rom"
            if [ ! -d "$dest_dir" ]; then
                err "'$dest_dir' does not exist yet."
                warn "Rename your extracted firmware folder to 'stock-rom' and copy it into your Download folder first."
            else
                cp "$SCRIPT_DIR/flash-stock-rom.sh" "$dest_dir/"
                (cd "$dest_dir" && TRRT_TOOL_HOME="$SCRIPT_DIR" bash flash-stock-rom.sh)
            fi
            ;;
        14)
            section "GSI Flash Tool"
            info "Launching GSI Flash Tool..."
            exec "$SCRIPT_DIR/gsi-flash.sh"
            ;;
        15)
            section "A/B Partition Tool"
            info "Launching A/B Partition Device Tool..."
            exec "$SCRIPT_DIR/flashAB.sh"
            ;;
        16)
            section "USB Fix Tool"
            info "Launching USB/OTG Fix Tool..."
            exec "$SCRIPT_DIR/usbfix.sh"
            ;;
        17)
            section "Bootloader Unlock"
            info "Coming soon — watch the project README for updates."
            ;;
        18)
            section "FRP Reset Tool"
            info "Launching FRP Tool..."
            exec "$SCRIPT_DIR/frp.sh"
            ;;
        19)
            section "Firmware Content Extractor"
            info "Opening the Firmware Content Extractor web tool..."
            if command -v termux-open-url >/dev/null 2>&1; then
                termux-open-url https://fce-tool.pages.dev/
            elif command -v xdg-open >/dev/null 2>&1; then
                xdg-open https://fce-tool.pages.dev/
            else
                warn "No URL opener found. Visit https://fce-tool.pages.dev/ manually."
            fi
            ;;
        20)
            section "Manual Command"
            info "Type a full command exactly as you want it run (example: termux-fastboot getvar all)."
            warn "This runs on your device/session with no extra safety checks — double-check what you type."
            read -r -p $'\033[1;97mCommand: \033[0m' user_command
            if [ -n "$user_command" ]; then
                trrt_log "MANUAL | $user_command"
                bash -c "$user_command"
            else
                warn "Nothing entered."
            fi
            ;;
        21)
            exec "$SCRIPT_DIR/mtk-detect.sh"
            ;;
        22)
            goodbye
            ;;
        *)
            err "Invalid choice."
            ;;
    esac

    echo
    if confirm "Return to the main menu?"; then
        continue
    else
        goodbye
    fi
done
