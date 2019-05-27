#!/bin/bash
oc login -u system:admin
oc new-app jenkins-persistent -n cicd
