#!/bin/bash

sudo yum install -y java-1.8.0-openjdk-devel wget

#Add JAVA in PATH
echo "JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:bin/java::")" | sudo tee -a /etc/profile
source /etc/profile

# Download Maven
cd
wget http://www-us.apache.org/dist/maven/maven-3/3.5.4/binaries/apache-maven-3.5.4-bin.tar.gz
tar -zxvf apache-maven-3.5.4-bin.tar.gz

#Configure HOME_DIR and permissions and symLink
sudo mv ~/apache-maven-3.5.4 /opt
sudo chown -R root:root /opt/apache-maven-3.5.4
sudo ln -s /opt/apache-maven-3.5.4 /opt/apache-maven

#Add MAVEN in PATH
echo 'export PATH=$PATH:/opt/apache-maven/bin' | sudo tee -a /etc/profile
source /etc/profile
