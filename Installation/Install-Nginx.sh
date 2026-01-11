#!/bin/bash

# What's Included:
# 1. Install Nginx
# 2. Enable/start Nginx service
# 3. Check status and version
# 4. Create a sample server block (Optional)
# 5. Test Nginx config and reload

# Colors for output
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo "-------- Installing Nginx Web Server --------"
sudo apt update
sudo apt install -y nginx
echo -e "${GREEN}✅ Nginx Installed${NC}"
echo "---------------------------------------------"

echo "------ Enabling & Starting Nginx Service ------"
sudo systemctl enable --now nginx
echo -e "${GREEN}✅ Nginx Service Enabled and Started${NC}"
echo "---------------------------------------------"

echo "--------------- Nginx Version -----------------"
nginx -v
sudo systemctl status nginx
echo "---------------------------------------------"

# Optional: Create a server block
read -p "Do you want to set up a server block? (y/n): " CREATE_SERVER_BLOCK
if [[ "$CREATE_SERVER_BLOCK" =~ ^[Yy]$ ]]; then
  read -p "Enter domain name (e.g., example.local): " DOMAIN
  read -p "Enter root path (e.g., /var/www/example): " ROOT_PATH

  # Create directory and index.html
  sudo mkdir -p "$ROOT_PATH"
  echo "<h1>Welcome to $DOMAIN via Nginx</h1>" | sudo tee "$ROOT_PATH/index.html" > /dev/null
  sudo chown -R $USER:$USER "$ROOT_PATH"

  # Create server block config
  SERVER_BLOCK="/etc/nginx/sites-available/${DOMAIN}"
  sudo tee "$SERVER_BLOCK" > /dev/null <<EOL
server {
    listen 80;
    server_name $DOMAIN;

    root $ROOT_PATH;
    index index.html;

    access_log /var/log/nginx/${DOMAIN}_access.log;
    error_log /var/log/nginx/${DOMAIN}_error.log;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOL

  # Enable site and reload
  sudo ln -s "$SERVER_BLOCK" /etc/nginx/sites-enabled/
  sudo nginx -t && sudo systemctl reload nginx
  echo -e "${GREEN}✅ Server block for '$DOMAIN' configured and enabled${NC}"

  echo "📌 Add the following to your /etc/hosts:"
  echo "127.0.0.1    $DOMAIN"
fi

echo ""
echo -e "${GREEN}🎉 Nginx setup is complete!${NC}"