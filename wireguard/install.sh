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
apt-get install resolvconf

# Set WireGuard directory and file paths
WG_DIR="/etc/wireguard"
WG_CONF="${WG_DIR}/wg0.conf"

# Generate client Private and Public Keys
echo "Generating Client Private and Public Keys..."
CLIENT_PRIVATE_KEY=$(wg genkey)
CLIENT_PUBLIC_KEY=$(echo "$CLIENT_PRIVATE_KEY" | wg pubkey)

# Prompt for server information
echo "Please provide the following server details:"

read -p "Enter Server PublicKey: " SERVER_PUBLIC_KEY
read -p "Enter Server Endpoint (IP:Port, e.g., 192.168.1.10:1234): " SERVER_ENDPOINT
read -p "Enter Client IP (e.g., 10.0.0.2/24): " CLIENT_IP
read -p "Enter DNS (e.g., 1.1.1.1): " DNS
read -p "Enter PersistentKeepalive (default 25): " PERSISTENT_KEEPALIVE
PERSISTENT_KEEPALIVE=${PERSISTENT_KEEPALIVE:-25}

# Create WireGuard configuration file
echo "Creating WireGuard client configuration..."
mkdir -p $WG_DIR
cat <<EOF > $WG_CONF
[Interface]
PrivateKey = ${CLIENT_PRIVATE_KEY}
Address = ${CLIENT_IP}
DNS = ${DNS}

[Peer]
PublicKey = ${SERVER_PUBLIC_KEY}
Endpoint = ${SERVER_ENDPOINT}
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = ${PERSISTENT_KEEPALIVE}
EOF

# Set appropriate permissions for the configuration file
chmod 600 $WG_CONF

# Start WireGuard
echo "Starting WireGuard client..."
wg-quick up wg0
systemctl enable wg-quick@wg0

# Output the Client PublicKey to give to the server administrator
echo "WireGuard client setup complete."
echo "Provide this Client PublicKey to the server administrator: ${CLIENT_PUBLIC_KEY}"
echo "Configuration file located at: ${WG_CONF}"
