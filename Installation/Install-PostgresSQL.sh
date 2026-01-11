#!/bin/bash

# What's Included:

# 1. Install PostgreSQL
# 2. Enable/start service
# 3. Check status and version
# 4. Set password for postgres user
# 5. (Optional) Create a new PostgreSQL user with custom privileges
# 6. (Optional) Create a new database
# 7. (Optional) Grant privileges on the new DB to the new user
# 8. Configure PostgreSQL to allow password-based local connections (via pg_hba.conf)
# 9. Restart the service to apply changes
# psql -U your_user -d your_db -h localhost -W (Test it)

# Colors for output
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo "-------Installing Postgres DB------"
sudo apt update
sudo apt install -y postgresql postgresql-contrib
echo -e "${GREEN}✅ PostgreSQL Installed${NC}"
echo "-----------------------------------"

echo "-----Enabling Postgres Service-----"
sudo systemctl enable --now postgresql
echo -e "${GREEN}✅ PostgreSQL Service Enabled and Started${NC}"
echo "-----------------------------------"

echo "--------Postgres DB Version--------"
psql --version
echo "-----------------------------------"

echo "----Set PostgreSQL 'postgres' User Password----"
read -s -p "Enter new password for 'postgres' user: " POSTGRES_PASSWORD
echo ""
read -s -p "Confirm password: " POSTGRES_PASSWORD_CONFIRM
echo ""

if [ "$POSTGRES_PASSWORD" != "$POSTGRES_PASSWORD_CONFIRM" ]; then
  echo "❌ Passwords do not match. Exiting."
  exit 1
fi

# Set password for 'postgres' user
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '${POSTGRES_PASSWORD}';"
echo -e "${GREEN}✅ 'postgres' password updated${NC}"

# Optional: Create a new user
echo ""
read -p "Do you want to create a new PostgreSQL user? (y/n): " CREATE_USER
if [[ "$CREATE_USER" =~ ^[Yy]$ ]]; then
  read -p "Enter new PostgreSQL username: " NEW_DB_USER
  read -s -p "Enter password for new user: " NEW_DB_PASS
  echo ""
  read -s -p "Confirm password: " NEW_DB_PASS_CONFIRM
  echo ""

  if [ "$NEW_DB_PASS" != "$NEW_DB_PASS_CONFIRM" ]; then
    echo "❌ Passwords do not match. Exiting."
    exit 1
  fi

  sudo -u postgres psql -c "CREATE USER ${NEW_DB_USER} WITH ENCRYPTED PASSWORD '${NEW_DB_PASS}';"
  echo -e "${GREEN}✅ User '${NEW_DB_USER}' created${NC}"

  # Optional: Create a new database for that user
  read -p "Do you want to create a database for '${NEW_DB_USER}'? (y/n): " CREATE_DB
  if [[ "$CREATE_DB" =~ ^[Yy]$ ]]; then
    read -p "Enter database name: " NEW_DB_NAME
    sudo -u postgres psql -c "CREATE DATABASE ${NEW_DB_NAME} OWNER ${NEW_DB_USER};"
    echo -e "${GREEN}✅ Database '${NEW_DB_NAME}' created and owned by '${NEW_DB_USER}'${NC}"
  fi
fi

# Configure pg_hba.conf to allow password authentication (local)
PG_HBA_FILE=$(sudo -u postgres psql -t -P format=unaligned -c "SHOW hba_file;")

if sudo grep -q "^local\s\+all\s\+all\s\+peer" "$PG_HBA_FILE"; then
  echo "🔧 Updating 'pg_hba.conf' to use 'md5' authentication..."
  sudo sed -i "s/^local\s\+all\s\+all\s\+peer/local all all md5/" "$PG_HBA_FILE"
  echo -e "${GREEN}✅ Updated 'pg_hba.conf' to use password authentication (md5)${NC}"
fi

# Restart PostgreSQL to apply changes
echo "🔁 Restarting PostgreSQL..."
sudo systemctl restart postgresql
echo -e "${GREEN}✅ PostgreSQL restarted${NC}"

echo ""
echo -e "${GREEN}🎉 PostgreSQL setup is complete!${NC}"