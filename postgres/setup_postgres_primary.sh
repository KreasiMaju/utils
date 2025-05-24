#!/bin/bash
set -e

echo "=== SETUP PRIMARY POSTGRESQL ==="
read -p "Masukkan IP Replica: " REPL_IP
read -p "Masukkan username untuk replication: " REPL_USER
read -s -p "Masukkan password untuk replication: " REPL_PASS
echo

# Install PostgreSQL
sudo apt update
sudo apt install -y postgresql

# Edit postgresql.conf
PG_CONF="/etc/postgresql/$(psql -V | awk '{print $3}' | cut -d. -f1,2)/main/postgresql.conf"
sudo sed -i "s/#wal_level = minimal/wal_level = replica/" $PG_CONF
sudo sed -i "s/#max_wal_senders = 10/max_wal_senders = 5/" $PG_CONF
sudo sed -i "s/#wal_keep_size = 0/wal_keep_size = 64/" $PG_CONF
sudo sed -i "s/#hot_standby = on/hot_standby = on/" $PG_CONF

# Edit pg_hba.conf
PG_HBA="/etc/postgresql/$(psql -V | awk '{print $3}' | cut -d. -f1,2)/main/pg_hba.conf"
echo "host replication $REPL_USER $REPL_IP/32 md5" | sudo tee -a $PG_HBA

# Restart PostgreSQL
sudo systemctl restart postgresql

# Buat user replicator
sudo -u postgres psql -c "CREATE ROLE $REPL_USER WITH REPLICATION LOGIN PASSWORD '$REPL_PASS';"

echo "Primary setup selesai. Lanjutkan ke replica!"
