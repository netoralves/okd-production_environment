#!/bin/bash

sudo yum -y install openshift-ansible

ansible-playbook /usr/share/ansible/openshift-ansible/playbooks/prerequisites.yml
ansible-playbook /usr/share/ansible/openshift-ansible/playbooks/deploy_cluster.yml

oc adm policy add-cluster-role-to-user cluster-admin admin
