#!/bin/bash
set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive

LOG_FILE="/var/log/user-data-mythic.log"
exec > >(tee -a "$LOG_FILE") 2>&1

# Base packages
apt-get update -y
apt-get install -y git make curl ca-certificates gnupg lsb-release

# Optional but safer than full apt upgrade
apt-get install -y docker.io docker-compose-plugin || true

systemctl enable docker || true
systemctl start docker || true

# Install Mythic
cd /opt

if [ ! -d /opt/Mythic ]; then
  git clone https://github.com/its-a-feature/Mythic --depth 1 --single-branch
fi

cd /opt/Mythic

# Install Docker the Mythic/Kali way if needed
chmod +x ./install_docker_kali.sh
./install_docker_kali.sh

systemctl enable docker
systemctl start docker

# Build mythic-cli
make

# Start Mythic
./mythic-cli start

# Save status
./mythic-cli status || true