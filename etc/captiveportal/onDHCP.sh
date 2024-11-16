#!/bin/bash
t=$(date)
MAC_FILENAME=$(echo -n "/etc/captiveportal/registered/$2.mac" | tr ':' '-')
echo "[$t] DHCP_$1 $2 $3 $4" >> $MAC_FILENAME
echo "[$t] DHCP_$1 $2 $3 $4" >> /etc/captiveportal/registered/$2.ip
