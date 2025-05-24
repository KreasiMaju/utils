#!/bin/bash
set -e

echo "=== SETUP REPLICA POSTGRESQL ==="
read -p "Masukkan IP Primary: " PRIMARY_IP
read -p "Masukkan username untuk replication: " REPL_USER
read -s -p "Masukkan password untuk replication: " REPL_PASS
echo

# Install PostgreSQL
sudo apt update
sudo apt install -y postgresql

# Stop PostgreSQL
sudo systemctl stop postgresql

# Hapus data lama
sudo rm -rf /var/lib/postgresql/*/main/*

# Base backup dari primary
export PGPASSWORD=$REPL_PASS
sudo -u postgres pg_basebackup -h $PRIMARY_IP -D /var/lib/postgresql/$(psql -V | awk '{print $3}' | cut -d. -f1,2)/main -U $REPL_USER -W --progress --verbose

# Buat standby.signal
sudo touch /var/lib/postgresql/$(psql -V | awk '{print $3}' | cut -d. -f1,2)/main/standby.signal

# Edit postgresql.conf
PG_CONF="/etc/postgresql/$(psql -V | awk '{print $3}' | cut -d. -f1,2)/main/postgresql.conf"
echo "primary_conninfo = 'host=$PRIMARY_IP port=5432 user=$REPL_USER password=$REPL_PASS'" | sudo tee -a $PG_CONF

# Start PostgreSQL
sudo systemctl start postgresql

echo "Replica setup selesai. Cek status di primary dan replica!"
