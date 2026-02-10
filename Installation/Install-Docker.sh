#!/bin/bash

# Script to install Docker on Ubuntu

set -e

echo "🔄 Updating package index..."
sudo apt update

echo "📦 Installing prerequisites..."
sudo apt install -y ca-certificates curl gnupg lsb-release

echo "📁 Creating Docker keyring directory..."
sudo mkdir -m 0755 -p /etc/apt/keyrings

echo "🔐 Adding Docker GPG key..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo "📄 Setting up the Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "🔄 Updating package index again with Docker repo..."
sudo apt update

echo "🐳 Installing Docker Engine and plugins..."
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "✅ Verifying Docker installation..."
sudo docker run hello-world

echo "👤 Adding current user (${USER}) to docker group..."
sudo usermod -aG docker $USER

echo "🎉 Docker installed successfully! You may need to log out and back in for group changes to take effect."