#!/bin/bash

# Variabel Konfigurasi
WG_INTERFACE="wg0"
PRIVATE_KEY_FILE="/etc/wireguard/private.key"
PUBLIC_KEY_FILE="/etc/wireguard/public.key"
PRESHARED_KEY_FILE="/etc/wireguard/preshared.key"
IP_ADDRESS="10.0.0.1/24"
PORT="51820"
DNS="1.1.1.1"
PEER_PUBLIC_KEY=""
PEER_IP="10.0.0.2/32"

# Install WireGuard
echo "Installing WireGuard..."
apt update
apt install -y wireguard iptables

# Generate Server Keys
echo "Generating WireGuard Server Keys..."
wg genkey | tee $PRIVATE_KEY_FILE | wg pubkey > $PUBLIC_KEY_FILE

# Setup WireGuard Config
echo "Setting up WireGuard Config..."
cat > /etc/wireguard/$WG_INTERFACE.conf <<EOL
[Interface]
PrivateKey = $(cat $PRIVATE_KEY_FILE)
Address = $IP_ADDRESS
ListenPort = $PORT
DNS = $DNS

PostUp = iptables -t nat -I POSTROUTING -o eth0 -j MASQUERADE
PostUp = iptables -A FORWARD -i $WG_INTERFACE -o eth0 -j ACCEPT
PostUp = iptables -A FORWARD -i eth0 -o $WG_INTERFACE -m state --state RELATED,ESTABLISHED -j ACCEPT

PreDown = iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
PreDown = iptables -D FORWARD -i $WG_INTERFACE -o eth0 -j ACCEPT
PreDown = iptables -D FORWARD -i eth0 -o $WG_INTERFACE -m state --state RELATED,ESTABLISHED -j ACCEPT

[Peer]
PublicKey = $PEER_PUBLIC_KEY
AllowedIPs = $PEER_IP
EOL

# Set up Preshared Key if provided
if [ ! -z "$PRESHARED_KEY_FILE" ]; then
    echo "Setting up Preshared Key..."
    wg set $WG_INTERFACE peer $PEER_PUBLIC_KEY preshared-key $PRESHARED_KEY_FILE
fi

# Enable IP forwarding and setup NAT
echo "Enabling IP forwarding and setting up NAT..."
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sysctl -p

# Set up iptables to persist across reboots
echo "Saving iptables rules..."
iptables-save > /etc/iptables/rules.v4

# Start WireGuard
echo "Starting WireGuard..."
wg-quick up $WG_INTERFACE

# Enable WireGuard on Boot
systemctl enable wg-quick@$WG_INTERFACE

echo "WireGuard setup is complete."
