# Changelog — Upgrade from original Termux-Root-Recovery-Tool

## Bug fixes
- **Success/failure was reported wrong.** Every "✓ Operation completed
  successfully!" message in the original scripts checked `$?` *after* an
  unrelated `read` prompt for the optional vbmeta/second-slot flash, not
  after the actual `termux-fastboot`/`termux-adb` command. That meant the
  success message printed almost unconditionally, even when the flash had
  failed. Fixed via `run_step`/`flash_one`, which capture the real exit
  code immediately after the command runs.
- **Typo caused the wrong partition to be flashed.** In `flashAB.sh`,
  option 10's "also flash recovery_b" step ran
  `termux-fastboot flash recovert_b $romname` — a typo'd partition name
  that would have failed outright rather than flashing slot B. Fixed to
  `recovery_b`.
- **Unbounded recursive `source`.** `return_to_menu`/`go_to_main_menu` in
  every script called `source ./script.sh` or `./script.sh` on "yes",
  which stacked another interactive shell/process on top of the current
  one every single time you answered "return to menu? y" — for a long
  session this grows the process/shell stack with no bound. Replaced with
  a `while true; do ... done` loop per script, and `exec` (process
  replacement, not stacking) when actually switching to a different
  script.
- **`installadb.sh` always tried to remove packages that might not be
  installed**, printing a scary-looking error on a clean install. It now
  checks `pkg list-installed` first and only removes what's actually
  there, and validates the install afterward instead of assuming success.
- **`eval "termux-$user_command"`** in the manual-command option force-
  prefixed `termux-` and used `eval` for no real benefit. Replaced with a
  plain `bash -c "$user_command"` that takes the full command as typed
  and logs it.

## Safety additions
- Confirmation prompts before destructive operations: erasing `system`,
  `fastboot -w` full reset, deleting a logical partition, wiping super.
- Optional SHA256 checksum display before any flash, so you can cross-
  check a file against the hash published by your ROM/firmware source.
- Empty-file detection — the old `[ -f "$path" ]` check accepted a
  0-byte file (a common result of an interrupted download) as valid.
- `fixall.sh`'s device-detection loop now stops after 10 attempts (or
  whenever you say no to "try again?") instead of looping forever with
  no way out besides Ctrl+C.
- `frp.sh` now asks you to confirm you own the device or are authorized
  by the owner to service it before anything else runs. The FRP reset
  logic itself is unchanged.

## New
- `lib/common.sh` — shared colors, box-drawing, confirmation, file/tool
  validation, checksum, and logging helpers used by every script, instead
  of ~25 lines of copy-pasted boilerplate per menu option.
- `mtk-detect.sh` — read-only MediaTek BROM/Preloader/Download-Agent mode
  identifier (VID `0x0E8D`, PIDs `0003`/`2000`/`2001`), wired into the
  main menu. Point-in-time via `lsusb`, not continuous monitoring (Termux
  has no udev/libusb hotplug access).
- `logs/trrt-YYYYMMDD.log` — every flash/erase/reset/manual-command action
  is now logged locally with a timestamp and success/failure.
- Consistent error messages that explain the likely cause (cable, driver,
  wrong mode, wrong file) instead of just printing the raw failure.

## Cleanup
- Collapsed the repeated "ask for a file → validate → flash → optionally
  flash vbmeta/slot B" pattern (appeared ~25 times across the original
  scripts) into `flash_one` / `offer_vbmeta` / `flash_slot_pair` helpers.
- Fixed assorted typos in menu labels (Lunch→Launch, Opration→Operation,
  Exicut→Execute, Rsetting→Resetting, commond→command).
- `flash-stock-rom.sh` now runs the vendor's `flash_all*.sh` with `bash`
  instead of `source`, so a stray `exit` in a vendor script can't kill
  the wrapping session, and asks for confirmation before each run.

## Deliberately left unchanged
- `frp.sh`'s actual FRP-reset commands (fastboot/adb calls) — only the
  ownership/authorization confirmation gate at the top was added.

## UI/UX and performance pass
- Replaced hand-padded fixed-width `┌─┐/│ │/└─┘` boxes (hardcoded to
  ~49 columns) with an adaptive `menu_start`/`menu_item`/`menu_end`
  renderer that sizes itself to the actual terminal width (`$COLUMNS`,
  falling back to `tput cols`), clamped to a readable 40–72 range. Menu
  labels no longer need manual space-counting to stay aligned, and the
  layout no longer breaks on narrower phone terminals or larger fonts.
- Added `spinner_wait` — a lightweight spinner for long-running
  background commands (currently used by checksum calculation) so a
  multi-gigabyte file being hashed doesn't look like a hang.
- Added checksum caching (`logs/.checksum_cache`, keyed by path + size
  + mtime): re-checking the same unchanged file in the same session
  reuses the previous SHA256 instead of rehashing it.
- `require_tool` now caches its `command -v` lookups per script
  session, so flashing several images in a row no longer re-forks the
  same lookup each time.
- `hr`/menu drawing now uses pure bash (`printf` + parameter
  expansion) instead of a `tr`/pipe, and computes terminal width once
  per screen draw instead of twice.
- `start.sh`: added `TRRT_FAST=1` (or simply running non-interactively)
  to skip the animated splash entirely; trimmed the remaining splash
  timings (~3s → ~1.5s) and animation frame count.
- `fixall.sh`: removed a purely cosmetic 1s sleep before launching the
  main menu; replaced an `echo | grep` pipeline with a direct here-
  string to shave one forked process per retry loop.
