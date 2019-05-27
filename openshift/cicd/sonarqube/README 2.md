# CI/CD - SonarQube
This is SonarQube configuration repository...


# Provision SonarQube POD
```
cd sonarqube/
#Provision a persistence volume to storage DB file.
./configure_pv.sh

#Provision
./deploy.sh

```
