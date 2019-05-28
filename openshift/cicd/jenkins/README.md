# CI/CD - Jenkins
Este é o diretório com as configurações do Jenkins Master, Jenkins Slave Maven e NodeJS.


# Jenkins Master
```
cd master/
#Provisionar um persistence volume para armazenamento do banco de dados
./configure_pv.sh

#Provisionar o Jenkins
./deploy.sh

```
# Jenkins Slave - Maven

```
#Provisionar o ConfigMap do jenkins Slave Maven
cd maven/
./deploy.sh
```

# Jenkins Slave - NodeJS
```
# Provisionar o ConfigMap do Jenkins Slave NodeJS
./deploy.sh
```
