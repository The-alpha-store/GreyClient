#!/bin/bash
# =====================================================================
# mtk-detect.sh — Read-only MediaTek BROM / Preloader / DA identifier
#
# Based on the VID/PID table and safety rules from the project's
# Linux BROM/Preloader detection notes. IMPORTANT: Termux has no
# udev or raw libusb hotplug access (that requires a desktop Linux
# host with root-level USB subsystem access), so this is a
# point-in-time snapshot you re-run right as the device is plugged
# in or powered on — not continuous event-driven monitoring.
#
# This script only reads USB descriptor info. It never sends a
# handshake, loads a Download Agent, or flashes anything.
# =====================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1
source "$SCRIPT_DIR/lib/common.sh"

MTK_VID="0e8d"

mtk_pid_meaning() {
    case "$1" in
        0003) echo "BROM (boot ROM) mode" ;;
        2000) echo "Preloader (VCOM) mode" ;;
        2001) echo "Download Agent (DA) running" ;;
        *)    echo "another MediaTek mode (PID $1) — Android/ADB/Fastboot composite or OEM-specific; verify against your own captures" ;;
    esac
}

detect_mtk() {
    if ! command -v lsusb >/dev/null 2>&1; then
        warn "'lsusb' not found — attempting to install the 'usbutils' package..."
        pkg install usbutils -y >/dev/null 2>&1
    fi

    if ! command -v lsusb >/dev/null 2>&1; then
        err "Could not install 'lsusb'."
        warn "Falling back to the raw Termux USB device list (no VID/PID decoding available)."
        require_tool termux-usb && termux-usb -l
        return 1
    fi

    local output
    output="$(lsusb 2>/dev/null)"
    if [ -z "$output" ]; then
        warn "No USB devices currently enumerated."
        return 1
    fi

    echo "$output"
    echo
    local found=0 pid meaning
    while IFS= read -r line; do
        if [[ "$line" =~ ID\ ${MTK_VID}:([0-9a-fA-F]{4}) ]]; then
            found=1
            pid="${BASH_REMATCH[1],,}"
            meaning="$(mtk_pid_meaning "$pid")"
            ok "MediaTek device found — VID ${MTK_VID}:${pid} → ${meaning}"
            trrt_log "MTK-DETECT | VID ${MTK_VID}:${pid} | $meaning"
        fi
    done <<< "$output"

    if [ "$found" -eq 0 ]; then
        info "No MediaTek (VID ${MTK_VID}) device currently enumerated."
        warn "BROM/Preloader only shows up for a short window right at power-on/USB plug-in."
        warn "Re-run this check right as you connect the cable or power on the device."
    fi
}

menu_start "MTK BROM / Preloader Detect"
section "MediaTek download-mode identification (read-only, no commands sent)"
detect_mtk
echo
warn "Read-only: this identifies the USB mode only. No handshake, DA load, or flash command is ever sent from here."
press_enter
go_home
