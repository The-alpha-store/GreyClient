#!/data/data/com.termux/files/usr/bin/bash
# =====================================================================
# installadb.sh — Installs/repairs termux-adb & termux-fastboot.
# Idempotent: safe to run even when everything is already installed.
# =====================================================================
set -u

GREEN="\033[1;92m"; YELLOW="\033[1;33m"; RED="\033[1;31m"; RESET="\033[0m"
info() { echo -e "${YELLOW}$*${RESET}"; }
ok()   { echo -e "${GREEN}$*${RESET}"; }
err()  { echo -e "${RED}$*${RESET}"; }

# Only remove packages that are actually installed — the original
# script called `pkg rm` unconditionally, which prints a scary error
# on a clean install where nothing is there to remove yet.
for pkg_name in termux-adb android-tools; do
    if pkg list-installed 2>/dev/null | grep -q "^${pkg_name}/"; then
        info "Removing existing ${pkg_name}..."
        yes | pkg uninstall "$pkg_name" >/dev/null 2>&1
    fi
done

upgradable_packages=$(apt list --upgradable 2>/dev/null | wc -l)
if [ "$upgradable_packages" -gt 1 ]; then
    info "Updating package lists..."
    yes | apt update && yes | apt upgrade
fi

if ! command -v adb >/dev/null 2>&1 || ! command -v fastboot >/dev/null 2>&1; then
    info "Installing ADB and Fastboot..."
    curl -fsSL https://raw.githubusercontent.com/nohajc/termux-adb/master/install.sh | bash
    installer_status=$?
    if [ $installer_status -ne 0 ]; then
        err "The termux-adb installer script failed (network issue or GitHub unreachable)."
        err "Check your connection and try again, or install 'android-tools' from pkg as a fallback."
        exit 1
    fi

    # Only (re)create the convenience symlinks if the underlying
    # binaries actually exist and the links aren't already correct —
    # avoids "ln: File exists" noise on a re-run.
    if [ -x "$PREFIX/bin/termux-fastboot" ] && [ ! -e "$PREFIX/bin/fastboot" ]; then
        ln -s "$PREFIX/bin/termux-fastboot" "$PREFIX/bin/fastboot"
    fi
    if [ -x "$PREFIX/bin/termux-adb" ] && [ ! -e "$PREFIX/bin/adb" ]; then
        ln -s "$PREFIX/bin/termux-adb" "$PREFIX/bin/adb"
    fi
fi

if command -v termux-adb >/dev/null 2>&1 && command -v termux-fastboot >/dev/null 2>&1; then
    ok "✓ ADB and Fastboot are ready (termux-adb / termux-fastboot)."
else
    err "✗ ADB/Fastboot still not found after install. Try: pkg install android-tools"
    exit 1
fi
