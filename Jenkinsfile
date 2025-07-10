pipeline {
    agent any
    environment {
        ANSIBLE_HOST_KEY_CHECKING = 'False'
    }
    tools {
        maven 'Maven-3.9.10'
    }
    stages {
        stage('Deploy to Docker via Ansible') {
            steps {
                sh 'ansible-playbook -i ansible/inventory ansible/playbooks/docker_deploy.yml'
            }
        }
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
        stage('Docker Build & Push') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', 
                                                    passwordVariable: 'DOCKER_PASSWORD', 
                                                    usernameVariable: 'DOCKER_USERNAME')]) {
                        sh '''
                            docker build -t ${DOCKER_USERNAME}/abc-tomcat-app:latest -f Dockerfile .
                            echo ${DOCKER_PASSWORD} | docker login -u ${DOCKER_USERNAME} --password-stdin
                            docker push ${DOCKER_USERNAME}/abc-tomcat-app:latest
                        '''
                    }
                }
            }
        }
        stage('Deploy to Kubernetes via Ansible') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', 
                                                passwordVariable: 'DOCKER_PASSWORD', 
                                                usernameVariable: 'DOCKER_USERNAME')]) {
                        sh '''
                            ansible-playbook -i ansible/inventory ansible/playbooks/docker_k8s_deploy.yml \
                            --extra-vars "dockerhub_username=${DOCKER_USERNAME} dockerhub_password=${DOCKER_PASSWORD}"
                        '''
                    }
                }
            }
        }
    }
    post {
        always {
            archiveArtifacts artifacts: 'target/*.war', fingerprint: true
        }
    }
}