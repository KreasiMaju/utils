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

# Generate private and public keys
echo "Generating WireGuard keys..."
umask 077
wg genkey | tee ${WG_DIR}/privatekey | wg pubkey > ${WG_DIR}/publickey

PRIVATE_KEY=$(cat ${WG_DIR}/privatekey)
PUBLIC_KEY=$(cat ${WG_DIR}/publickey)

# Ask for server and client IPs
read -p "Enter Server IP (e.g., 10.0.0.1/24): " SERVER_IP
read -p "Enter Client IP (e.g., 10.0.0.2/32): " CLIENT_IP
PORT="51820"

# Create WireGuard configuration file
echo "Creating WireGuard configuration..."
cat <<EOF > $WG_CONF
[Interface]
Address = ${SERVER_IP}
ListenPort = ${PORT}
PrivateKey = ${PRIVATE_KEY}

[Peer]
PublicKey = $(wg genkey | tee ${WG_DIR}/client_privatekey | wg pubkey)
AllowedIPs = ${CLIENT_IP}
EOF

# Enable IP forwarding
echo "Enabling IP forwarding..."
sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

# Start and enable WireGuard
echo "Starting WireGuard..."
wg-quick up wg0
systemctl enable wg-quick@wg0

# Output server public key
echo "Installation and configuration complete."
echo "Server Public Key: ${PUBLIC_KEY}"
echo "Client Private Key: $(cat ${WG_DIR}/client_privatekey)"
echo "Server configuration file located at: ${WG_CONF}"
