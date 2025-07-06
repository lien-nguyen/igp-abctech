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

# Add environment variables to .bashrc
echo "" >> ~/.bashrc
echo "# Add environments for Java, Maven" >> ~/.bashrc
echo "JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64" >> ~/.bashrc
echo "M2_HOME=/opt/maven" >> ~/.bashrc
echo "M2=/opt/maven/bin" >> ~/.bashrc
echo "" >> ~/.bashrc
echo "PATH=\$PATH:\$HOME/bin:\$JAVA_HOME/bin:\$M2" >> ~/.bashrc

# Reload the .bashrc to apply changes
source ~/.bashrc

# Verify installation
echo "Maven installation completed!"
echo "Verifying Maven installation:"
/opt/maven/bin/mvn -version