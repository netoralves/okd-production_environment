# CI/CD - Jenkins
This is CI/CD repository to jenkins Master, Jenkins Slave Maven and NodeJS.

# Jenkins Master
```
cd master/
#Provision a persistence volume to storage jenkins config
./configure_pv.sh

#Provisio a Jenkins Master
./deploy.sh

```
# Jenkins Slave - Maven

```
#Provision a ConfigMap to Jenkins Slave Maven - (Kubernetes Plugin)
cd maven/
./configure_pv.sh
./deploy.sh
```
Obs. This config use persistence volume to optimize deploy

# Jenkins Slave - NodeJS
```
# Provisionar o ConfigMap do Jenkins Slave NodeJS
./deploy.sh
```
