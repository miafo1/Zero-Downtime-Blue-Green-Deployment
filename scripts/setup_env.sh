#!/bin/bash

# Setup script for GitHub Codespaces (Debian/Ubuntu)
# Installs Docker, Docker Compose, and Python dependencies

set -e

echo "Starting environment setup..."

# 1. Update system
echo "Updating package lists..."
sudo apt-get update

# 2. Install essential tools
echo "Installing prerequisites..."
sudo apt-get install -y curl git jq

# 3. Check/Install Docker
if ! command -v docker &> /dev/null; then
    echo "Docker not found. Installing..."
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker $USER
else
    echo "Docker is already installed."
fi

# 4. Check/Install Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose not found. Installing..."
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.23.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
else
    echo "Docker Compose is already installed."
fi

# 5. Install Python dependencies
echo "Installing Python dependencies..."
# Check for requirements.txt, if not exists, create a basic one for now or wait
if [ ! -f requirements.txt ]; then
    echo "Creating basic requirements.txt..."
    echo "Flask==3.0.0" > requirements.txt
    echo "gunicorn==21.2.0" >> requirements.txt
    echo "requests==2.31.0" >> requirements.txt
fi

pip install -r requirements.txt

echo "Setup complete! Please restart your terminal if you just installed Docker."
