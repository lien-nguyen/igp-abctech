# Ansible Integration with Jenkins, Docker, and Kubernetes

This directory contains Ansible playbooks and configuration for automating the deployment of ABCtechnologies application to Docker containers and Kubernetes clusters.

## Directory Structure

```
ansible/
├── ansible.cfg                 # Ansible configuration
├── inventory                   # Inventory file with host definitions
├── vault_pass.template         # Template for vault password file
├── playbooks/
│   ├── docker-k8s-deploy.yml   # Used for Task 4 (Docker & K8s deployment)
│   ├── node_exporter_install_quick.yml # Used for monitoring setup
│   └── docker-deploy.yml       # Deploy to Docker containers (if needed)
└── templates/
    └── Dockerfile.j2           # Docker image template
```

## Prerequisites

1. **Ansible Control Node** (Usually Jenkins server):
   - Ansible installed
   - SSH access to target hosts
   - ansibleadmin user with SSH keys

2. **Target Hosts**:
   - Docker hosts for container deployment
   - Kubernetes cluster (master + workers)
   - ansibleadmin user with sudo privileges

## Setup Instructions

### 1. Install Ansible on Control Node


Run the installation script on EC2 Ansible control node:

```bash
sudo ./scripts/create_user.sh
```

This will:
- Install Ansible and required dependencies
- Create ansibleadmin user
- Generate SSH key pair
- Display public key to copy to target hosts

### 2. Setup Target Hosts

On each target host, run the setup script, for example:

```bash
# For Docker hosts
sudo ./scripts/setup-target-host.sh docker "ssh-rsa AAAAB3NzaC1yc2E... ansibleadmin@jenkins"
```

### 3. Configure Inventory

Edit the inventory file and replace placeholder IPs with actual host IPs:

```bash
cd ansible
cp inventory inventory.backup
nano inventory
```

Update these placeholders:
- `<DOCKER_HOST_IP>` - IP of Docker host
- `<K8S_MASTER_IP>` - IP of Kubernetes master
- `<K8S_WORKER1_IP>` - IP of first Kubernetes worker
- `<K8S_WORKER2_IP>` - IP of second Kubernetes worker
- `<JENKINS_HOST_IP>` - IP of Jenkins server

### 4. Setup Vault Password

Create the vault password file:

```bash
cd ansible
cp vault_pass.template vault_pass
nano vault_pass  # Replace with your actual password
chmod 600 vault_pass
```

### 5. Test Connectivity

Test SSH connectivity to all hosts:

```bash
cd ansible
ansible all -i inventory -m ping
```

## Playbooks


## Playbooks

### 1. docker_k8s_deploy.yml
Used for Task 4: Deploys application to Docker and Kubernetes cluster.

```bash
ansible-playbook -i inventory playbooks/docker_k8s_deploy.yml \
  --extra-vars "build_number=123"
```

### 2. node_exporter_install_quick.yml
Used for monitoring setup: Installs and configures Node Exporter on target hosts.

```bash
ansible-playbook -i inventory playbooks/node_exporter_install_quick.yml
```

### 3. docker_deploy.yml (optional - if you implement this step prior to implement k8s-stack)
Builds Docker image and deploys container to Docker hosts (if needed).

```bash
ansible-playbook -i inventory playbooks/docker_deploy.yml \
  --extra-vars "war_file_path=/path/to/ABCtechnologies-1.0.war" \
  --extra-vars "build_number=123"
```

## Jenkins Integration

### Pipeline Parameters

The Jenkins pipeline supports these parameters:

- `SETUP_HOSTS` - Setup Ansible managed hosts
- `DEPLOY_TO_K8S` - Deploy to Kubernetes
- `RUN_COMPLETE_PIPELINE` - Run complete CI/CD pipeline
- `PUSH_TO_DOCKERHUB` - Push images to Docker Hub
- `DOCKER_REGISTRY` - Docker Registry URL

### Usage in Jenkins

1. **Use the new pipeline file**: Copy `archived/jenkinsfile-ansible` to replace the existing `Jenkinsfile` in the project root

2. **Configure Jenkins credentials**:
   - Add SSH credentials for ansibleadmin
   - Add Docker Hub credentials if pushing to Docker Hub

3. **Run the pipeline**:
   - Check desired parameters
   - Run the build

## Kubernetes Resources

The deployment creates these Kubernetes resources:

- **Namespace**: `abctech`
- **Deployment**: `abctechnologies-deployment` (3 replicas)
- **Services**: 
  - `abctechnologies-service` (LoadBalancer)
  - `abctechnologies-nodeport` (NodePort: 30080)
- **ConfigMap**: `abctechnologies-config`

## Accessing the Application

### Docker Deployment
- Direct access: `http://<docker-host-ip>:8080`

### Kubernetes Deployment
- LoadBalancer: `http://<load-balancer-ip>:80`
- NodePort: `http://<any-node-ip>:30080`

## Troubleshooting

### Common Issues

1. **SSH Connection Failed**:
   ```bash
   # Test SSH manually
   ssh -i ~/.ssh/id_rsa ansibleadmin@<target-host-ip>
   
   # Check SSH key permissions
   ls -la ~/.ssh/
   ```

2. **Docker Permission Denied**:
   ```bash
   # Add user to docker group
   sudo usermod -aG docker ansibleadmin
   newgrp docker
   ```

3. **Kubernetes Connection Failed**:
   ```bash
   # Check kubeconfig
   kubectl --kubeconfig=/home/ansibleadmin/.kube/config get nodes
   ```

4. **Playbook Fails**:
   ```bash
   # Run with verbose output
   ansible-playbook -i inventory playbooks/docker-deploy.yml -vvv
   ```

### Log Files

- Ansible logs: `/var/log/ansible/ansible.log`
- Docker logs: `docker logs <container-name>`
- Kubernetes logs: `kubectl logs -n abctech <pod-name>`

## Best Practices

1. **Security**:
   - Use Ansible Vault for sensitive data
   - Rotate SSH keys regularly
   - Use non-root users for deployments

2. **Monitoring**:
   - Monitor deployed applications
   - Set up alerts for failures
   - Use health checks

3. **Scaling**:
   - Adjust Kubernetes replica counts
   - Use horizontal pod autoscaling
   - Monitor resource usage


## Notes

### Removed/Unused Playbooks
The following playbooks were previously included but are now ignored and not tracked in git:
- cicd-pipeline.yml
- setup-hosts.yml
- k8s-deploy.yml

These files are not part of the current solution and have been excluded for clarity and relevance.

For Task 4, I did not create separate pod and configmap manifest files for Kubernetes. This was mainly due to time constraints and the need to focus on automating the core monitoring stack and CI/CD setup. Only the essential configuration files (deployment.yaml and service.yaml) required for the main project tasks were included and tracked in the repository, as these are necessary for defining the application's deployment and service in the cluster. Unused or example manifests were ignored to keep the codebase clean and relevant.

### Monitoring
Prometheus and Grafana are set up using direct installation and systemd services, not Docker Compose. This approach was chosen to learn manual setup and service management. However, you can also use the provided docker-compose.yml file to set up these services if you prefer containerized deployment.

## Support

For issues or questions, check:
- Ansible documentation: https://docs.ansible.com/
- Kubernetes documentation: https://kubernetes.io/docs/
- Docker documentation: https://docs.docker.com/
