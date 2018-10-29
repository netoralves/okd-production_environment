#!/bin/bash

echo '"/exports/maven-data" *(rw,root_squash)' > /etc/exports.d/maven.exports
mkdir -p /exports/maven-data
chown nfsnobody:nfsnobody /exports/maven-data
chmod 777 /exports/maven-data

exportfs -va

oc login -u system:admin
oc create -f ./pv-maven.yml
