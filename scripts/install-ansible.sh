#!/bin/bash

# Ansible Installation and Setup Script for Ubuntu/Debian
# Run this script on the Ansible control node

set -e

echo "=== Ansible Installation and Setup Script ==="
echo "Installing Ansible and required dependencies..."

# Update package
sudo apt update

# Install Python and pip if not already installed
sudo apt install -y python3 python3-pip python3-venv software-properties-common

# Add Ansible PPA repository
sudo add-apt-repository -y --update ppa:ansible/ansible

# Install Ansible
sudo apt install -y ansible

# Install required Python modules for Ansible
sudo pip3 install docker kubernetes pyyaml

# Install Ansible collections
ansible-galaxy collection install kubernetes.core
ansible-galaxy collection install community.docker

# Verify installation
echo "=== Verifying Ansible Installation ==="
ansible --version
python3 -c "import docker; print('Docker module: OK')"
python3 -c "import kubernetes; print('Kubernetes module: OK')"

echo "=== Setting up SSH keys for ansibleadmin ==="
echo "Generating SSH key pair for ansibleadmin user..."

# Create ansibleadmin user if it doesn't exist
sudo useradd -m -s /bin/bash ansibleadmin || echo "User ansibleadmin already exists"

# Create SSH directory
sudo mkdir -p /home/ansibleadmin/.ssh
sudo chmod 700 /home/ansibleadmin/.ssh

# Generate SSH key pair if it doesn't exist
if [ ! -f /home/ansibleadmin/.ssh/id_ed25519 ]; then
    sudo ssh-keygen -t ed25519 -f /home/ansibleadmin/.ssh/id_ed25519 -N "" -C "ansibleadmin@$(hostname)"
    echo "ED25519 SSH key pair generated successfully!"
else
    echo "ED25519 SSH key pair already exists"
fi

# Set proper ownership
sudo chown -R ansibleadmin:ansibleadmin /home/ansibleadmin/.ssh
sudo chmod 600 /home/ansibleadmin/.ssh/id_ed25519
sudo chmod 644 /home/ansibleadmin/.ssh/id_ed25519.pub

# Display public key
echo "=== Public Key (copy this to target hosts) ==="
sudo cat /home/ansibleadmin/.ssh/id_ed25519.pub
echo ""

# Add ansibleadmin to sudo group with NOPASSWD
echo "ansibleadmin ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/ansibleadmin

# Create Ansible directories
sudo mkdir -p /etc/ansible
sudo mkdir -p /var/log/ansible

# Set up basic Ansible configuration
cat << 'EOF' | sudo tee /etc/ansible/ansible.cfg
[defaults]
host_key_checking = False
inventory = /etc/ansible/hosts
remote_user = ansibleadmin
private_key_file = /home/ansibleadmin/.ssh/id_rsa
retry_files_enabled = False
stdout_callback = yaml
gathering = smart
fact_caching = memory
log_path = /var/log/ansible/ansible.log

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no
EOF

# Create log directory and set permissions
sudo mkdir -p /var/log/ansible
sudo chown ansibleadmin:ansibleadmin /var/log/ansible

echo "=== Installation completed! ==="
echo ""
echo "Next steps:"
echo "1. Copy the public key above to all target hosts:"
echo "   - Copy to /home/ansibleadmin/.ssh/authorized_keys on each target host"
echo "   - Ensure ansibleadmin user exists on all target hosts"
echo "   - Add ansibleadmin to sudo group on all target hosts"
echo ""
echo "2. Update the inventory file with your host IPs:"
echo "   - Edit /home/lien/edureka/igp-abctech/ansible/inventory"
echo "   - Replace <DOCKER_HOST_IP>, <K8S_MASTER_IP>, etc. with actual IPs"
echo ""
echo "3. Create vault password file:"
echo "   - cp /home/lien/edureka/igp-abctech/ansible/vault_pass.template /home/lien/edureka/igp-abctech/ansible/vault_pass"
echo "   - Edit vault_pass with your actual password"
echo "   - chmod 600 /home/lien/edureka/igp-abctech/ansible/vault_pass"
echo ""
echo "4. Test connectivity:"
echo "   cd /home/lien/edureka/igp-abctech/ansible"
echo "   ansible all -i inventory -m ping"
echo ""
echo "Public key location: /home/ansibleadmin/.ssh/id_ed25519.pub"
