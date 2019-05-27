#!/bin/bash
# Autor: Francisco Neto netoralves@gmail.com
# SCRIPT PARA CONFIGURAR PERSISTENCE VOLUME DO SONARQUBE

echo '"/exports/jenkins-data" *(rw,root_squash)' > /etc/exports.d/jenkins.exports
mkdir /exports/jenkins-data
chown nfsnobody:nfsnobody /exports/jenkins-data
chmod 777 /exports/jenkins-data

exportfs -va

oc login -u system:admin
oc create -f ./pv-jenkins.yml
