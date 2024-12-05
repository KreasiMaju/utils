#!/bin/sh

# Exit on error
set -e

echo "Updating system and installing dependencies..."
apk update
apk add --no-cache strongswan strongswan-libs strongswan-ipsec strongswan-swanctl

echo "Configuring StrongSwan with username/password authentication..."

# Create the ipsec.conf file
cat > /etc/ipsec.conf <<EOF
# ipsec.conf - strongSwan IPsec configuration file

config setup
    charondebug="ike 2, knl 2, cfg 2"

conn %default
    keyexchange=ikev2
    ike=aes256-sha256-modp2048!
    esp=aes256-sha256!

conn myvpn
    left=%any
    leftsubnet=0.0.0.0/0
    leftauth=pubkey
    leftcert=serverCert.pem
    right=%any
    rightauth=eap-mschapv2
    rightsourceip=10.10.10.0/24
    auto=add
EOF

# Create the ipsec.secrets file
cat > /etc/ipsec.secrets <<EOF
: RSA serverKey.pem
EOF

# Configure credentials for EAP-MSCHAPv2
cat > /etc/strongswan.d/charon/eap-mschapv2.conf <<EOF
eap-mschapv2 {
    load = yes
}
EOF

# Create the strongSwan user credentials
cat > /etc/strongswan/ipsec.d/credentials.conf <<EOF
username : EAP "password"
EOF

# Generate server certificates (self-signed for simplicity)
echo "Generating certificates..."
ipsec pki --gen --type rsa --size 2048 --outform pem > /etc/ipsec.d/private/serverKey.pem
ipsec pki --self --ca --lifetime 3650 --in /etc/ipsec.d/private/serverKey.pem --type rsa --dn "C=US, O=MyVPN, CN=VPN Root CA" --outform pem > /etc/ipsec.d/cacerts/caCert.pem
ipsec pki --gen --type rsa --size 2048 --outform pem > /etc/ipsec.d/private/serverKey.pem
ipsec pki --pub --in /etc/ipsec.d/private/serverKey.pem --type rsa | ipsec pki --issue --lifetime 1825 --cacert /etc/ipsec.d/cacerts/caCert.pem --cakey /etc/ipsec.d/private/serverKey.pem --dn "C=US, O=MyVPN, CN=$(hostname -f)" --san="$(hostname -f)" --outform pem > /etc/ipsec.d/certs/serverCert.pem

# Enable IP forwarding
echo "Enabling IP forwarding..."
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

# Start the IPsec service
echo "Starting StrongSwan service..."
service ipsec start

echo "StrongSwan installation and configuration complete!"
