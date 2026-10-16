#!/bin/bash
# =====================================================================
# lib/common.sh — shared helpers for Termux Root Recovery Tool
#
# This file is meant to be *sourced*, never executed directly:
#     source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
#
# Centralizes colors, adaptive box/menu drawing, confirmations,
# file/tool checks, checksum caching, a spinner for long-running
# commands, logging, and the flash/run wrapper that reports success
# or failure based on the command's real exit code.
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
TRRT_CHECKSUM_CACHE="$TRRT_LOG_DIR/.checksum_cache"

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
# Terminal width — adaptive layout instead of hand-padded fixed-width
# boxes (the original scripts hardcoded ~49-column boxes that visibly
# broke on narrower phone terminals / larger fonts). Prefers the
# $COLUMNS shell variable (no subprocess) and only forks `tput` when
# that isn't set. Clamped to a readable range.
# ---------------------------------------------------------------------
term_width() {
    local w="${COLUMNS:-}"
    if [ -z "$w" ]; then
        w=$(tput cols 2>/dev/null)
    fi
    [ -z "$w" ] && w=50
    (( w > 72 )) && w=72
    (( w < 40 )) && w=40
    echo "$w"
}

# hr [width] — a horizontal rule. Pure bash (printf + parameter
# expansion), no `tr`/subshell pipeline, so redrawing a menu doesn't
# fork extra processes on every frame.
hr() {
    local width="${1:-$(term_width)}" line
    printf -v line '%*s' "$width" ''
    echo -e "${C_CYAN}${line// /─}${C_RESET}"
}

# ---------------------------------------------------------------------
# Menu chrome — replaces the old hand-padded ┌─┐/│ │/└─┘ boxes (every
# label change meant re-counting spaces to keep the right border
# aligned, and emoji/variable-width labels broke it anyway). Width is
# computed once per draw and reused for both rules instead of calling
# `tput` twice.
# ---------------------------------------------------------------------
menu_start() {
    local subtitle="$1"
    clear
    _MENU_WIDTH="$(term_width)"
    hr "$_MENU_WIDTH"
    echo -e "  ${C_YELLOW}★ ${C_WHITE}Termux Root Recovery Tool${C_RESET}"
    [ -n "$subtitle" ] && echo -e "  ${C_MAGENTA}${subtitle}${C_RESET}"
    hr "$_MENU_WIDTH"
}

# menu_item "num" "icon" "label" ["color"] — one consistently-indented
# row; no manual padding required, and multi-digit numbers (1 vs 10)
# line up automatically via %2s.
menu_item() {
    local num="$1" icon="$2" label="$3" color="${4:-$C_GREEN}"
    printf "  %b%2s.%b %s  %b%s%b\n" "$C_WHITE" "$num" "$C_RESET" "$icon" "$color" "$label" "$C_RESET"
}

menu_end() {
    hr "${_MENU_WIDTH:-$(term_width)}"
}

# Backwards-compatible alias (older drafts of this lib used box_header).
box_header() { menu_start "$1"; }

# section "Operation title" — lighter sub-header used inside a menu
# action (e.g. "Recovery Flash Operation"), one rule instead of a
# full box, so the terminal isn't dominated by chrome during a
# multi-step flash.
section() {
    local title="$1"
    hr
    echo -e "${C_YELLOW}▸ ${title}${C_RESET}"
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
# spinner_wait <pid> <message> — shows a lightweight spinner while a
# backgrounded command (started by the caller) runs, so operations
# like a large checksum don't look frozen. No-op (just waits) when
# stdout isn't a real terminal, so logs/CI output stay clean.
# ---------------------------------------------------------------------
spinner_wait() {
    local pid="$1" msg="$2"
    if [ -t 1 ]; then
        local frames='|/-\' i=0
        while kill -0 "$pid" 2>/dev/null; do
            i=$(( (i + 1) % 4 ))
            printf "\r${C_YELLOW}%s %s...${C_RESET}" "${frames:$i:1}" "$msg"
            sleep 0.12
        done
        printf "\r%*s\r" "$(( ${#msg} + 12 ))" ""
    fi
    wait "$pid" 2>/dev/null
}

# ---------------------------------------------------------------------
# Requirement / safety checks
# ---------------------------------------------------------------------
declare -A _TRRT_TOOL_CACHE

# require_tool caches its command -v lookups for the life of the
# current script/menu session, so repeatedly flashing several images
# in a row doesn't re-fork `command -v` for the same tool every time.
require_tool() {
    local tool="$1"
    if [ -z "${_TRRT_TOOL_CACHE[$tool]+set}" ]; then
        if command -v "$tool" >/dev/null 2>&1; then
            _TRRT_TOOL_CACHE[$tool]=1
        else
            _TRRT_TOOL_CACHE[$tool]=0
        fi
    fi
    if [ "${_TRRT_TOOL_CACHE[$tool]}" = "1" ]; then
        return 0
    fi
    err "Required tool '$tool' was not found."
    warn "Run option 'Fix USB / ADB / Fastboot' from the main menu, or 'bash installadb.sh', then try again."
    return 1
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
# trimming surrounding quotes so a copy/pasted or drag-and-dropped
# path works either way.
prompt_path() {
    local label="$1" __resultvar="$2" path
    info "Please enter the $label file location."
    read -e -r -p $'\033[1;97mPath: \033[0m' path
    path="${path%\"}"; path="${path#\"}"
    path="${path%\'}"; path="${path#\'}"
    printf -v "$__resultvar" '%s' "$path"
}

# _file_stat_key "/path" — "<size>|<mtime>", used as a cheap content
# fingerprint for the checksum cache below. Tries GNU stat then BSD
# stat so this also behaves if ever run outside Termux's toolchain.
_file_stat_key() {
    local path="$1" size mtime
    size=$(stat -c%s "$path" 2>/dev/null || stat -f%z "$path" 2>/dev/null)
    mtime=$(stat -c%Y "$path" 2>/dev/null || stat -f%m "$path" 2>/dev/null)
    echo "${size}|${mtime}"
}

# checksum_offer "/path/to/file" — optional sha256 display so the
# user can cross-check against the ROM/firmware source before
# trusting a multi-gigabyte file to a flash command. Results are
# cached by path+size+mtime (logs/.checksum_cache) so re-flashing the
# same unchanged file in the same session doesn't rehash it, and runs
# with a spinner so a large file doesn't look like a hang.
checksum_offer() {
    local path="$1"
    confirm "Show SHA256 checksum of this file before continuing?" || return 0
    command -v sha256sum >/dev/null 2>&1 || { warn "sha256sum is not available on this system; skipping."; return 0; }

    local fkey sum="" cpath csum
    fkey="$(_file_stat_key "$path")"

    if [ -f "$TRRT_CHECKSUM_CACHE" ]; then
        while IFS='|' read -r cpath csize cmtime csum; do
            if [ "$cpath" = "$path" ] && [ "${csize}|${cmtime}" = "$fkey" ]; then
                sum="$csum"
                break
            fi
        done < "$TRRT_CHECKSUM_CACHE"
    fi

    if [ -n "$sum" ]; then
        info "Using cached checksum (file unchanged since it was last hashed):"
        echo -e "${C_GREEN}${sum}${C_RESET}  $path"
        return 0
    fi

    local tmp; tmp="$(mktemp)"
    ( sha256sum "$path" > "$tmp" 2>/dev/null ) &
    spinner_wait "$!" "Computing checksum (large files can take a while)"
    sum="$(awk '{print $1}' "$tmp" 2>/dev/null)"
    rm -f "$tmp"

    if [ -n "$sum" ]; then
        echo -e "${C_GREEN}${sum}${C_RESET}  $path"
        echo "${path}|${fkey}|${sum}" >> "$TRRT_CHECKSUM_CACHE" 2>/dev/null
    else
        warn "Checksum computation failed or was interrupted."
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
