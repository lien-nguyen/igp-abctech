#!/bin/bash

# Node Exporter Installation Script

set -e

# Variables
NODE_EXPORTER_VERSION="1.6.1"
NODE_EXPORTER_USER="node_exporter"
NODE_EXPORTER_HOME="/opt/node_exporter"
SERVICE_FILE="/etc/systemd/system/node_exporter.service"

echo "=== Node Exporter Installation Script ==="
echo "Version: ${NODE_EXPORTER_VERSION}"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)" 
   exit 1
fi

# Update system packages
echo "Updating system packages..."
apt-get update

# Create node_exporter user
echo "Creating node_exporter user..."
if ! id "$NODE_EXPORTER_USER" &>/dev/null; then
    useradd --no-create-home --shell /bin/false $NODE_EXPORTER_USER
fi

# Create directories
echo "Creating directories..."
mkdir -p $NODE_EXPORTER_HOME
mkdir -p /var/lib/node_exporter

# Download and install Node Exporter
echo "Downloading Node Exporter..."
cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz

echo "Extracting Node Exporter..."
tar xzf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz

echo "Installing Node Exporter..."
cp node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter $NODE_EXPORTER_HOME/
chown -R $NODE_EXPORTER_USER:$NODE_EXPORTER_USER $NODE_EXPORTER_HOME
chown -R $NODE_EXPORTER_USER:$NODE_EXPORTER_USER /var/lib/node_exporter

# Create systemd service file
echo "Creating systemd service..."
cat > $SERVICE_FILE << EOF
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=$NODE_EXPORTER_USER
Group=$NODE_EXPORTER_USER
Type=simple
ExecStart=$NODE_EXPORTER_HOME/node_exporter \\
    --collector.systemd \\
    --collector.processes \\
    --web.listen-address=:9100

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
echo "Enabling and starting Node Exporter service..."
systemctl daemon-reload
systemctl enable node_exporter
systemctl start node_exporter

# Check service status
echo "Checking service status..."
systemctl status node_exporter --no-pager

# Cleanup
echo "Cleaning up..."
rm -rf /tmp/node_exporter-*

# Open firewall port (if ufw is enabled)
if command -v ufw &> /dev/null; then
    echo "Opening firewall port 9100..."
    ufw allow 9100/tcp
fi

echo ""
echo "=== Installation Complete ==="
echo "Node Exporter is now running on port 9100"
echo "You can access metrics at: http://$(hostname -I | awk '{print $1}'):9100/metrics"
echo ""
echo "Service commands:"
echo "  Start:   sudo systemctl start node_exporter"
echo "  Stop:    sudo systemctl stop node_exporter"
echo "  Status:  sudo systemctl status node_exporter"
echo "  Logs:    sudo journalctl -u node_exporter -f"
