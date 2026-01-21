#!/bin/bash

set -e

echo "=============================================="
echo " Jenkins Installation Started"
echo "=============================================="

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run this script using sudo or as root"
  exit 1
fi

echo "🔄 Updating system packages..."
apt update && apt upgrade -y

echo "📦 Installing required system utilities..."
apt install -y curl wget gnupg2 ca-certificates lsb-release apt-transport-https

echo "☕ Checking Java installation..."
if command -v java >/dev/null 2>&1; then
  echo "✅ Java already installed:"
  java -version
else
  echo "⬇️ Java not found. Installing OpenJDK 21 (LTS)..."
  apt install -y openjdk-21-jdk
  echo "✅ Java installed successfully:"
  java -version
fi

echo "🔑 Adding Jenkins GPG key..."
if [ ! -f /usr/share/keyrings/jenkins-keyring.asc ]; then
  curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key \
  | tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
else
  echo "✅ Jenkins GPG key already exists"
fi

echo "📂 Adding Jenkins repository..."
if [ ! -f /etc/apt/sources.list.d/jenkins.list ]; then
  echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
https://pkg.jenkins.io/debian-stable binary/" \
  | tee /etc/apt/sources.list.d/jenkins.list
else
  echo "✅ Jenkins repository already configured"
fi

echo "📥 Installing Jenkins..."
apt update
apt install -y jenkins

echo "🚀 Starting and enabling Jenkins service..."
systemctl start jenkins
systemctl enable jenkins

echo "📊 Jenkins service status:"
systemctl status jenkins --no-pager

echo "=============================================="
echo " Jenkins Installation Completed Successfully"
echo "=============================================="
echo ""
echo "🔐 Initial Jenkins Admin Password:"
cat /var/lib/jenkins/secrets/initialAdminPassword
echo ""
echo "🌐 Access Jenkins at: http://<SERVER-IP>:8080"
echo "=============================================="