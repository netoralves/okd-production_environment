#!/bin/bash
oc login -u user_limpeza -p limpaImagens@123

#CI/CD PROJECT
oc adm prune builds --orphans --keep-complete=10 --keep-failed=1 --keep-younger-than=60m --confirm -n cicd
oc adm prune deployments --orphans --keep-complete=10 --keep-failed=1 --keep-younger-than=60m --confirm -n cicd

#HMLG PROJECT
oc adm prune builds --orphans --keep-complete=10 --keep-failed=1 --keep-younger-than=60m --confirm -n hmlg
oc adm prune deployments --orphans --keep-complete=10 --keep-failed=1 --keep-younger-than=60m --confirm -n hmlg

#CLEAN IMAGES
oc adm prune images --keep-tag-revisions=3 --keep-younger-than=60m --confirm
oc adm prune images --prune-over-size-limit --confirm
