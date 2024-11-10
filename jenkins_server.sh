#!/bin/bash

# Update package lists
sudo apt-get update

# Install required system packages
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    gnupg \
    lsb-release \
    python3.12 \
    python3.12-venv \
    python3-pip \
    git

# Install Docker
# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add Jenkins user to docker group
sudo usermod -aG docker jenkins

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.5/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update
sudo apt-get install -y terraform=1.9.7*

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip

# Install pre-commit
pip3 install pre-commit

# Verify installations
echo "Verifying installations..."
docker --version
docker-compose --version
terraform --version
aws --version
python3.12 --version
pre-commit --version

# Create a test directory for pre-commit configuration
mkdir -p /var/lib/jenkins/pre-commit-cache
chown jenkins:jenkins /var/lib/jenkins/pre-commit-cache

# Set environment variables
echo "export PRE_COMMIT_HOME=/var/lib/jenkins/pre-commit-cache" | sudo tee -a /etc/environment
echo "export DOCKER_BUILDKIT=1" | sudo tee -a /etc/environment
echo "export COMPOSE_DOCKER_CLI_BUILD=1" | sudo tee -a /etc/environment

# Configure Docker to start on boot
sudo systemctl enable docker

# Restart Jenkins agent service (if running as a service)
sudo systemctl restart jenkins-agent || true

echo "Installation complete. Please restart the Jenkins agent to apply all changes."
