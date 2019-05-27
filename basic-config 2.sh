#!/bin/bash

if [ "$(hostname -s)" != "master" ]; then
    echo "Este script deve ser executado do host master"
    exit 1
fi

if [ "$(whoami)" != "root" ]; then
    echo "Este script deve ser executado como usuario root"
    exit 1
fi
#VARIAVEIS
MASTER="master.openshift.local"
NODE1="node1.openshift.local"
NODE2="node2.openshift.local"
USER="okd"
USER_PASS="okd@123"
ROOT_PASS="master_root_password"

#instalacao basica de pacotes para rodar o ansible
yum update -y
yum install -y sshpass centos-release-openshift-origin310 epel-release docker git pyOpenSSL glusterfs-fuse vim docker

# ADICIONAR UM USUARIO E DAR PRIVILEGIOS DE ROOT COM SUDO
#MASTER
echo "CRIACAO DO USUARIO $USER NO HOST $MASTER"
useradd $USER
(echo $USER_PASS ; echo $USER_PASS ) | passwd $USER &>/dev/null
echo "%$USER ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$USER
echo "[GERANDO CHAVE SSH] - POR FAVOR PRESSIONE <ENTER>"
su -c "ssh-keygen -N ''" - $USER

echo "REMOVE PERMISSÕES DE ACESSO VIA ROOT LOGIN"
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
echo "COPIANDO CHAVE PARA ACESSO VIA SSH LOCAL"
su -c "sshpass -p $USER_PASS ssh-copy-id -o 'StrictHostKeyChecking no' $MASTER" - $USER

#LACO PARA CRIAR O USUARIO E COPIAR A CHAVE INSERIR TODOS OS NODES NO LACO 
for host in $NODE1 $NODE2;
do
# CRIA O USUARIO DANDO PRIVILEGIOS DE ROOT | DEFINE SUA SENHA DE ACESSO | REMOVE O ACESSO DIRETO DO USUARIO ROOT | COPIA A CHAVE SSH DO USUARIO $USER DO HOST MASTER
echo "CRIACAO E CONFIGURACAO DO USUARIO $USER NO HOST $host"
sshpass -p $ROOT_PASS ssh -o StrictHostKeyChecking=no root@$host "useradd $USER && echo '%"$USER" ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/$USER && ( echo $USER_PASS ; echo $USER_PASS ) | passwd $USER &>/dev/null && sed -i 's/#PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config"

echo "COPIANDO A CHAVE SSH DO HOST $MASTER PARA O HOST $host"
su -c "sshpass -p $USER_PASS ssh-copy-id -o StrictHostKeyChecking=no $host" - $USER

echo "ATUALIZANDO PACOTES DO HOST $host"
su -c "ssh $host -o StrictHostKeyChecking=no sudo yum update -y" - $USER
su -c "ssh $host -o StrictHostKeyChecking=no sudo yum install -y centos-release-openshift-origin310 epel-release docker git pyOpenSSL glusterfs-fuse vim" - $USER
echo " "
done

yum update -y
yum install -y ansible

# BACKUP ANSIBLE
rsync -zvh /etc/ansible/hosts /etc/ansible/hosts_DEFAULT
rsync -zvh /etc/ansible/ansible.cfg /etc/ansible/ansible.cfg_DEFAULT

# ARQUIVO CUSTOM ANSIBLE
rsync -zvh /root/OPENSHIFTORIGIN/templates/hosts /etc/ansible/hosts
rsync -zvh /root/OPENSHIFTORIGIN/templates/ansible.cfg /etc/ansible/ansible.cfg

rsync -avzh /root/OPENSHIFTORIGIN/install-prepare /home/$USER/
rsync -avzh /root/OPENSHIFTORIGIN/install-run /home/$USER/
rsync -avzh /root/OPENSHIFTORIGIN/install-metrics /home/$USER/
touch /etc/ansible/ansible.log
chown $USER:$USER /home/$USER -R
chown $USER:$USER /etc/ansible/ansible.log
mkdir -p /etc/cni/net.d

#echo "EXECUTANDO PLAYBOOK INSTALL-PREPARE" 
#su -c "ansible-playbook ~/install-prepare/install-prepare.yml" - $USER
