#!/bin/bash

oc login https://sorento.ocb.org.br:8443 --username=hmlg --password=ocb

oc new-app --template=openshift/postgresql-persistent --param=DATABASE_SERVICE_NAME=keycloak-postgresql --param=POSTGRESQL_USER=keycloak --param=POSTGRESQL_PASSWORD=keycloak@123 --param=POSTGRESQL_DATABASE=keycloak --param=VOLUME_CAPACITY=10Gi

oc new-app --docker-image=jboss/keycloak:latest -e DB_VENDOR=postgres -e DB_ADDR=keycloak-postgresql -e DB_DATABASE=keycloak -e DB_USER=keycloak -e DB_PASSWORD=keycloak@123 -e KEYCLOAK_USER=admin -e KEYCLOAK_PASSWORD=admin@123

oc expose svc keycloak
