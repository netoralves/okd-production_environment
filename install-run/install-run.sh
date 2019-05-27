#!/bin/bash

sudo yum -y install openshift-ansible

#Utilizar a versao 2.6.5 - 2.7.5 - incompativel com o parametro include_tasks
sudo yum downgrade -y ansible

#Bug registrado - atualizando filtro pra sanitizacao de pacotes
cat /usr/share/ansible/openshift-ansible/playbooks/init/base_packages.yml | grep python-docker-py &> /dev/null
if [ $? -ne 0 ]; then
	echo "Alterando o pacote python-docker -> python-docker-py..."
	sudo sed -i 's/python-docker/python-docker-py/g' /usr/share/ansible/openshift-ansible/playbooks/init/base_packages.yml
fi

ansible-playbook /usr/share/ansible/openshift-ansible/playbooks/prerequisites.yml
ansible-playbook /usr/share/ansible/openshift-ansible/playbooks/deploy_cluster.yml

oc adm policy add-cluster-role-to-user cluster-admin admin
