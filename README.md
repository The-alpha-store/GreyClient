<img align="right" src="TRRT1.jpg" width="350" alt="GreyClient Termux Root Recovery Tool">

# GreyClient | Termux Root Recovery Tool

A Termux-based menu toolkit for flashing Custom Recovery, `boot.img`, `vbmeta.img`, `init_boot.img`, GSI ROMs, and troubleshooting Android devices over ADB/Fastboot. 

> ⚠️ **Requirement:** This tool is designed for **bootloader unlocked devices only**.

Originally developed by Repair A2Z, this is an upgraded and enhanced build maintained by The Alpha Store. See `CHANGELOG.md` for the full list of improvements.

---

## ✨ Tool Features

1. **No Need to Type Commands 🚫⌨️**: All commands are presented in an interactive menu. Just enter the option number and paste the file location.
2. **Automatic Pre-Flight Checks ✅**: Automatically detects USB connection and required packages before the tool starts to ensure a stable connection.
3. **Flash IMG Files 📀**: Easily flash `boot.img`, `init_boot.img`, `super_empty.img`, `vbmeta.img`, and `magisk_patched.img` without typing complex commands.
4. **One-Click Reboot 🔃**: Quickly reboot your device to Fastboot, Recovery, FastbootD, or System.
5. **Device Connection Checker 🔌**: Verify connected ADB and Fastboot devices directly from your mobile.
6. **Flash ZIP Files 🗃️**: Flash any ZIP file (Magisk, Custom ROMs, Kernel Zips) directly in Sideload mode.
7. **A/B Partition Support 🆎**: Dedicated tools to flash root, recovery, boot, and vbmeta on A/B (dual-slot) partition devices.
8. **GSI ROM Flashing 💿**: Easily flash Generic System Images (GSI) on dynamic partition devices.
9. **FRP Remove 🔐**: Bypass FRP lock on select older devices (see safety disclaimer below).
10. **Firmware Content Extractor 📦**: Download specific images (`boot.img`, `init_boot.img`, `vendor_boot.img`, `system.img`, `super.img`) without downloading the entire flash file.
11. **USB Fix Tool 🔧**: Built-in troubleshooting to fix connection issues if your device is not being detected.
12. **Automatic Environment Fix 🛠️**: Option 1 in the start menu automatically fixes/installs `termux-api`, `termux-adb`, and `termux-usb` dependencies.

---

## 🛠️ Setup & Installation Guide

Follow these step-by-step instructions to properly install and configure the tool.

### Step 1: Install Termux & Termux:API
Choose the correct APK based on your Android version:

- **Android 13 and Lower:**  
  Install [Termux](https://f-droid.org/repo/com.termux_1022.apk) & [Termux:API](https://f-droid.org/repo/com.termux.api_1001.apk)
- **Android 14 and Newer:**  
  Install [Termux-Monet](https://github.com/Termux-Monet/termux-monet/releases/download/v0.119.0-b1-36/termux-app_v0.119.0-b1-36+apt-android-7-github-debug_universal.apk) & [Termux-Monet-API](https://github.com/Termux-Monet/termux-api/releases/download/v0.50.1-5/termux-api_v0.50.1-5+github-debug.apk)

### Step 2: Initial Termux Setup
Open Termux and run the following commands to grant storage permissions and update packages:
```bash
termux-setup-storage
yes | pkg update && pkg upgrade
pkg install termux-api
yes | pkg install git
```

### Step 3: Clone the Repository
Download the GreyClient repository and navigate into its directory:
```bash
git clone https://github.com/The-alpha-store/GreyClient.git
cd GreyClient
```

### Step 4: Grant Execution Permissions
Make all shell scripts in the directory executable:
```bash
chmod -R +x .
```

### Step 5: Install ADB & Fastboot Tools
Run the included setup script to install or repair `termux-adb` and `termux-fastboot`:
```bash
bash installadb.sh
```

### Step 6: Launch the Tool
Start the main interface:
```bash
bash start.sh
# or ./start.sh
```

> **⚠️ Important Hardware Note:**  
> When prompted, grant the **Termux:API USB permission**. Ensure your OTG cable or adapter supports **data transfer** (not charge-only), otherwise the tool will not detect your device.

---

## 📂 Included Scripts Reference

| Script | Purpose |
|---|---|
| `start.sh` | Splash screen + main launcher |
| `fixall.sh` | Checks if USB/ADB/Fastboot are ready before launching |
| `flash.sh` | Main menu: flash recovery/boot/vbmeta, reboot, sideload |
| `flashAB.sh` | A/B (dual-slot) partition flashing |
| `gsi-flash.sh` | GSI flashing on dynamic-partition devices |
| `flash-stock-rom.sh` | Wraps a vendor `flash_all*.sh` stock ROM package |
| `usbfix.sh` | USB/OTG/ADB/Fastboot troubleshooting |
| `installadb.sh` | Installs/repairs `termux-adb` and `termux-fastboot` |
| `mtk-detect.sh` | Read-only MediaTek BROM/Preloader/DA mode identifier |
| `frp.sh` | FRP reset utilities |
| `lib/common.sh` | Shared UI/safety/logging helpers |

---

## 📦 For Flashing Fastboot ROMs

To use the **Fastboot ROM Flash** option, follow these steps:
1. Rename your extracted fastboot ROM folder to exactly: `stock-rom`
2. Copy the `stock-rom` folder to the **Download** folder in your device's internal storage (`/sdcard/Download/stock-rom`).
3. Launch the tool and select the Fastboot ROM Flash option.

---

## 📝 Logging

Every flash, erase, or reset action is appended to `logs/trrt-YYYYMMDD.log`.  
These logs are **human-readable and stored locally only** (nothing is sent anywhere), allowing you to review what ran and whether it reported success after the fact.

---

## ⚠️ Safety Notes

- **Bricking Risk:** Flashing the wrong image to the wrong partition, or interrupting a flash, **can make your device unbootable.** Always confirm the file matches your exact device model and firmware before flashing.
- **Explicit Confirmation:** Destructive operations (erase, wipe-super, factory reset, delete partition) require explicit user confirmation.
- **Checksum Verification:** The tool can show a file's SHA256 checksum before flashing. Always cross-check this against the checksum published by your ROM/firmware source.
- **MediaTek Detection:** `mtk-detect.sh` is strictly read-only. It identifies a connected MediaTek device's USB mode. Because Termux lacks event-driven USB hotplug access, you may need to re-run it right as you plug in the device to catch a brief BROM/Preloader window.

### FRP Reset (`frp.sh`) Disclaimer
Factory Reset Protection (FRP) exists to prevent a phone from being used after a factory reset unless the original account signs back in.  
**🚨 ONLY use this on a device you own, or one you are explicitly authorized by the owner to service.** The script will ask you to confirm this before executing any actions.

---

## 🏆 Credits & Acknowledgments

- **Original Developer:** Repair A2Z  
  [YouTube](https://youtube.com/@repaira2z) · [YouTube Mix](https://youtube.com/@repaira2zmix) · [Instagram](https://www.instagram.com/dineshpatel43642) · [Telegram](https://t.me/RepairA2Z)
- **Termux-ADB/Fastboot:** [nohajc](https://github.com/nohajc) for the foundational [termux-adb](https://github.com/nohajc/termux-adb) project.
- **UI Enhancement:** [Mahesh Verma](https://github.com/MaheshTechnicals) for UI improvements in the tool.
- **Upgraded & Maintained By:** The Alpha Store (GreyClient)