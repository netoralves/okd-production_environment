#!/bin/bash
oc login -u system:admin
oc new-app -n cicd -f lib-pipeline.yaml
