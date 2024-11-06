#!/bin/bash

# Update paket sistem
echo "Updating system packages..."
sudo apt update

# Install dependencies
echo "Installing dependencies..."
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

# Tambahkan GPG Key Docker
echo "Adding Docker GPG key..."
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Tambahkan repository Docker
echo "Adding Docker repository..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update paket sistem lagi setelah menambahkan repository Docker
echo "Updating package list..."
sudo apt update

# Install Docker
echo "Installing Docker..."
sudo apt install -y docker-ce

# Enable dan start Docker service
echo "Starting and enabling Docker service..."
sudo systemctl enable docker
sudo systemctl start docker

# Cek status Docker
echo "Checking Docker status..."
sudo systemctl status docker --no-pager

# Jalankan container Portainer Agent
echo "Running Portainer Agent container..."
sudo docker run -d \
  -p 9001:9001 \
  --name portainer_agent \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /var/lib/docker/volumes:/var/lib/docker/volumes \
  -v /:/host \
  portainer/agent:2.21.3

echo "Docker and Portainer Agent installation completed."

curl -fsSL https://get.casaos.io | sudo bash
