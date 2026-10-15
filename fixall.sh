#!/bin/bash
# =====================================================================
# fixall.sh — Checks USB/ADB/Fastboot readiness before launching the
# main menu. Retries a bounded number of times instead of looping
# forever, and always gives the user a way out.
# =====================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1
source "$SCRIPT_DIR/lib/common.sh"

MAX_ATTEMPTS=10

check_termux_api() {
    if ! command -v termux-usb >/dev/null 2>&1; then
        warn "Termux:API not installed. Installing now..."
        pkg install termux-api -y
    fi
}

check_termux_adb() {
    if ! command -v termux-adb >/dev/null 2>&1 || ! command -v termux-fastboot >/dev/null 2>&1; then
        err "ADB/Fastboot not found."
        info "Running installadb.sh to install them..."
        bash "$SCRIPT_DIR/installadb.sh"
    fi
}

box_header "Device Requirement Check"
section "Checking USB, ADB and Fastboot availability"

attempt=0
device_ready=0

while [ "$attempt" -lt "$MAX_ATTEMPTS" ]; do
    attempt=$((attempt + 1))
    echo -e "${C_CYAN}[$attempt/$MAX_ATTEMPTS] Checking USB via Termux:API...${C_RESET}"

    USB_OUTPUT="$(termux-usb -l 2>/dev/null)"
    USB_ID="$(echo "$USB_OUTPUT" | grep -oE '/dev/bus/usb/[0-9]+/[0-9]+')"

    if [ -z "$USB_ID" ]; then
        err "No USB device detected."
        check_termux_api
        warn "Plug in the device (or enable OTG) and make sure you grant the USB permission prompt."
        sleep 2
        if ! confirm "Try again?"; then
            break
        fi
        continue
    fi

    ok "USB detected: $USB_ID"
    check_termux_adb

    info "Searching for ADB devices..."
    ADB_DEVICE="$(termux-adb devices 2>/dev/null | awk 'NR>1 && $2=="device" {print $1}')"
    if [ -n "$ADB_DEVICE" ]; then
        ok "ADB device found: $ADB_DEVICE"
        device_ready=1
        break
    fi

    info "Searching for Fastboot devices..."
    FASTBOOT_DEVICE="$(termux-fastboot devices 2>/dev/null | awk 'NR>1 {print $1}')"
    if [ -n "$FASTBOOT_DEVICE" ]; then
        ok "Fastboot device found: $FASTBOOT_DEVICE"
        device_ready=1
        break
    fi

    err "USB detected but no ADB/Fastboot device responded."
    warn "Check USB debugging is enabled, the cable supports data, and you accepted any on-device prompt."
    sleep 2
    if ! confirm "Try again?"; then
        break
    fi
done

if [ "$device_ready" -eq 1 ]; then
    ok "Device connected successfully! Launching Termux Root Recovery Tool..."
    sleep 1
    exec "$SCRIPT_DIR/flash.sh"
else
    warn "Could not confirm a connected device after $attempt attempt(s)."
    if confirm "Open the main menu anyway (you can retry a connection check from there)?"; then
        exec "$SCRIPT_DIR/flash.sh"
    else
        goodbye
    fi
fi
