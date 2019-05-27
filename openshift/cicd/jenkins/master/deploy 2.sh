#!/bin/bash
oc login https://sorento.ocb.org.br:8443 --token=vlgrImgyIOoujjNSIia6FZ-Vcm1ICH2TiapfxLAWQoY
oc new-app jenkins-persistent -n cicd
