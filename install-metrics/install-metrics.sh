#!/bin/bash

IMAGE_VERSION="v3.11.0"
SCHEMA_VERSION="latest"

ansible-playbook /usr/share/ansible/openshift-ansible/playbooks/openshift-metrics/config.yml \
    -e openshift_metrics_install_metrics=True \
    -e openshift_metrics_cassandra_image=docker.io/openshift/origin-metrics-cassandra:$IMAGE_VERSION \
    -e openshift_metrics_hawkular_metrics_image=docker.io/openshift/origin-metrics-hawkular-metrics:$IMAGE_VERSION \
    -e openshift_metrics_schema_installer_image=docker.io/alv91/origin-metrics-schema-installer:$SCHEMA_VERSION \
    -e openshift_metrics_heapster_image=docker.io/openshift/origin-metrics-heapster:$IMAGE_VERSION
