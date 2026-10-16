#!/bin/bash
# =====================================================================
# flash.sh — Main menu: Flash • Recovery • Root • Customize • Sideload
# =====================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1
source "$SCRIPT_DIR/lib/common.sh"

show_menu() {
    menu_start "Flash • Recovery • Root • Customize • Sideload"
    menu_item " 1" "💿" "Flash Recovery"
    menu_item " 2" "📀" "Flash VBMETA"
    menu_item " 3" "💿" "Flash Boot image"
    menu_item " 4" "📀" "Flash init_boot image"
    menu_item " 5" "📀" "Flash vendor_boot image"
    menu_item " 6" "💿" "Flash super_empty image"
    menu_item " 7" "🔌" "Check fastboot devices"
    menu_item " 8" "🔌" "Check ADB devices"
    menu_item " 9" "🔃" "Reboot to fastboot mode"
    menu_item "10" "♻️" "Reboot to recovery mode"
    menu_item "11" "🔛" "Reboot system (from fastboot)"
    menu_item "12" "📁" "Flash zip (ADB sideload)"
    menu_item "13" "📂" "Flash fastboot ROM"
    menu_item "14" "☯️" "Flash GSI ROM (dynamic partition)"
    menu_item "15" "🆎" "A/B partition tool"
    menu_item "16" "📵" "Fix USB not working"
    menu_item "17" "🔓" "Bootloader unlock (coming soon)" "$C_YELLOW"
    menu_item "18" "🔐" "FRP remove (experimental)"
    menu_item "19" "⬇️" "Firmware content extractor tool"
    menu_item "20" "📝" "Run a manual command"
    menu_item "21" "🔎" "MTK BROM/Preloader detect (read-only)"
    menu_item "22" "🚪" "Exit" "$C_RED"
    menu_end
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
