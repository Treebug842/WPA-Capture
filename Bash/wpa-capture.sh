#!/bin/bash

current_dir=$(pwd)
parsing_dir=$(mktemp -d "${TMPDIR:-/tmp/}$(basename $0).XXXXXXXXXXXX")

RED="\e[0;31m"
WHITE="\e[0m"
BLUE="\e[1;36m"
YELLOW="\e[1;33m"

heading() {
clear
echo "__        ______   _       ____            _"
echo "\ \      / /  _ \ / \     / ___|__ _ _ __ | |_ _   _ _ __ ___"
echo " \ \ /\ / /| |_) / _ \   | |   / _' | '_ \| __| | | | '__/ _ \'"
echo "  \ V  V / |  __/ ___ \  | |__| (_| | |_) | |_| |_| | | |  __/"
echo "   \_/\_/  |_| /_/   \_\  \____\__,_| .__/ \__|\__,_|_|  \___|"
echo "                                    |_|"
}

select_adapter() {
heading
echo -e "${BLUE}-------------- ${YELLOW}Choose a Network Interface to Use${BLUE} --------------${WHITE}\n"
echo -e "${RED}WARNING: ${WHITE}Try and avoid using wlan0\n"
iwconfig > $parsing_dir/iwconfig.txt 2> /dev/null
cat $parsing_dir/iwconfig.txt | grep "IEEE" | cut -d' ' -f1 > $parsing_dir/network-adapters.txt
mapfile -t listed_interface < $parsing_dir/network-adapters.txt
number_of_adapters=-1

for adapter_num in {0..50}; do
if [ ! -z ${listed_interface[adapter_num]} ]; then
echo "$adapter_num) ${listed_interface[adapter_num]}" 
let number_of_adapters++
fi
done
echo ""
read -p "Select Network Interface: " interface_num

if [ -z $interface_num ]; then
echo -e "\nInvalid Option!"
sleep 2
select_adapter
fi

if [ $interface_num -ge 0 ] && [ $interface_num -le $number_of_adapters ]
then
interface=${listed_interface[interface_num]}
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
echo -e "${BLUE}------------------- ${YELLOW}Choose a target Network${BLUE} -------------------${WHITE}\n"
cat $parsing_dir/scan-results-01.csv | grep "WPA" | cut -d',' -f14 > $parsing_dir/networks.txt
mapfile -t listed_network < $parsing_dir/networks.txt
number_of_networks=-1
for network_num in {0..100}; do
if [ ! -z ${listed_network[network_num]} ]; then
echo "${network_num}) ${listed_network[network_num]}"
let number_of_networks++; fi
done
echo ""
read -p "Select Network: " chosen_network

if [ -z $chosen_network ]; then
echo -e "\nInvalid Option!"
sleep 2
show_scan_results
fi

if [ $chosen_network -ge 0 ] && [ $chosen_network -le $number_of_networks ]; then
network=$(echo "${listed_network[chosen_network]}" | tr -d ' ')
bssid=$(cat $parsing_dir/scan-results-01.csv | grep "$network" | cut -d',' -f1 | xargs)
channel=$(cat $parsing_dir/scan-results-01.csv | grep "$network" | cut -d',' -f4 | xargs)
else
echo -e "\nInvalid Option!"
sleep 2
show_scan_results
fi
}

start_capture() {
airodump-ng -c $channel --bssid $bssid -w $current_dir/$network --output-format cap $interface
clear
echo "File saved as ${network}"
}

heading
select_adapter
scan_for_targets
show_scan_results
start_capture
