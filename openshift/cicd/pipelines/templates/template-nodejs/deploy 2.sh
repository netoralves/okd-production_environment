#!/bin/bash
oc login https://sorento.ocb.org.br:8443 --token=3n2t23BzBAVieUIecUxD1RVGJF8whRHaEbiiniYjiwY
oc new-app -n cicd -f app-pipeline.yaml
