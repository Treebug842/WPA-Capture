#!/bin/python3
# Written by Treebug842
# Must have airodump-ng installed!

import subprocess
import colorama
import time
import sys
from colorama import init, Fore
from subprocess import call

mktemp_output = subprocess.check_output('mktemp -d "${TMPDIR:-/tmp/}$(basename $0).XXXXXXXXXXXX"', shell=True)
mktemp_output_decoded = mktemp_output.decode()
parsing_dir = mktemp_output_decoded.strip()

def heading():
	call(['clear'])
	print(Fore.WHITE + '__        ______   _       ____            _')
	print('\ \      / /  _ \ / \     / ___|__ _ _ __ | |_ _   _ _ __ ___')
	print(" \ \ /\ / /| |_) / _ \   | |   / _' | '_ \| __| | | | '__/ _ \'")
	print('  \ V  V / |  __/ ___ \  | |__| (_| | |_) | |_| |_| | | |  __/')
	print('   \_/\_/  |_| /_/   \_\  \____\__,_| .__/ \__|\__,_|_|  \___|')
	print('                                    |_|')

def select_adapter():
	heading()
	print (f'{Fore.CYAN}------------------- {Fore.YELLOW}Choose a Network Adapter{Fore.CYAN} -------------------')
	print ('\n' + Fore.RED + 'WARNING:' + Fore.WHITE + ' Try and avoid using wlan0\n')
	global iwconfig_output
	iwconfig_output = subprocess.check_output('iwconfig 2>/dev/null', shell=True)
	iwconfig_output_decoded = iwconfig_output.decode()
	
	with open(f'{parsing_dir}/iwconfig.txt', 'a') as myfile:
		myfile.write(str(iwconfig_output_decoded))
	global interface_line
	
	with open(f'{parsing_dir}/iwconfig.txt') as search:
		global interfaces
		interfaces = []
		for line in search:
			line = line.rstrip()
			if 'IEEE' in line:
				interface_line = line
				interface_line_split = interface_line.split(" ")
				interfaces.insert(0, interface_line_split[0])
	interfaces = list(dict.fromkeys(interfaces))
	if not interfaces:
		print('No interfaces found!\n')
		time.sleep(2)
		sys.exit()
	device_num = 0
	for device in interfaces:
		print(f'{device_num}) {device}')
		device_num += 1
	global interface_selection_num
	try:
		interface_selection_num = int(input('\nSelect Network Interface: '))
	except ValueError:
		print('\nInvalid Option!')
		time.sleep(2)
		select_adapter()
	global interface
	try:
		interface = interfaces[interface_selection_num]
	except:
		print('\nInvalid Option!')
		time.sleep(2)
		select_adapter()
def scan_for_targets():	
	print(f'\n{Fore.CYAN}Press CRTL + C to stop scan{Fore.WHITE}')
	global interface_mode_decoded
	interface_mode_output = subprocess.check_output(f'iwconfig {interface} 2>/dev/null', shell=True)
	interface_mode_decoded = interface_mode_output.decode()
	
	with open(f'{parsing_dir}/interface_mode.txt', 'a') as myfile:
			myfile.write(str(interface_mode_decoded))
	with open(f'{parsing_dir}/interface_mode.txt') as search:
		global interface_mode
		for line in search:
			line = line.rstrip()
			if 'Mode:' in line:
				mode_parse1 = line.split('Mode:',1)[1]
				mode_parse2 = mode_parse1.split(' ')
				interface_mode = mode_parse2[0]
	global test_interface
	test_interface = 'wlan0'
	if interface_mode != 'Monitor':
		call(['ifconfig', interface, 'down'])
		call(['iwconfig', interface, 'mode', 'monitor'])
		call(['ifconfig', interface, 'up'])
	time.sleep(1)
	save_directory = parsing_dir + '/scan_results'	
	try:
		call(['airodump-ng', interface, '-o', 'csv', '-w', save_directory])
	except KeyboardInterrupt:
		print('Quitting...')
	global scan_file_location
	scan_file_location = parsing_dir + '/scan_results-01.csv'

def show_scan_results():
	heading()
	print (f'{Fore.CYAN}------------------- {Fore.YELLOW}Choose a Target Network{Fore.CYAN} -------------------{Fore.WHITE}\n')
	with open(scan_file_location) as search:
		global networks
		global channels
		global bssids
		bssids = []
		channels = []
		networks = []
		for line in search:
			if 'WPA2' in line:
				line_split = line.split(',')
				bssids.insert(0, line_split[0].strip())
				channels.insert(0, line_split[12].strip())
				networks.insert(0, line_split[13].strip())
	if not networks:
		print('No networks found!\n')
		time.sleep(2)
		sys.exit()
	name_num = 0
	for name in networks:
		print(f'{name_num}) {name}')
		name_num += 1
	global target_num
	try:
		target_num = int(input('\nSelect Target Network: '))
	except ValueError:
		print('\nInvalid Option!')
		time.sleep(2)
		show_scan_results()
	try:
		t = networks[target_num]
	except:
		print('\nInvalid Option')
		time.sleep(2)
		show_scan_results()
def start_capture():
	try:
		call(['airodump-ng', '-c', channels[target_num], '--bssid', bssids[target_num], '-w', networks[target_num], '--output-format', 'cap', interface ])
	except KeyboardInterrupt:
		call(['clear'])
		print(f'File saved as {networks[target_num]}-??.cap')

select_adapter()
scan_for_targets()
show_scan_results()
start_capture()






