#!/bin/bash

# Function to check if a rule exists
rule_exists() {
    iptables -S FORWARD | grep -q "$1"
}

# If the first argument is "DROP", add the DROP all rule if it doesn't exist
if [[ "$1" == "DROP" ]]; then
    if rule_exists "-j DROP"; then
        echo "DROP all rule already exists."
    else
        iptables -A FORWARD -j DROP
        echo "Added DROP all rule to the FORWARD chain."
    fi
    exit 0
fi

# Check if MAC address and action are provided
if [[ -n "$1" && -n "$2" ]]; then
    # Check if the MAC address rule already exists in iptables
    if rule_exists "$1"; then
        echo "MAC address $1 is already whitelisted."
    else
        echo "MAC address $1 does not exist, adding rule."
        iptables -I FORWARD -m mac --mac-source "$1" -j "$2"
        echo "Rule added for MAC $1 with action $2."
    fi
else
    echo "Usage: $0 <MAC address> <ACTION>"
    echo "Example: $0 aa:bb:cc:dd:ee:ff ACCEPT"
    exit 1
fi
