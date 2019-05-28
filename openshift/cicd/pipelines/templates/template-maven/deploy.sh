#!/bin/bash
oc login -u system:admin
oc new-app -n cicd -f @app@-pipeline.yaml
