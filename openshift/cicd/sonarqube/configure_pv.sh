#!/bin/bash
# Autor: Francisco Neto netoralves@gmail.com
# SCRIPT PARA CONFIGURAR PERSISTENCE VOLUME DO SONARQUBE

echo '"/exports/sonarqube-data" *(rw,root_squash)' > /etc/exports.d/sonarqube.exports
mkdir /exports/sonarqube-data
chown nfsnobody:nfsnobody /exports/sonarqube-data
chmod 777 /exports/sonarqube-data

exportfs -va

oc login -u system:admin
oc create -f ./pv-sonarqube.yml
