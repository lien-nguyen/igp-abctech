#!/bin/bash

# Quick Start Script for Ansible CI/CD Setup
# This script helps you get started quickly with the Ansible integration

set -e

echo "=== ABCtechnologies Ansible CI/CD Quick Start ==="
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "Please run this script as a regular user (not root)"
    echo "The script will prompt for sudo when needed"
    exit 1
fi

# Get current directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "Project directory: $PROJECT_DIR"
echo ""

# Function to prompt for user input
prompt_for_input() {
    local prompt="$1"
    local var_name="$2"
    local default_value="$3"
    
    if [ -n "$default_value" ]; then
        read -p "$prompt [$default_value]: " input
        if [ -z "$input" ]; then
            input="$default_value"
        fi
    else
        read -p "$prompt: " input
        while [ -z "$input" ]; do
            echo "This field is required!"
            read -p "$prompt: " input
        done
    fi
    
    eval "$var_name='$input'"
}

echo "=== Configuration Setup ==="
echo "Please provide the following information:"
echo ""

# Get host IPs
prompt_for_input "Docker Host IP" DOCKER_HOST_IP
prompt_for_input "Kubernetes Master IP" K8S_MASTER_IP
prompt_for_input "Kubernetes Worker 1 IP" K8S_WORKER1_IP ""
prompt_for_input "Kubernetes Worker 2 IP" K8S_WORKER2_IP ""
prompt_for_input "Jenkins Host IP" JENKINS_HOST_IP "$(hostname -I | awk '{print $1}')"

# Get registry info
prompt_for_input "Docker Registry URL" DOCKER_REGISTRY "localhost:5000"

# Get vault password
prompt_for_input "Ansible Vault Password" VAULT_PASSWORD

echo ""
echo "=== Installing Ansible ==="
if command -v ansible >/dev/null 2>&1; then
    echo "Ansible is already installed: $(ansible --version | head -n1)"
else
    echo "Installing Ansible..."
    sudo "$PROJECT_DIR/scripts/install-ansible.sh"
fi

echo ""
echo "=== Setting up configuration files ==="

# Update inventory file
cd "$PROJECT_DIR/ansible"

echo "Updating inventory file..."
sed -i "s/<DOCKER_HOST_IP>/$DOCKER_HOST_IP/g" inventory
sed -i "s/<K8S_MASTER_IP>/$K8S_MASTER_IP/g" inventory
sed -i "s/<K8S_WORKER1_IP>/$K8S_WORKER1_IP/g" inventory
sed -i "s/<K8S_WORKER2_IP>/$K8S_WORKER2_IP/g" inventory
sed -i "s/<JENKINS_HOST_IP>/$JENKINS_HOST_IP/g" inventory

# Create vault password file
echo "Creating vault password file..."
echo "$VAULT_PASSWORD" > vault_pass
chmod 600 vault_pass

echo ""
echo "=== Getting SSH public key ==="
if [ -f "/home/ansibleadmin/.ssh/id_rsa.pub" ]; then
    PUBLIC_KEY=$(sudo cat /home/ansibleadmin/.ssh/id_rsa.pub)
    echo "Found existing SSH public key:"
else
    echo "SSH key not found. Please run the Ansible installation script first."
    exit 1
fi

echo "$PUBLIC_KEY"
echo ""

echo "=== Next Steps ==="
echo ""
echo "1. Copy the SSH public key above to all target hosts:"
echo "   Run on each target host:"
echo "   sudo $PROJECT_DIR/scripts/setup-target-host.sh docker \"$PUBLIC_KEY\""
echo "   sudo $PROJECT_DIR/scripts/setup-target-host.sh k8s-master \"$PUBLIC_KEY\""
echo "   sudo $PROJECT_DIR/scripts/setup-target-host.sh k8s-worker \"$PUBLIC_KEY\""
echo ""

echo "2. Test connectivity:"
echo "   cd $PROJECT_DIR/ansible"
echo "   ansible all -i inventory -m ping"
echo ""

echo "3. Setup target hosts (run this after step 1):"
echo "   cd $PROJECT_DIR/ansible"
echo "   ansible-playbook -i inventory playbooks/setup-hosts.yml"
echo ""

echo "4. Test Docker deployment:"
echo "   cd $PROJECT_DIR"
echo "   mvn clean package"
echo "   cd ansible"
echo "   ansible-playbook -i inventory playbooks/docker-deploy.yml \\"
echo "     --extra-vars \"war_file_path=$PROJECT_DIR/target/ABCtechnologies-1.0.war\" \\"
echo "     --extra-vars \"build_number=1\""
echo ""

echo "5. Test Kubernetes deployment:"
echo "   cd $PROJECT_DIR/ansible"
echo "   ansible-playbook -i inventory playbooks/k8s-deploy.yml \\"
echo "     --extra-vars \"build_number=1\""
echo ""

echo "6. Update Jenkins pipeline:"
echo "   Replace your existing jenkinsfile with jenkinsfile-ansible"
echo "   Configure Jenkins with the new pipeline parameters"
echo ""

echo "=== Configuration Summary ==="
echo "Docker Host: $DOCKER_HOST_IP"
echo "K8s Master: $K8S_MASTER_IP"
echo "K8s Workers: $K8S_WORKER1_IP, $K8S_WORKER2_IP"
echo "Jenkins Host: $JENKINS_HOST_IP"
echo "Docker Registry: $DOCKER_REGISTRY"
echo "Inventory file: $PROJECT_DIR/ansible/inventory"
echo "Vault password file: $PROJECT_DIR/ansible/vault_pass"
echo ""

echo "=== Quick Start completed! ==="
echo "Save the SSH public key and follow the next steps above."
