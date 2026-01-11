#!/bin/bash

# What's Included:
#
# 1. Install MySQL Server
# 2. Enable/start service
# 3. Check status and version
# 4. Secure MySQL installation (root password, auth method)
# 5. (Optional) Create a new MySQL user
# 6. (Optional) Create a new database
# 7. (Optional) Grant privileges
# 8. Configure MySQL to allow password-based login
# 9. Restart MySQL service
# mysql -u your_user -p -h localhost (Test it)

# Colors
GREEN='\033[0;32m'
NC='\033[0m'

echo "-------Installing MySQL DB-------"
sudo apt update
sudo apt install -y mysql-server
echo -e "${GREEN}✅ MySQL Installed${NC}"
echo "--------------------------------"

echo "-----Enabling MySQL Service-----"
sudo systemctl enable --now mysql
echo -e "${GREEN}✅ MySQL Service Enabled and Started${NC}"
echo "--------------------------------"

echo "---------MySQL Version----------"
mysql --version
echo "--------------------------------"

echo "-----Securing MySQL Installation-----"

# Set MySQL root password
read -s -p "Enter new MySQL root password: " MYSQL_ROOT_PASSWORD
echo ""
read -s -p "Confirm password: " MYSQL_ROOT_PASSWORD_CONFIRM
echo ""

if [ "$MYSQL_ROOT_PASSWORD" != "$MYSQL_ROOT_PASSWORD_CONFIRM" ]; then
  echo "❌ Passwords do not match. Exiting."
  exit 1
fi

# Configure root user to use mysql_native_password
sudo mysql <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASSWORD}';
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF

echo -e "${GREEN}✅ MySQL root password configured${NC}"

# Optional: Create new MySQL user
echo ""
read -p "Do you want to create a new MySQL user? (y/n): " CREATE_USER
if [[ "$CREATE_USER" =~ ^[Yy]$ ]]; then
  read -p "Enter new MySQL username: " NEW_DB_USER
  read -s -p "Enter password for new user: " NEW_DB_PASS
  echo ""
  read -s -p "Confirm password: " NEW_DB_PASS_CONFIRM
  echo ""

  if [ "$NEW_DB_PASS" != "$NEW_DB_PASS_CONFIRM" ]; then
    echo "❌ Passwords do not match. Exiting."
    exit 1
  fi

  sudo mysql -u root -p"${MYSQL_ROOT_PASSWORD}" <<EOF
CREATE USER '${NEW_DB_USER}'@'localhost' IDENTIFIED BY '${NEW_DB_PASS}';
EOF

  echo -e "${GREEN}✅ User '${NEW_DB_USER}' created${NC}"

  # Optional: Create database
  read -p "Do you want to create a database for '${NEW_DB_USER}'? (y/n): " CREATE_DB
  if [[ "$CREATE_DB" =~ ^[Yy]$ ]]; then
    read -p "Enter database name: " NEW_DB_NAME

    sudo mysql -u root -p"${MYSQL_ROOT_PASSWORD}" <<EOF
CREATE DATABASE ${NEW_DB_NAME};
GRANT ALL PRIVILEGES ON ${NEW_DB_NAME}.* TO '${NEW_DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF

    echo -e "${GREEN}✅ Database '${NEW_DB_NAME}' created and privileges granted${NC}"
  fi
fi

# Restart MySQL
echo "🔁 Restarting MySQL..."
sudo systemctl restart mysql
echo -e "${GREEN}✅ MySQL restarted${NC}"

echo ""
echo -e "${GREEN}🎉 MySQL setup is complete!${NC}"
