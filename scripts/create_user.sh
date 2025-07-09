#!/bin/bash

set -e

echo "=== Target Host: ansibleadmin Setup Script ==="

# 1. Create ansibleadmin user if not exists
if id "ansibleadmin" &>/dev/null; then
    echo "User ansibleadmin already exists"
else
    sudo useradd -m -s /bin/bash ansibleadmin
    echo "User ansibleadmin created"
fi

# 2. Set up SSH directory and permissions
sudo mkdir -p /home/ansibleadmin/.ssh
sudo chmod 700 /home/ansibleadmin/.ssh

# 3. Prompt for public key and add to authorized_keys
echo "Paste the ansibleadmin public key from your Ansible control node, then press ENTER and CTRL+D:"
sudo tee /home/ansibleadmin/.ssh/authorized_keys > /dev/null

sudo chmod 600 /home/ansibleadmin/.ssh/authorized_keys
sudo chown -R ansibleadmin:ansibleadmin /home/ansibleadmin/.ssh

# 4. Add to sudoers with NOPASSWD
echo "ansibleadmin ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/ansibleadmin

echo "=== User is created and Setup Done ==="
#echo "Now you can test SSH from your Ansible control node:"
#echo "  sudo -u ansibleadmin ssh -i /home/ansibleadmin/.ssh/id_ed25519 ansibleadmin@<JENKINS_EC2_PUBLIC_IP>"