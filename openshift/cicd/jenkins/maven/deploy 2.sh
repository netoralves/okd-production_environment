#!/bin/bash
oc login -u system:admin
oc create -f jenkins-slave-maven-configmap.yaml -n cicd
