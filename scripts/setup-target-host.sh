#!/bin/bash

# Target Host Setup Script
# Run this script on each target host (Docker hosts, Kubernetes nodes)

set -e

HOST_TYPE="${1:-docker}"  # docker, k8s-master, k8s-worker
ANSIBLE_PUBLIC_KEY="${2}"

echo "=== Target Host Setup Script ==="
echo "Setting up host as: $HOST_TYPE"

# Update package cache
sudo apt update

# Install basic packages
sudo apt install -y curl wget gnupg lsb-release software-properties-common python3 python3-pip

# Create ansibleadmin user
sudo useradd -m -s /bin/bash ansibleadmin || echo "User ansibleadmin already exists"

# Add ansibleadmin to sudo group with NOPASSWD
echo "ansibleadmin ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/ansibleadmin

# Setup SSH for ansibleadmin
sudo mkdir -p /home/ansibleadmin/.ssh
sudo chmod 700 /home/ansibleadmin/.ssh

# Add public key if provided
if [ ! -z "$ANSIBLE_PUBLIC_KEY" ]; then
    echo "$ANSIBLE_PUBLIC_KEY" | sudo tee /home/ansibleadmin/.ssh/authorized_keys
    sudo chmod 600 /home/ansibleadmin/.ssh/authorized_keys
    sudo chown -R ansibleadmin:ansibleadmin /home/ansibleadmin/.ssh
    echo "Public key added for ansibleadmin"
else
    echo "No public key provided. You'll need to manually add it to /home/ansibleadmin/.ssh/authorized_keys"
fi

# Host-specific setup
case $HOST_TYPE in
    "docker")
        echo "Setting up Docker host..."
        
        # Install Docker
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        sudo apt update
        sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        
        # Start and enable Docker
        sudo systemctl start docker
        sudo systemctl enable docker
        
        # Add ansibleadmin to docker group
        sudo usermod -aG docker ansibleadmin
        
        # Install Python Docker module
        sudo pip3 install docker
        
        echo "Docker setup completed!"
        ;;
        
    "k8s-master")
        echo "Setting up Kubernetes master..."
        
        # Install kubectl
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
        rm kubectl
        
        # Install Python Kubernetes module
        sudo pip3 install kubernetes pyyaml
        
        echo "Kubernetes master setup completed!"
        echo "Don't forget to copy kubeconfig to /home/ansibleadmin/.kube/config"
        ;;
        
    "k8s-worker")
        echo "Setting up Kubernetes worker..."
        
        # Install kubectl
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
        rm kubectl
        
        echo "Kubernetes worker setup completed!"
        ;;
        
    *)
        echo "Unknown host type: $HOST_TYPE"
        echo "Supported types: docker, k8s-master, k8s-worker"
        exit 1
        ;;
esac

echo "=== Host setup completed! ==="
echo ""
echo "Next steps:"
echo "1. If you didn't provide the public key, add it manually:"
echo "   echo 'ssh-rsa AAAAB3NzaC1yc2E...' >> /home/ansibleadmin/.ssh/authorized_keys"
echo ""
echo "2. Test SSH connectivity from Ansible control node:"
echo "   ssh -i ~/.ssh/id_rsa ansibleadmin@$(hostname -I | awk '{print $1}')"
echo ""
echo "3. For Kubernetes master, copy kubeconfig:"
echo "   sudo cp /etc/kubernetes/admin.conf /home/ansibleadmin/.kube/config"
echo "   sudo chown ansibleadmin:ansibleadmin /home/ansibleadmin/.kube/config"
