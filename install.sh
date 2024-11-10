#!/bin/bash
apt install ncat bind9 dnsmasq net-tools
cp -rv usr/ /
if [[ -f "/etc/captiveportal/config" ]]
then
cp /etc/captiveportal/config /etc/captiveportal/config.old
source /etc/captiveportal/config.old
fi
cp -rv etc/ /
cp bind-db /etc/bind/db.catchall
if [[ "$portalip" == "" ]]
then
echo "Please enter an ip address that will serve Captive portal DNS and web requests"
hostname -I
read -p "Captive Portal local network IP: " portalip
fi
echo "portalip=$portalip" > /etc/captiveportal/config
echo "leasetime=30d" > /etc/captiveportal/config
echo "* IN A $portalip" >> /etc/bind/db.catchall
echo "features=\"renat iptables dnsmasq-dhcp\"" >> /etc/captiveportal/config 
ifconfig
read -p "Choose a LAN interface(local network, can be used as wan interface aswell): " lan_interface
read -p "Choose a WAN interface(Internet network): " wan_interface
echo "lan_interface=$lan_interface" >> /etc/captiveportal/config
echo "wan_interface=$wan_interface" >> /etc/captiveportal/config
