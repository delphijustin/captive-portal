#!/bin/bash
IPConfigured=0
cp -rv usr/ /
apt install -y bind9
cp -rv etc/ /
cp bind-db /etc/bind/db.catchall
echo "Please enter an ip address that will serve Captive portal DNS and web requests"
hostname -I
read -p "Captive Portal local network IP: " portalip
ips=$(hostname -I)
echo " $ips " | grep -q " $portalip "
if [[ $? -gt 0 ]]
then
echo "Invalid ip or not assigned to this server"
exit 1
fi
echo "portalip=$portalip" > /etc/captiveportal/config
echo "leasetime=30d" >> /etc/captiveportal/config
echo "* IN A $portalip" >> /etc/bind/db.catchall
echo "features=\"renat iptables dnsmasq-dhcp\"" >> /etc/captiveportal/config
ls /sys/class/net
read -p "Choose a LAN interface(local network, can be used as wan interface aswell): " lan_interface
if [[ ! -d /sys/class/net/$lan_interface/ ]]
then
echo "LAN_INTERFACE: Doesn't exist"
exit 1
else
if [[ "$lan_interface" == "" ]]
then
exit 1
fi
fi
read -p "Choose a WAN interface(Internet network): " wan_interface
if [[ ! -d /sys/class/net/$wan_interface/ ]]
then
echo "WAN_INTERFACE: Doesn't exist"
exit 1
else
if [[ "$lan_interface" == "" ]]
then
exit 1
fi
fi
echo "lan_interface=$lan_interface" >> /etc/captiveportal/config
echo "wan_interface=$wan_interface" >> /etc/captiveportal/config
read -p "Enter homepage url, example(http://google.com): " redirect
echo "redirect=\"$redirect\"" >> /etc/captiveportal/config
# Split the IP address into an array using dot as the delimiter
IFS='.' read -r -a ip_array <<< "$portalip"
if [[ "${ip_array[0]}" == "10" ]]
then
IPConfigured=1
echo "localnet=10.0.0.0/8" >> /etc/captiveportal/config
fi
if [[ "${ip_array[0]}.${ip_array[1]}" == "192.168" ]]
then
echo "localnet=192.168.${ip_array[2]}.0/24" >> /etc/captiveportal/config
IPConfigured=3
fi
if [[ "${ip_array[0]}" == "172" && ${ip_array[1]} -lt 32 && ${ip_array[1]} -gt 15 ]]
then
echo "localnet=172.${ip_array[1]}.0.0/16" >> /etc/captiveportal/config
IPConfigured=2
fi
if [[ "$IPConfigured" == "0" ]]
then
echo "Could not detect your local IP class."
echo "Please make sure you enter the local ip address for your portal IP is not your internet ip."
exit 1
fi
apt install -y ncat dnsmasq att python3-requests
cp /etc/dnsmasq.conf /etc/captiveportal/dnsmasq.conf.off
echo "port=0" > /etc/dnsmasq.conf
echo "dhcp-option=3,$portalip" >> /etc/dnsmasq.conf
echo "dhcp-option=6,$portalip" >> /etc/dnsmasq.conf
case $IPConfigured in
 1)
 dhcpRange=${ip_array[0]}.0.0.1,${ip_array[0]}.255.255.254
 ;;
 2)
 dhcpRange=${ip_array[0]}.${ip_array[1]}.0.1,${ip_array[0]}.${ip_array[1]}.255.254
 ;;
 3)
 dhcpRange=${ip_array[0]}.${ip_array[1]}.${ip_array[2]}.1,${ip_array[0]}.${ip_array[1]}.${ip_array[2]}.254
 ;;
esac
cat /etc/captiveportal/named.conf.header /etc/captiveportal/named.conf.footer1 /etc/captiveportal/named.conf.footer2 > /etc/bind/named.conf.local
echo "dhcp-range=$dhcpRange,7d" >> /etc/dnsmasq.conf
chmod +x /usr/local/bin/gameserver
chmod +x /usr/local/bin/blocksite
chmod +x /usr/local/bin/unblocksite
chmod +x /usr/local/bin/mac-add
chmod +x /usr/local/bin/hosts-get
chmod +x /usr/local/bin/captive-portal.sh
chmod +x /usr/local/bin/natinstall
chmod +x /usr/local/bin/cpuser
chmod +x /usr/local/bin/hosts-build
natinstall
gameserver
cp captive-portal.service /etc/systemd/system/
systemctl enable captive-portal
systemctl enable named
systemctl enable dnsmasq
systemctl restart named
echo "When someone successfully logins it will say Welcome to the network_name network"
read -p "Enter a network name, this can be anything, it doesn't need to be your wifi name: " welcomename
echo "welcomename=\"$welcomename\"" >> /etc/captiveportal/config
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
