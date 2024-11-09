#!/bin/bash

# Exit if any command fails
set -e

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

# Install WireGuard
echo "Installing WireGuard..."
apt update && apt install -y wireguard

# Set WireGuard directory and file paths
WG_DIR="/etc/wireguard"
WG_CONF="${WG_DIR}/wg0.conf"

# Ask for server and peer details
read -p "Enter Server PrivateKey: " SERVER_PRIVATE_KEY
read -p "Enter Server IP (e.g., 10.0.0.2/24): " SERVER_IP
read -p "Enter DNS (e.g., 1.1.1.1): " DNS
read -p "Enter Peer PublicKey: " PEER_PUBLIC_KEY
read -p "Enter Peer Allowed IPs (e.g., 0.0.0.0/0, ::/0): " PEER_ALLOWED_IPS
read -p "Enter Endpoint (e.g., 192.168.1.183:51820): " ENDPOINT
read -p "Enter PersistentKeepalive (e.g., 30): " PERSISTENT_KEEPALIVE

# Generate Server PublicKey from the provided PrivateKey
echo "Generating Server PublicKey..."
SERVER_PUBLIC_KEY=$(echo "$SERVER_PRIVATE_KEY" | wg pubkey)

# Create WireGuard configuration file
echo "Creating WireGuard configuration..."
mkdir -p $WG_DIR
cat <<EOF > $WG_CONF
[Interface]
PrivateKey = ${SERVER_PRIVATE_KEY}
Address = ${SERVER_IP}
DNS = ${DNS}

[Peer]
PublicKey = ${PEER_PUBLIC_KEY}
AllowedIPs = ${PEER_ALLOWED_IPS}
Endpoint = ${ENDPOINT}
PersistentKeepalive = ${PERSISTENT_KEEPALIVE}
EOF

# Enable IP forwarding
echo "Enabling IP forwarding..."
sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

# Start and enable WireGuard
echo "Starting WireGuard..."
wg-quick up wg0
systemctl enable wg-quick@wg0

# Output the Server PublicKey for reference
echo "WireGuard setup complete."
echo "Server PublicKey: ${SERVER_PUBLIC_KEY}"
echo "Configuration file located at: ${WG_CONF}"
