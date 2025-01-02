#!/bin/bash

# Periksa apakah script dijalankan sebagai root
if [ "$EUID" -ne 0 ]; then
  echo "Silakan jalankan script ini sebagai root atau dengan sudo."
  exit 1
fi

# Unduh skrip instalasi OpenVPN
wget https://git.io/vpn -O openvpn-install.sh

# Periksa apakah unduhan berhasil
if [ $? -ne 0 ]; then
  echo "Gagal mengunduh openvpn-install.sh. Periksa koneksi internet Anda atau URL."
  exit 1
fi

# Beri izin eksekusi pada skrip yang diunduh
chmod +x openvpn-install.sh

# Jalankan skrip instalasi OpenVPN
./openvpn-install.sh
