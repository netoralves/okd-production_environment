# CI/CD - SonarQube
Este é o diretório com as configurações do SonarQube..


# Provisionamento do POD SonarQube
```
cd sonarqube/
#Provisionar um persistence volume para armazenamento do banco de dados
./configure_pv.sh

#Provisionar o Jenkins
./deploy.sh

```
