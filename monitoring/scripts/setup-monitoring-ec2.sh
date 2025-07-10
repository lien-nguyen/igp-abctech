#!/bin/bash

# EC2 Monitoring Setup Script
# This script sets up comprehensive monitoring on EC2 instances

set -e

# Variables
MONITORING_DIR="/opt/monitoring"
DOCKER_COMPOSE_VERSION="2.38.0"

echo "=== EC2 Monitoring Setup Script ==="
echo "Setting up monitoring stack on EC2 instance"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)" 
   exit 1
fi

# Update system packages
echo "Updating system packages..."
apt-get update && apt-get upgrade -y

# Install required packages
echo "Installing required packages..."
apt-get install -y \
    curl \
    wget \
    git \
    htop \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release

# Install Docker
echo "Installing Docker..."
if ! command -v docker &> /dev/null; then
    # Install prerequisites
    apt-get update
    apt-get install -y ca-certificates curl gnupg
    
    # Create keyrings directory and add Docker's GPG key
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    # Add Docker repository
    echo \
      "deb [arch=$(dpkg --print-architecture) \
      signed-by=/etc/apt/keyrings/docker.gpg] \
      https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker Engine and Docker Compose plugin
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Start and enable Docker
    systemctl start docker
    systemctl enable docker
    
    # Add current user to docker group
    usermod -aG docker $USER
    
    echo "Docker installed successfully"
else
    echo "Docker is already installed"
fi
    fi
else
    echo "Docker is already installed"
fi

# Install Docker Compose (standalone)
echo "Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    curl -L "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    echo "Docker Compose installed successfully"
else
    echo "Docker Compose is already installed"
fi

# Configure Docker daemon for metrics
echo "Configuring Docker daemon for metrics..."
DOCKER_DAEMON_CONFIG="/etc/docker/daemon.json"
if [ ! -f "$DOCKER_DAEMON_CONFIG" ]; then
    mkdir -p /etc/docker
    cat > $DOCKER_DAEMON_CONFIG << 'EOF'
{
  "metrics-addr": "0.0.0.0:9323",
  "experimental": true,
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF
    systemctl restart docker
    echo "Docker daemon configured for metrics"
fi

# Create monitoring directory
echo "Creating monitoring directory..."
mkdir -p $MONITORING_DIR
cd $MONITORING_DIR

# Clone monitoring configuration
echo "Setting up monitoring configuration..."
if [ -d "/home/*/igp-abctech/monitoring" ]; then
    # If the monitoring config exists locally, copy it
    cp -r /home/*/igp-abctech/monitoring/* $MONITORING_DIR/
else
    # Create basic monitoring structure
    mkdir -p prometheus grafana/provisioning/{dashboards,datasources} scripts
    
    # Copy configurations if they exist in the current directory
    if [ -f "../monitoring/docker-compose.yml" ]; then
        cp ../monitoring/docker-compose.yml .
    fi
    if [ -f "../monitoring/prometheus/prometheus.yml" ]; then
        cp ../monitoring/prometheus/prometheus.yml prometheus/
    fi
    if [ -f "../monitoring/grafana/provisioning/datasources/datasource.yml" ]; then
        cp ../monitoring/grafana/provisioning/datasources/datasource.yml grafana/provisioning/datasources/
    fi
    if [ -f "../monitoring/grafana/provisioning/dashboards/dashboard.yml" ]; then
        cp ../monitoring/grafana/provisioning/dashboards/dashboard.yml grafana/provisioning/dashboards/
    fi
fi

# Set permissions
chown -R $USER:$USER $MONITORING_DIR

# Configure firewall (if ufw is enabled)
if command -v ufw &> /dev/null && ufw status | grep -q "Status: active"; then
    echo "Configuring firewall..."
    ufw allow 3000/tcp  # Grafana
    ufw allow 9090/tcp  # Prometheus
    ufw allow 9100/tcp  # Node Exporter
    ufw allow 8080/tcp  # cAdvisor
    ufw allow 9323/tcp  # Docker metrics
fi

# Install Node Exporter
echo "Installing Node Exporter..."
if [ -f "$MONITORING_DIR/scripts/install-node-exporter.sh" ]; then
    chmod +x $MONITORING_DIR/scripts/install-node-exporter.sh
    $MONITORING_DIR/scripts/install-node-exporter.sh
fi

# Start monitoring stack
echo "Starting monitoring stack..."
cd $MONITORING_DIR
if [ -f "docker-compose.yml" ]; then
    docker-compose up -d
    
    # Wait for services to start
    echo "Waiting for services to start..."
    sleep 30
    
    # Check service status
    echo "Checking service status..."
    docker-compose ps
else
    echo "Warning: docker-compose.yml not found in $MONITORING_DIR"
fi

# Display access information
INSTANCE_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || hostname -I | awk '{print $1}')

echo ""
echo "=== Monitoring Setup Complete ==="
echo "Services are now accessible at:"
echo "  Grafana:    http://$INSTANCE_IP:3000 (admin/admin)"
echo "  Prometheus: http://$INSTANCE_IP:9090"
echo "  cAdvisor:   http://$INSTANCE_IP:8080"
echo "  Node Exp:   http://$INSTANCE_IP:9100"
echo ""
echo "Monitoring files location: $MONITORING_DIR"
echo ""
echo "Useful commands:"
echo "  View logs:     cd $MONITORING_DIR && docker-compose logs -f"
echo "  Restart:       cd $MONITORING_DIR && docker-compose restart"
echo "  Stop:          cd $MONITORING_DIR && docker-compose down"
echo "  Update:        cd $MONITORING_DIR && docker-compose pull && docker-compose up -d"
echo ""
echo "Note: Change Grafana admin password after first login!"
