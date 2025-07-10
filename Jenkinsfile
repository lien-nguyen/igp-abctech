pipeline {
    agent any
    environment {
        ANSIBLE_HOST_KEY_CHECKING = 'False'
    }
    tools {
        maven 'Maven-3.9.10'
    }
    stages {
        stage('Code Checkout') {
            steps {
                echo 'Checking out code...'
                git branch: 'main', url: 'https://github.com/lien-nguyen/igp-abctech.git'
            }
        }
        stage('Code Compile') {
            steps {
                echo 'Compiling...'
                sh 'mvn compile'
            }
        }
        stage('Unit Test') {
            steps {
                echo 'Testing...'
                sh 'mvn test'
            }
        }
        stage('Code Packaging') {
            steps {
                echo 'Packaging...'
                sh 'mvn package'
            }
        }
        stage('Deploy to Docker (Tomcat) via Ansible') {
            steps {
                sh 'ansible-playbook -i ansible/inventory ansible/playbooks/docker_deploy.yml'
            }
        }
        stage('Deploy to Kubernetes via Ansible') {
            steps {
                sh 'ansible-playbook -i ansible/inventory ansible/playbooks/k8s_deploy.yml'
            }
        }
    }
    post {
        always {
            archiveArtifacts artifacts: 'target/*.war', fingerprint: true
        }
    }
}