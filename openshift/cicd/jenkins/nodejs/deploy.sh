#!/bin/bash
oc login -u system:admin
oc create -f jenkins-slave-nodejs-configmap.yaml -n cicd
