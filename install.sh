#!/bin/bash
IPConfigured=0
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
ls /sys/class/net
read -p "Choose a LAN interface(local network, can be used as wan interface aswell): " lan_interface
read -p "Choose a WAN interface(Internet network): " wan_interface
echo "lan_interface=$lan_interface" >> /etc/captiveportal/config
echo "wan_interface=$wan_interface" >> /etc/captiveportal/config
# Split the IP address into an array using dot as the delimiter
IFS='.' read -r -a ip_array <<< "$portalip"
if [[ "$ip_array[0]" == "10" ]]
then
IPConfigured=1
echo "localnet=10.0.0.0/8" >> /etc/captiveportal/config
fi
if [[ "$ip_array[0].$ip_array[1]" == "192.168" ]]
then
echo "localnet=192.168.$ip_array[2].0/24" >> /etc/captiveportal/config
IPConfigured=3
fi
if [[ "$ip_array[0]" == "172" ]]
then
if [[ $ip_array[1] -gt 15 && $ip_array[1] -lt 32 ]]
then
echo "localnet=172.$ip_array[1].0.0/16" >> /etc/captiveportal/config
IPConfigured=2
fi
fi
if [[ "$IPConfigured" == "0" ]]
then
echo "Could not detect your local IP class."
echo "Please make sure you enter the local ip address for your portal IP not your internet ip.."
exit 1
fi
apt install ncat bind9 dnsmasq
cp /etc/dnsmasq.conf /etc/captiveportal/dnsmasq.conf.off
echo "port=0" > /etc/dnsmasq.conf
echo "dhcp-option=3,$portalip" >> /etc/dnsmasq.conf
echo "dhcp-option=6,$portalip" >> /etc/dnsmasq.conf
case $IPConfigured in
 1)
 dhcpRange=$ip_array[0].0.0.1,$ip_array[0].255.255.254
 ;;
 2)
 dhcpRange=$ip_array[0].$ip_array[1].0.1,$ip_array[0].$ip_array[1].255.254
 ;;
 3)
 dhcpRange=$ip_array[0].$ip_array[1].$ip_array[2].1,$ip_array[0].$ip_array[1].$ip_array[2].254
 ;;
esac
echo "dhcp-range=$dhcpRange,7d" >> /etc/dnsmasq.conf
chmod +x /usr/locall/bin/gameserver
chmod +x /usr/locall/bin/mac-add
chmod +x /usr/locall/bin/captive-portal.sh
chmod +x /usr/locall/bin/natinstall
chmod +x /usr/locall/bin/cpuser
natinstall
gameserver
cp captive-portal.service /etc/systemd/system/
systemctl enable captive-portal
systemctl enable named
systemctl enable dnsmasq
systemctl restart named
echo "The next step is to disable DHCP Server on the Internet router and enable mac address filter to only allow this server to get internet."
echo "Once done type the word \"DONE\" in uppercase lettes anything else will disable dhcp on this server"
read ready
if [[ "$ready" != *"DONE"* ]]
then
systemctl disable dnsmasq
echo "DNSMasq temporary disabled"
exit 1
fi
systemctl restart dnsmasq
systemctl restart captive-portal
