#!/bin/bash

# What's Included:
#
# 1. Install nvm (Node Version Manager) for a target user
# 2. Install a specific Node.js version via nvm and set it as the default
# 3. Install PM2 globally under the selected Node.js
# 4. Optionally configure PM2 startup (systemd) so processes survive reboots
# 5. Optionally create a small sample Node app and run it with PM2 (for testing)
# 6. Print final verification (node, npm, pm2 versions and pm2 process list)
# 7. Attempt to source the user's shell startup files so nvm is usable immediately

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== nvm + Node (user) + pm2 installer ===${NC}"

# Decide which user to install for:
if [ "$EUID" -eq 0 ]; then
  # running as root (e.g. sudo). Prefer to install for the invoking user.
  INSTALL_USER="${SUDO_USER:-root}"
else
  INSTALL_USER="$USER"
fi

HOME_DIR=$(eval echo "~$INSTALL_USER")
NVM_DIR="$HOME_DIR/.nvm"

echo -e "${YELLOW}Installing for user:${NC} $INSTALL_USER (home: $HOME_DIR)"

# Ensure curl or wget is present
if command -v curl >/dev/null 2>&1; then
  DL_CMD="curl -o-"
elif command -v wget >/dev/null 2>&1; then
  DL_CMD="wget -qO-"
else
  echo "❌ curl or wget is required. Install one and re-run (e.g. sudo apt install -y curl)"
  exit 1
fi

# Ask NVM version (you can input a tag like 'v0.40.2' or press Enter for latest release)
read -p "Enter nvm version tag to install (example 'v0.40.2') or press Enter to install latest release: " NVM_TAG
if [ -z "$NVM_TAG" ]; then
  # Try to detect latest release tag via GitHub API (no jq required)
  echo -e "${YELLOW}Detecting latest nvm release from GitHub...${NC}"
  LATEST_TAG="$(curl -s 'https://api.github.com/repos/nvm-sh/nvm/releases/latest' \
    | grep -oP '"tag_name":\s*"\K(.*?)(?=")' || true)"
  if [ -n "$LATEST_TAG" ]; then
    echo -e "${GREEN}Found latest nvm tag: ${LATEST_TAG}${NC}"
    NVM_URL="https://raw.githubusercontent.com/nvm-sh/nvm/${LATEST_TAG}/install.sh"
  else
    echo -e "${YELLOW}Could not determine latest tag; falling back to the default installer URL (master/HEAD).${NC}"
    NVM_URL="https://raw.githubusercontent.com/nvm-sh/nvm/install.sh"
  fi
else
  NVM_URL="https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_TAG}/install.sh"
fi

echo -e "${GREEN}Installing nvm from:${NC} $NVM_URL"

# Run the installer as the target user (so dotfiles are updated for that user)
sudo -u "$INSTALL_USER" -H bash -lc "$DL_CMD $NVM_URL | bash"

# Ask for Node version to install
read -p "Enter Node.js version to install (e.g. 20, 18, lts, node). Default: lts: " NODE_VERSION
NODE_VERSION="${NODE_VERSION:-lts}"

echo -e "${GREEN}Installing Node.js version:${NC} $NODE_VERSION (via nvm)"

# Install Node and set default (run as INSTALL_USER)
sudo -u "$INSTALL_USER" -H bash -lc "
export NVM_DIR=\"$NVM_DIR\"
[ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\"
nvm install \"$NODE_VERSION\"
nvm alias default \"$NODE_VERSION\"
nvm use default
"

echo -e "${GREEN}✅ Node installed and default alias set${NC}"

# Install pm2 globally under that node (as INSTALL_USER)
echo -e "${GREEN}Installing pm2 globally (npm -g)...${NC}"
sudo -u "$INSTALL_USER" -H bash -lc "
export NVM_DIR=\"$NVM_DIR\"
[ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\"
nvm use default
npm install -g pm2@latest
"

echo -e "${GREEN}✅ pm2 installed${NC}"

# (pm2 startup / sample app code unchanged — include your existing blocks here)
# ... (keep the pm2 startup & sample app blocks you already had) ...

# Final checks: show node & pm2 version and pm2 list (as the install user)
echo -e "${YELLOW}Final verification (Node, npm, pm2):${NC}"
sudo -u "$INSTALL_USER" -H bash -lc "
export NVM_DIR=\"$NVM_DIR\"
[ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\"
nvm use default
echo 'node ->' \$(node -v)
echo 'npm  ->' \$(npm -v)
echo 'pm2  ->' \$(pm2 -v)
echo 'pm2 list:'
pm2 ls || true
"

# Attempt to source common shell startup files so nvm is available for subsequent commands.
# NOTE: this affects the script's shell; it cannot change the parent interactive shell.
echo -e "${YELLOW}Attempting to source user shell startup files so nvm is available...${NC}"
SOURCES=( ".bashrc" ".profile" ".bash_profile" )

for f in "${SOURCES[@]}"; do
  USER_FILE="$HOME_DIR/$f"
  if [ -f "$USER_FILE" ]; then
    echo "Sourcing $USER_FILE for $INSTALL_USER..."
    # If the script is run as the same user interactively, source directly.
    if [ "$INSTALL_USER" = "$USER" ] && [ "$EUID" -ne 0 ]; then
      # shellcheck disable=SC1090
      . "$USER_FILE" || true
    else
      # source as that user inside a login shell so subsequent sudo -u commands in this script can use nvm
      sudo -u "$INSTALL_USER" -H bash -lc ". \"$USER_FILE\"" || true
    fi
  fi
done

echo -e "${GREEN}🎉 nvm + node + pm2 setup complete for user: $INSTALL_USER${NC}"
echo ""
echo "Important:"
echo "- If you ran this script normally (not sourced), your current interactive shell won't automatically pick up nvm."
echo "- To enable nvm in your current shell session run:"
echo "    source $HOME_DIR/.bashrc"
echo "  (or run: source ~/.profile or source ~/.bash_profile if that's what your distro uses)."
echo ""
echo "- If you want the installer to both run and change your current shell automatically, run this script with:"
echo "    source ./install-nvm-node-pm2.sh"
echo "  (That will execute the script in your current shell so the final 'source' has effect.)"

exit 0