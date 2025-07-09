# Ansible Integration with Jenkins, Docker, and Kubernetes

This directory contains Ansible playbooks and configuration for automating the deployment of ABCtechnologies application to Docker containers and Kubernetes clusters.

## Directory Structure

```
ansible/
├── ansible.cfg                 # Ansible configuration
├── inventory                   # Inventory file with host definitions
├── vault_pass.template         # Template for vault password file
├── playbooks/
│   ├── setup-hosts.yml         # Setup Docker and K8s hosts
│   ├── docker-deploy.yml       # Deploy to Docker containers
│   ├── k8s-deploy.yml          # Deploy to Kubernetes
│   └── cicd-pipeline.yml       # Complete CI/CD pipeline
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

Run the installation script on your Jenkins server:

```bash
cd /home/lien/edureka/igp-abctech
sudo ./scripts/install-ansible.sh
```

This will:
- Install Ansible and required dependencies
- Create ansibleadmin user
- Generate SSH key pair
- Display public key to copy to target hosts

### 2. Setup Target Hosts

On each target host, run the setup script:

```bash
# For Docker hosts
sudo ./scripts/setup-target-host.sh docker "ssh-rsa AAAAB3NzaC1yc2E... ansibleadmin@jenkins"

# For Kubernetes master
sudo ./scripts/setup-target-host.sh k8s-master "ssh-rsa AAAAB3NzaC1yc2E... ansibleadmin@jenkins"

# For Kubernetes workers
sudo ./scripts/setup-target-host.sh k8s-worker "ssh-rsa AAAAB3NzaC1yc2E... ansibleadmin@jenkins"
```

### 3. Configure Inventory

Edit the inventory file and replace placeholder IPs with actual host IPs:

```bash
cd ansible
cp inventory inventory.backup
nano inventory
```

Update these placeholders:
- `<DOCKER_HOST_IP>` - IP of your Docker host
- `<K8S_MASTER_IP>` - IP of your Kubernetes master
- `<K8S_WORKER1_IP>` - IP of first Kubernetes worker
- `<K8S_WORKER2_IP>` - IP of second Kubernetes worker
- `<JENKINS_HOST_IP>` - IP of your Jenkins server

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

### 1. setup-hosts.yml
Sets up Docker and Kubernetes hosts with required packages and configurations.

```bash
ansible-playbook -i inventory playbooks/setup-hosts.yml
```

### 2. docker-deploy.yml
Builds Docker image and deploys container to Docker hosts.

```bash
ansible-playbook -i inventory playbooks/docker-deploy.yml \
  --extra-vars "war_file_path=/path/to/ABCtechnologies-1.0.war" \
  --extra-vars "build_number=123"
```

### 3. k8s-deploy.yml
Deploys application to Kubernetes cluster.

```bash
ansible-playbook -i inventory playbooks/k8s-deploy.yml \
  --extra-vars "build_number=123"
```

### 4. cicd-pipeline.yml
Runs complete CI/CD pipeline (Docker + K8s deployment).

```bash
ansible-playbook -i inventory playbooks/cicd-pipeline.yml \
  --extra-vars "build_number=123" \
  --extra-vars "workspace=/var/lib/jenkins/workspace/ABCTech-Pipeline"
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

1. **Use the new pipeline file**: Copy `jenkinsfile-ansible` to replace your existing `jenkinsfile`

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

## Next Steps

1. **Implement monitoring** using Prometheus/Grafana (already configured)
2. **Add security scanning** to the pipeline
3. **Implement blue-green deployments**
4. **Add automated rollback** capabilities
5. **Configure log aggregation** (ELK stack)

## Support

For issues or questions, check:
- Ansible documentation: https://docs.ansible.com/
- Kubernetes documentation: https://kubernetes.io/docs/
- Docker documentation: https://docs.docker.com/
