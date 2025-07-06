#!/bin/bash

# https://maven.apache.org/install.html
# https://maven.apache.org/download.cgi

# sudo -su i 

# Install maven from the opt directory
cd /opt 
wget https://dlcdn.apache.org/maven/maven-3/3.9.10/binaries/apache-maven-3.9.10-bin.tar.gz

# Extract the downloaded tar file
tar -xvzf apache-maven-3.9.10-bin.tar.gz

# Rename directory for easier management
mv apache-maven-3.9.10 maven

# Remove the downloaded tar file to save space
# rm apache-maven-3.9.10-bin.tar.gz

# Add environment variables to user's .profile (preferred approach)
echo "" >> ~/.profile
echo "# Add environments for Java, Maven" >> ~/.profile
echo "export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64" >> ~/.profile
echo "export M2_HOME=/opt/maven" >> ~/.profile
echo "export M2=/opt/maven/bin" >> ~/.profile
echo "export PATH=\$PATH:\$HOME/bin:\$JAVA_HOME/bin:\$M2" >> ~/.profile

# Alternative: Add system-wide environment variables (uncomment if needed)
# echo "" >> /etc/profile
# echo "# Add environments for Java, Maven" >> /etc/profile
# echo "export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64" >> /etc/profile
# echo "export M2_HOME=/opt/maven" >> /etc/profile
# echo "export M2=/opt/maven/bin" >> /etc/profile
# echo "export PATH=\$PATH:\$HOME/bin:\$JAVA_HOME/bin:\$M2" >> /etc/profile

# Reload the .profile to apply changes
source ~/.profile

# Verify installation
echo "Maven installation completed!"
echo "Verifying Maven installation:"
/opt/maven/bin/mvn -version