#!/bin/bash
# =====================================================================
# lib/common.sh — shared helpers for Termux Root Recovery Tool
#
# This file is meant to be *sourced*, never executed directly:
#     source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
#
# It centralizes everything that used to be copy-pasted into every
# single menu script: colors, box drawing, confirmations, file/tool
# checks, checksum helpers, logging and the flash/run wrapper that
# actually reports success or failure correctly.
# =====================================================================

# ---------------------------------------------------------------------
# Resolve the tool's root directory regardless of where it's sourced
# from, so every script can reliably find its neighbors and the log
# folder no matter what the user's current working directory is.
# ---------------------------------------------------------------------
TRRT_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TRRT_LOG_DIR="$TRRT_HOME/logs"
mkdir -p "$TRRT_LOG_DIR" 2>/dev/null
TRRT_LOG_FILE="$TRRT_LOG_DIR/trrt-$(date +%Y%m%d).log"

# ---------------------------------------------------------------------
# Colors
# ---------------------------------------------------------------------
C_RESET="\033[0m"
C_CYAN="\033[1;36m"
C_GREEN="\033[1;92m"
C_YELLOW="\033[1;33m"
C_RED="\033[1;31m"
C_WHITE="\033[1;97m"
C_BLUE="\033[1;34m"
C_MAGENTA="\033[1;35m"

# Abort cleanly on Ctrl+C instead of leaving the terminal in a weird
# state or silently continuing into the next prompt.
trap 'echo -e "\n${C_RED}✗ Cancelled by user.${C_RESET}"; exit 130' INT

# ---------------------------------------------------------------------
# Logging — every flash/erase/reset action gets a line in
# logs/trrt-YYYYMMDD.log so a failed session can be diagnosed later.
# Never fails the calling script even if the log can't be written.
# ---------------------------------------------------------------------
trrt_log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$TRRT_LOG_FILE" 2>/dev/null
}

# ---------------------------------------------------------------------
# UI helpers
# ---------------------------------------------------------------------
box_header() {
    # box_header "Subtitle shown under the tool's name"
    local subtitle="$1"
    clear
    echo -e "${C_CYAN}"
    echo "╔═══════════════════════════════════════════════╗"
    printf "║  %b★ %bTermux Root Recovery Tool%b★%b   ║\n" "$C_YELLOW" "$C_WHITE" "$C_YELLOW" "$C_CYAN"
    echo "╠═══════════════════════════════════════════════╣"
    printf "║  %b%-45s%b║\n" "$C_MAGENTA" "$subtitle" "$C_CYAN"
    echo "╚═══════════════════════════════════════════════╝${C_RESET}"
}

section() {
    local title="$1"
    echo -e "${C_CYAN}╭───────────────────────────────────────────────╮${C_RESET}"
    echo -e "${C_CYAN}│${C_YELLOW} ${title}${C_RESET}"
    echo -e "${C_CYAN}╰───────────────────────────────────────────────╯${C_RESET}"
}

info()  { echo -e "${C_GREEN}► $*${C_RESET}"; }
warn()  { echo -e "${C_YELLOW}⚠ $*${C_RESET}"; }
err()   { echo -e "${C_RED}✗ $*${C_RESET}"; }
ok()    { echo -e "${C_GREEN}✓ $*${C_RESET}"; }

press_enter() {
    read -r -p $'\033[1;36mPress Enter to continue...\033[0m'
}

# confirm "Question text" -> 0 (yes) / 1 (no). Defaults to "no" so a
# stray Enter key never triggers a destructive action by accident.
confirm() {
    local prompt="$1"
    local ans
    read -r -p $"$(echo -e "${C_WHITE}${prompt} [y/N]: ${C_RESET}")" ans
    [[ "$ans" =~ ^([Yy]|[Yy][Ee][Ss])$ ]]
}

# ---------------------------------------------------------------------
# Requirement / safety checks
# ---------------------------------------------------------------------
require_tool() {
    local tool="$1"
    if ! command -v "$tool" >/dev/null 2>&1; then
        err "Required tool '$tool' was not found."
        warn "Run option 'Fix USB / ADB / Fastboot' from the main menu, or 'bash installadb.sh', then try again."
        return 1
    fi
    return 0
}

# require_file "/path/to/file" — checks it exists, is a regular file,
# and is not empty (an empty/partial download is a very common cause
# of a failed flash that otherwise looks like a successful command).
require_file() {
    local path="$1"
    if [ -z "$path" ]; then
        err "No path entered."
        return 1
    fi
    # Strip optional surrounding quotes a user may paste/drag in.
    path="${path%\"}"; path="${path#\"}"
    path="${path%\'}"; path="${path#\'}"
    if [ ! -f "$path" ]; then
        err "'$path' was not found."
        warn "Double check the path and that the file finished copying/downloading."
        return 1
    fi
    if [ ! -s "$path" ]; then
        err "'$path' exists but is empty (0 bytes)."
        return 1
    fi
    return 0
}

# prompt_path "human label" resultvar — reads a path into $resultvar,
# trimming quotes so copy/pasted or drag-and-dropped paths both work.
prompt_path() {
    local label="$1" __resultvar="$2" path
    info "Please enter the $label file location."
    read -e -r -p $'\033[1;97mPath: \033[0m' path
    path="${path%\"}"; path="${path#\"}"
    path="${path%\'}"; path="${path#\'}"
    printf -v "$__resultvar" '%s' "$path"
}

# checksum_offer "/path/to/file" — optional sha256 display so the
# user can cross-check against the ROM/firmware source before
# trusting a multi-gigabyte file to a flash command.
checksum_offer() {
    local path="$1"
    if confirm "Show SHA256 checksum of this file before continuing?"; then
        if command -v sha256sum >/dev/null 2>&1; then
            echo -e "${C_CYAN}Computing checksum (this can take a while for large files)...${C_RESET}"
            sha256sum "$path"
        else
            warn "sha256sum is not available on this system; skipping."
        fi
    fi
}

# danger_confirm "description of what will happen" — used before any
# operation that is destructive or irreversible (erasing partitions,
# locking the bootloader, factory reset, etc).
danger_confirm() {
    local action="$1"
    warn "This will $action."
    warn "This can make the device unbootable if interrupted or used on the wrong hardware."
    confirm "Type y to continue, anything else to cancel"
}

# ---------------------------------------------------------------------
# run_step "human label" command [args...]
#   Runs a command, prints success/failure based on ITS OWN exit code
#   (the original scripts checked $? *after* an unrelated read prompt,
#   which meant the success message always printed no matter what the
#   flash command actually did — this fixes that) and logs the result.
# ---------------------------------------------------------------------
run_step() {
    local label="$1"; shift
    echo -e "${C_YELLOW}⚡ ${label}...${C_RESET}"
    "$@"
    local status=$?
    if [ $status -eq 0 ]; then
        ok "${label} completed successfully."
        trrt_log "OK   | $label | $*"
    else
        err "${label} failed (exit code $status)."
        warn "Check the USB cable/driver, that the device is in the right mode, and that the file matches your device."
        trrt_log "FAIL($status) | $label | $*"
    fi
    return $status
}

# flash_one "human label" "partition" [extra fastboot flags...]
#   The single most repeated pattern in the old scripts: ask for a
#   file, validate it, offer a checksum, confirm, then fastboot flash
#   it to a partition. One function now backs every "Flash X" menu
#   item instead of ~25 lines copy-pasted per option.
flash_one() {
    local label="$1" partition="$2"; shift 2
    local extra_flags=("$@")
    local path

    require_tool termux-fastboot || return 1
    prompt_path "$label" path
    require_file "$path" || return 1
    path="${path%\"}"; path="${path#\"}"
    path="${path%\'}"; path="${path#\'}"
    checksum_offer "$path"

    if ! confirm "Flash '$path' to the '$partition' partition now?"; then
        warn "Skipped flashing $label."
        return 1
    fi

    run_step "Flashing $label" termux-fastboot "${extra_flags[@]}" flash "$partition" "$path"
}

# offer_vbmeta — the recurring "want to also flash vbmeta.img now?"
# follow-up, factored out of every individual menu option.
offer_vbmeta() {
    local partition="${1:-vbmeta}"
    if confirm "Also flash ${partition}.img now (needed on many devices after flashing boot/recovery)?"; then
        flash_one "vbmeta ($partition)" "$partition" --disable-verity --disable-verification
    else
        info "Skipping ${partition}.img flash."
    fi
}

# go_home — return to the main flash menu. Uses exec so we replace
# the current process instead of nesting another interactive shell
# on top of it (the original scripts called "source ./flash.sh" or
# "./flash.sh" from inside return_to_menu, which on every "return to
# menu? y" press added one more shell/process to the stack for the
# rest of the session).
go_home() {
    exec "$TRRT_HOME/flash.sh"
}

goodbye() {
    ok "Thank you for using Termux Root Recovery Tool!"
    echo -e "${C_YELLOW}╭───────────────────────────────────────────────╮${C_RESET}"
    echo -e "${C_YELLOW}│ ${C_WHITE}Subscribe - Repair A2Z YouTube channel        ${C_YELLOW}│${C_RESET}"
    echo -e "${C_YELLOW}╰───────────────────────────────────────────────╯${C_RESET}"
    exit 0
}
