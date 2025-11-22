#!/bin/bash

#Proton VPN connection helper


case $1 in
	-c)

		echo "Testing connection..."
		echo ""

		if ping -c2 www.google.com
		then 
			echo "Logging and connection on Proton..."
			echo ""
			protonvpn-cli login [you proton username];protonvpn-cli connect
		else	
			echo "Error!"
			nmcli connection delete pvpn-ipv6leak-protection
			echo ""
			echo "Reboot your system to fix network connection.."
			sudo init 6
		fi ;;
	-d)
		protonvpn-cli disconnect ;;
	*)
		cat << EOF
		
	This script may help you a quickly test, connect and disconnect Proton VPN on Linux hosts.

		Options:

		-c	Use to connect Proton VPN 
		-d 	Use to disconnect Proton VPN
EOF
esac
