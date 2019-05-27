#!/bin/bash
# Francisco Neto <netoralves@gmail.com>
# SCRIPT DE DEPLOY SONARQUBE NO PROJETO CICD
oc login https://sorento.ocb.org.br:8443 --token=vlgrImgyIOoujjNSIia6FZ-Vcm1ICH2TiapfxLAWQoY
oc new-app -f openshift-sonarqube-embedded-template --param=SONARQUBE_VERSION=7.0 --param=SONAR_MAX_MEMORY=3Gi -n cicd
