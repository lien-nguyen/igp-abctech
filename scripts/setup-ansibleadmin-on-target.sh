#!/bin/bash
# Usage: sudo ./setup-ansibleadmin-on-target.sh "<PASTE_PUBLIC_KEY_HERE>"
# Example: sudo ./setup-ansibleadmin-on-target.sh "ssh-ed25519 AAAAC3... ansibleadmin@ansible-server"

set -e

PUBKEY="$1"
if [ -z "$PUBKEY" ]; then
  echo "Usage: sudo $0 \"<PASTE_PUBLIC_KEY_HERE>\""
  exit 1
fi

# Create ansibleadmin user if not exists
id ansibleadmin &>/dev/null || sudo useradd -m -s /bin/bash ansibleadmin

# Add to sudo group
sudo usermod -aG sudo ansibleadmin

# Add to sudoers with NOPASSWD
if [ ! -f /etc/sudoers.d/ansibleadmin ]; then
  echo "ansibleadmin ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/ansibleadmin
  sudo chmod 440 /etc/sudoers.d/ansibleadmin
fi

# Setup SSH directory and authorized_keys
sudo mkdir -p /home/ansibleadmin/.ssh
sudo chmod 700 /home/ansibleadmin/.ssh

echo "$PUBKEY" | sudo tee /home/ansibleadmin/.ssh/authorized_keys > /dev/null
sudo chmod 600 /home/ansibleadmin/.ssh/authorized_keys
sudo chown -R ansibleadmin:ansibleadmin /home/ansibleadmin/.ssh

# Print result
echo "ansibleadmin user and SSH key setup complete."
echo "You can now SSH as ansibleadmin to this host using your private key."
