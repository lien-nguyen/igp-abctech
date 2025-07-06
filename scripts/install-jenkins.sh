# Install Java 17 on the machine (recommended for Jenkins)
sudo apt update
sudo apt install fontconfig openjdk-17-jdk
java -version

# Add JAVA_HOME to environment (commented out - not typically needed for Jenkins)
# echo 'export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64' >> ~/.bashrc
# echo 'export PATH=$JAVA_HOME/bin:$PATH' >> ~/.bashrc
# source ~/.bashrc

# Install Jenkins
sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update
sudo apt-get install jenkins

# Start and enable Jenkins service
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Check Jenkins status
sudo systemctl status jenkins

# Get initial admin password
echo "Initial Jenkins admin password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword