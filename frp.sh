#!/bin/bash
trap "echo -e '\033[0;31m Script execution aborted. \033[0m'; exit 1" INT

# ---------------------------------------------------------------------
# Ownership/authorization gate (added — the FRP reset logic below this
# point is unmodified from the original script).
# This feature is only appropriate on a device you own, or one you are
# explicitly authorized to service (e.g. as a repair technician with
# the owner's consent). It must not be used on a device that is lost,
# stolen, or otherwise not yours to unlock.
# ---------------------------------------------------------------------
clear
echo -e "\033[1;31m╔═══════════════════════════════════════════════╗"
echo -e "║            FRP Reset - Please Confirm          ║"
echo -e "╚═══════════════════════════════════════════════╝\033[0m"
echo -e "\033[1;97mThis tool resets Factory Reset Protection (FRP).\033[0m"
echo -e "\033[1;97mOnly use it on a device you own, or one you are\033[0m"
echo -e "\033[1;97mexplicitly authorized by the owner to service.\033[0m"
echo
read -r -p $'\033[1;33mDo you own this device or have the owner\'s explicit authorization? (y/n): \033[0m' frp_auth_choice
if [[ ! "$frp_auth_choice" =~ ^([Yy]|[Yy][Ee][Ss])$ ]]; then
    echo -e "\033[1;31m✗ Cancelled. This tool is only for devices you own or are authorized to service.\033[0m"
    exit 1
fi

# Function to prompt user before returning to main menu
return_to_menu() {
    echo -e "\033[1;33m╭───────────────────────────────────────────────╮\033[0m"
    echo -e "\033[1;33m│ \033[1;97m     Operation completed                      \033[1;33m│\033[0m"
    echo -e "\033[1;33m╰───────────────────────────────────────────────╯\033[0m"
    
    read -p $'\033[1;36mReturn to Frp Reset menu? (y/n): \033[0m' choice
    if [[ "$choice" == "y" || "$choice" == "Y" || "$choice" == "yes" || "$choice" == "YES" ]]; then
        source ./frp.sh
    else
    echo -e "\033[1;32m✓ Exiting program. Thank you for using Termux Root Recovery Tool! \033[0m"
	echo -e "\033[1;33m╭───────────────────────────────────────────────╮\033[0m"
    echo -e "\033[1;33m│ \033[1;97m     Subscribe - Repair A2Z YouTube channel   \033[1;33m│\033[0m"
	echo -e "\033[1;33m╰───────────────────────────────────────────────╯\033[0m"
        exit 0
    fi
}

# Function to prompt user before returning to main menu
go_to_main_menu() {
    echo -e "\033[1;33m╭───────────────────────────────────────────────╮\033[0m"
    echo -e "\033[1;33m│ \033[1;97m  Returning to main menu?                     \033[1;33m│\033[0m"
    echo -e "\033[1;33m╰───────────────────────────────────────────────╯\033[0m"
    
    read -p $'\033[1;36mGo to main menu? (y/n): \033[0m' choice
    if [[ "$choice" == "y" || "$choice" == "Y" || "$choice" == "yes" || "$choice" == "YES" ]]; then
        ./flash.sh
    else
        echo -e "\033[1;32m✓ Exiting program. Thank you for using Termux Root Recovery Tool! \033[0m"
	echo -e "\033[1;33m╭───────────────────────────────────────────────╮\033[0m"
    echo -e "\033[1;33m│ \033[1;97m     Subscribe - Repair A2Z YouTube channel   \033[1;33m│\033[0m"
	echo -e "\033[1;33m╰───────────────────────────────────────────────╯\033[0m"
        ./frp.sh
    fi
}

clear
echo -e "\033[1;36m
╔═══════════════════════════════════════════════╗
║\033[1;33m ★ \033[1;37mTermux Root Recovery Tool By Repair-A2Z\033[1;33m ★\033[1;36m   ║
╠═══════════════════════════════════════════════╣
║  \033[1;95m         Frp Reset Tool Utility    \033[1;36m          ║
╚═══════════════════════════════════════════════╝
\033[0m"

echo -e "\033[1;35m╭───────────────────────────────────────────────╮\033[0m"
echo -e "\033[1;35m│\033[1;33m          What would you like to do?           \033[1;35m│\033[0m"
echo -e "\033[1;35m╰───────────────────────────────────────────────╯\033[0m"

echo -e "\033[1;34m┌──────────────────────────────────────────────┐\033[0m"
echo -e "\033[1;34m│ \033[1;37m 1. \033[1;92m🔒 SPRD FRP Reset OLD \033[1;31m( Fastboot )       \033[1;34m│\033[0m"
echo -e "\033[1;34m│ \033[1;37m 2. \033[1;92m💲 Samsung FRP Reset \033[1;31m(ADB)               \033[1;34m│\033[0m"
echo -e "\033[1;34m│ \033[1;37m 3. \033[1;92m🔐 SPRD/MTK Frp Reset old \033[1;31m( ADB)         \033[1;34m│\033[0m"
echo -e "\033[1;34m│ \033[1;37m 4. \033[1;92m🔌 Check adb Devices                     \033[1;34m│\033[0m"
echo -e "\033[1;34m│ \033[1;37m 5. \033[1;92m🔌 Check Fastboot Devices                \033[1;34m│\033[0m"
echo -e "\033[1;34m│ \033[1;37m 6. \033[1;33m↩️  Return to Main Menu                   \033[1;34m│\033[0m"
echo -e "\033[1;34m└──────────────────────────────────────────────┘\033[0m"

echo -e "\033[1;33m╭───────────────────────────────────────────────╮\033[0m"
echo -e "\033[1;33m│ \033[1;97mEnter your choice or press any key to exit    \033[1;33m│\033[0m"
echo -e "\033[1;33m╰───────────────────────────────────────────────╯\033[0m"

read -p $'\033[1;36mChoice: \033[0m' flasher

case $flasher in
  "1")
    echo -e "\033[1;36m╭───────────────────────────────────────────────╮\033[0m"
    echo -e "\033[1;36m│\033[1;33m             SPRD Frp Reset OLD Device         \033[1;36m│\033[0m"
    echo -e "\033[1;36m╰───────────────────────────────────────────────╯\033[0m"
    
    echo -e "\033[1;92m► 🔐 Resetting FRP Via fastboot... \033[0m"
    termux-fastboot erase persist

    return_to_menu
  ;;

  "6")
    go_to_main_menu
  ;;

  "3")
    echo -e "\033[1;36m╭───────────────────────────────────────────────╮\033[0m"
    echo -e "\033[1;36m│\033[1;33m          Reset MTK/SPD FRP Via Adb            \033[1;36m│\033[0m"
    echo -e "\033[1;36m╰───────────────────────────────────────────────╯\033[0m"
    
    echo -e "\033[1;33m🔐 Resetting FRP Via ADB... \033[0m"
    termux-adb shell content insert --uri content://settings/secure --bind name:s:user_setup_complete --bind value:s:1


    return_to_menu
  ;;
"4")    
     echo -e "\033[1;36m╭───────────────────────────────────────────────╮\033[0m"
    echo -e "\033[1;36m│\033[1;33m              Search 🔍 Adb device             \033[1;36m│\033[0m"
    echo -e "\033[1;36m╰───────────────────────────────────────────────╯\033[0m"
    
    echo -e "\033[1;33m Searching adb device... \033[0m"
    termux-adb devices

        return_to_menu
  ;;
"5")    
     echo -e "\033[1;36m╭───────────────────────────────────────────────╮\033[0m"
    echo -e "\033[1;36m│\033[1;33m           Search 🔍  Fastboot Device          \033[1;36m│\033[0m"
    echo -e "\033[1;36m╰───────────────────────────────────────────────╯\033[0m"
    
    echo -e "\033[1;33m Searching Fastboot device... \033[0m"
    termux-fastboot devices

        return_to_menu
  ;;
"2")
    echo -e "\033[1;36m╭───────────────────────────────────────────────╮\033[0m"
    echo -e "\033[1;36m│\033[1;33m            Samsung FRP Reset Via adb          \033[1;36m│\033[0m"
    echo -e "\033[1;36m╰───────────────────────────────────────────────╯\033[0m"
    
    echo -e "\033[1;33m🔒 Rsetting Samsung FRP... \033[0m"
    termux-adb shell am start -n com.google.android.gsf.login/
    termux-adb shell am start -n com.google.android.gsf.login.LoginActivity
    termux-adb shell content insert --uri content://settings/secure --bind name:s:user_setup_complete --bind value:s:1


    return_to_menu
  ;;
  *)
    echo -e '\033[1;31m✗ Wrong key press please select correct. \033[0m';
    
read -p $'\033[1;36mDo You want to exit? (y/n): \033[0m' choice
    if [[ "$choice" == "y" || "$choice" == "Y" || "$choice" == "yes" || "$choice" == "YES" ]]; then
        echo -e "\033[1;32m✓ Exiting program. Thank you for using Termux Root Recovery Tool! \033[0m"
	echo -e "\033[1;33m╭───────────────────────────────────────────────╮\033[0m"
    echo -e "\033[1;33m│ \033[1;97m     Subscribe - Repair A2Z YouTube channel   \033[1;33m│\033[0m"
	echo -e "\033[1;33m╰───────────────────────────────────────────────╯\033[0m"
xdg-open https://youtube.com/@repaira2z
        exit 0
    else
        ./frp.sh
    fi
  ;;
esac

