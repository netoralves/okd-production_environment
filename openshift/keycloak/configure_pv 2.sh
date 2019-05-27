#!/bin/bash

echo '"/exports/keycloak" *(rw,root_squash)' > /etc/exports.d/keycloak.exports
mkdir /exports/keycloak
chown nfsnobody:nfsnobody /exports/keycloak
chmod 777 /exports/keycloak

exportfs -va

oc login -u system:admin
oc create -f ./pv-keycloak.yml

