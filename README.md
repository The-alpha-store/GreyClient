# Termux Root Recovery Tool

A Termux-based menu toolkit for flashing, recovering, and troubleshooting
Android devices over ADB/Fastboot using `termux-adb` / `termux-fastboot`
(via Termux:API + USB OTG). Originally by Repair A2Z; this is an upgraded
build — see `CHANGELOG.md` for the full list of changes.

## Setup

```bash
pkg update && pkg upgrade
pkg install termux-api
bash installadb.sh      # installs termux-adb / termux-fastboot
bash start.sh           # launch
```

Grant the Termux:API USB permission prompt when it appears, and make sure
your OTG cable/adapter supports data (not charge-only).

## What's in here

| Script | Purpose |
|---|---|
| `start.sh` | Splash screen + launcher |
| `fixall.sh` | Checks USB/ADB/Fastboot are ready before launching the main menu |
| `flash.sh` | Main menu — flash recovery/boot/vbmeta/etc, reboot, sideload |
| `flashAB.sh` | A/B (dual-slot) partition flashing |
| `gsi-flash.sh` | GSI (Generic System Image) flashing on dynamic-partition devices |
| `flash-stock-rom.sh` | Wraps a vendor `flash_all*.sh` stock ROM package |
| `usbfix.sh` | USB/OTG/ADB/Fastboot troubleshooting |
| `installadb.sh` | Installs/repairs `termux-adb` and `termux-fastboot` |
| `mtk-detect.sh` | Read-only MediaTek BROM/Preloader/DA mode identifier |
| `frp.sh` | FRP reset utilities (see disclaimer below) |
| `lib/common.sh` | Shared UI/safety/logging helpers used by every script above |

## Logging

Every flash/erase/reset action is appended to `logs/trrt-YYYYMMDD.log`
(human-readable, local only — nothing is sent anywhere) so you can check
what ran and whether it reported success after the fact.

## Safety notes

- Flashing the wrong image to the wrong partition, or interrupting a flash,
  **can make your device unbootable.** Always confirm the file matches your
  exact device/firmware before flashing.
- Destructive operations (erase, wipe-super, factory reset, delete
  partition) now ask for explicit confirmation.
- The tool can offer to show a file's SHA256 checksum before flashing it —
  cross-check that against the number published by your ROM/firmware
  source.
- `mtk-detect.sh` is read-only: it identifies a connected MediaTek device's
  USB mode and sends nothing to it. It's a point-in-time snapshot, not
  continuous monitoring — Termux has no event-driven USB hotplug access
  the way a rooted desktop Linux host with udev/libusb does, so you may
  need to re-run it right as you plug in/power on the device to catch a
  brief BROM/Preloader window.

### FRP reset (`frp.sh`)

Factory Reset Protection exists to stop a phone from being used after a
factory reset unless the original Google/Samsung account signs back in.
**Only use this on a device you own, or one you are explicitly authorized
by the owner to service** (for example, as a repair technician with the
owner's consent and proof of ownership). The script now asks you to
confirm this before it runs anything.

## Credits

- Developed By: Repair A2Z — [YouTube](https://youtube.com/@repaira2z) · [Instagram](https://www.instagram.com/dineshpatel43642) · [Telegram](https://t.me/RepairA2Z)
