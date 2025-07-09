# Monitoring Stack for ABCtechnologies

This directory contains a complete monitoring solution for the ABCtechnologies Java web application using Prometheus, Grafana, Node Exporter, and cAdvisor.

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│    Grafana      │    │   Prometheus    │    │  Node Exporter  │
│   Dashboard     │◄───┤   Monitoring    │◄───┤   Host Metrics  │
│   (Port 3000)   │    │   (Port 9090)   │    │   (Port 9100)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │    cAdvisor     │
                       │ Container Metrics│
                       │   (Port 8080)   │
                       └─────────────────┘
```

## Components

### 1. Prometheus
- **Port**: 9090
- **Purpose**: Metrics collection and storage
- **Configuration**: `prometheus/prometheus.yml`

### 2. Grafana
- **Port**: 3000
- **Purpose**: Visualization and dashboards
- **Default Login**: admin/admin
- **Configuration**: `grafana/provisioning/`

### 3. Node Exporter
- **Port**: 9100
- **Purpose**: Host system metrics (CPU, memory, disk, network)

### 4. cAdvisor
- **Port**: 8080
- **Purpose**: Container metrics and resource usage

## Quick Start

### Using Docker Compose (Recommended)

1. **Start the monitoring stack**:
   ```bash
   cd monitoring
   docker-compose up -d
   ```

2. **Access services**:
   - Grafana: http://localhost:3000 (admin/admin)
   - Prometheus: http://localhost:9090
   - cAdvisor: http://localhost:8080
   - Node Exporter: http://localhost:9100

3. **Stop the monitoring stack**:
   ```bash
   docker-compose down
   ```

### EC2 Setup

For AWS EC2 instances, use the automated setup script:

```bash
sudo ./scripts/setup-monitoring-ec2.sh
```

This script will:
- Install Docker and Docker Compose
- Configure Docker daemon for metrics
- Set up firewall rules
- Install Node Exporter as a system service
- Start the monitoring stack

### Manual Node Exporter Installation

For standalone Node Exporter installation:

```bash
sudo ./scripts/install-node-exporter.sh
```

## Configuration Files

### Prometheus Configuration (`prometheus/prometheus.yml`)
- Defines scrape targets and intervals
- Configures data retention and alerting rules
- Targets include: Prometheus itself, Node Exporter, cAdvisor, Docker daemon, Java app, Jenkins

### Grafana Datasource (`grafana/provisioning/datasources/datasource.yml`)
- Auto-configures Prometheus as the default datasource
- Sets up connection to Prometheus service

### Grafana Dashboards (`grafana/provisioning/dashboards/dashboard.yml`)
- Configures dashboard provisioning
- Enables dashboard imports and updates

### Docker Daemon Metrics (`docker-daemon-metrics.json`)
- Configuration for Docker daemon to expose metrics
- Should be placed in `/etc/docker/daemon.json` on the host

## Metrics Endpoints

| Service | Endpoint | Purpose |
|---------|----------|---------|
| Prometheus | http://localhost:9090/metrics | Prometheus internal metrics |
| Node Exporter | http://localhost:9100/metrics | Host system metrics |
| cAdvisor | http://localhost:8080/metrics | Container metrics |
| Docker Daemon | http://localhost:9323/metrics | Docker engine metrics |
| Java App | http://localhost:8081/actuator/prometheus | Application metrics (if configured) |

## Monitoring Targets

### System Metrics
- CPU usage and load average
- Memory usage and swap
- Disk usage and I/O
- Network traffic and errors
- System uptime and boot time

### Container Metrics
- Container CPU and memory usage
- Container network and disk I/O
- Container lifecycle events
- Resource limits and requests

### Application Metrics (if configured)
- JVM metrics (heap, garbage collection)
- HTTP request metrics
- Database connection pools
- Custom business metrics

### Jenkins Metrics (if available)
- Build success/failure rates
- Queue lengths
- Job execution times
- Node utilization

## Grafana Dashboard Setup

1. **Login to Grafana**: http://localhost:3000 (admin/admin)
2. **Import popular dashboards**:
   - Node Exporter Full: Dashboard ID `1860`
   - Docker and System Monitoring: Dashboard ID `893`
   - JVM Micrometer: Dashboard ID `4701`
   - Jenkins Performance and Health: Dashboard ID `9964`

3. **Create custom dashboards** for your Java application metrics

## Troubleshooting

### Services not starting
```bash
# Check service status
docker-compose ps

# View service logs
docker-compose logs prometheus
docker-compose logs grafana

# Restart services
docker-compose restart
```

### Prometheus not scraping targets
1. Check `prometheus/prometheus.yml` configuration
2. Verify target endpoints are accessible
3. Check Prometheus logs: `docker-compose logs prometheus`
4. Visit Prometheus UI → Status → Targets

### Grafana connection issues
1. Verify Prometheus is running: `docker-compose ps`
2. Check datasource configuration in Grafana
3. Test connection: Grafana → Configuration → Data Sources → Test

### Node Exporter not responding
```bash
# Check if Node Exporter is running
sudo systemctl status node_exporter

# Restart Node Exporter
sudo systemctl restart node_exporter

# Check logs
sudo journalctl -u node_exporter -f
```

## Security Considerations

1. **Change default passwords**: Update Grafana admin password
2. **Network security**: Configure firewall rules appropriately
3. **Authentication**: Set up proper authentication for production
4. **TLS/SSL**: Enable HTTPS for production deployments
5. **Data retention**: Configure appropriate data retention policies

## Maintenance

### Regular Tasks
- Monitor disk usage for metrics storage
- Update dashboard configurations
- Review and update alerting rules
- Backup Grafana dashboards and configurations

### Updates
```bash
# Update container images
docker-compose pull

# Restart with updated images
docker-compose up -d
```

## Integration with CI/CD

To integrate with your Jenkins pipeline:

1. **Add monitoring steps** to `jenkinsfile`
2. **Configure Jenkins Prometheus plugin**
3. **Set up alerting** for build failures
4. **Monitor deployment metrics**

## Support

For issues and questions:
1. Check the logs: `docker-compose logs -f`
2. Verify configurations in the respective files
3. Ensure all ports are accessible and not blocked by firewall
4. Check Docker and Docker Compose versions
