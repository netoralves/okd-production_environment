#!/bin/bash

if [ "$(hostname -s)" != "master1" ]; then
    echo "This script must be executed on host master1"
    exit 1
fi

if [ "$(whoami)" != "root" ]; then
    echo "This script must be executed as root user"
    exit 1
fi
#VARIABLES

#==============================
#MASTERS
MASTER1="master1"
MASTER2="master2"
MASTER3="master3"
#==============================

#==============================
#NODES INFRA
NODE1_INFRA="node1"
NODE2_INFRA="node2"
NODE3_INFRA="node3"
#==============================

#==============================
#NODES APP
NODE1_COMPUTE="node4"
NODE2_COMPUTE="node5"
#==============================

#==============================
#LOADBALANCER
LB1="lb1"
LB2="lb2"
#==============================

USER="okd"
USER_PASS="password"
ROOT_PASS="root_password"
OPENSHIFT_PACKAGE="centos-release-openshift-origin311"

# INSTALL BASIC PACKS
yum update -y
yum install -y $OPENSHIFT_PACKAGE sshpass epel-release docker git pyOpenSSL glusterfs-fuse vim docker

# ADD A USER AND GRANT PRIVILEGIES
#MASTER
useradd -G root $USER
(echo $USER_PASS ; echo $USER_PASS ) | passwd $USER &>/dev/null
echo "%$USER ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$USER

echo "[GENERATE SSH KEY] - Please Press <ENTER>"
su -c "ssh-keygen -N ''" - $USER

echo "REMOVE ACCESS PERMISSION ON DIRECT ROOT LOGIN"
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
echo "COPY SSH KEY"
su -c "sshpass -p $USER_PASS ssh-copy-id -o 'StrictHostKeyChecking no' $MASTER1" - $USER

for host in $MASTER2 $MASTER3 $LB1 $LB2 $NODE1_INFRA $NODE2_INFRA $NODE3_INFRA $NODE1_COMPUTE $NODE2_COMPUTE;
do
echo "CREATE A CONFIG FROM USER $USER ON $host"
sshpass -p $ROOT_PASS ssh -o StrictHostKeyChecking=no root@$host "useradd -G root $USER && echo '%"$USER" ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/$USER && ( echo $USER_PASS ; echo $USER_PASS ) | passwd $USER &>/dev/null && sed -i 's/#PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config"

echo "COPY SSH KEY FROM $MASTER1 TO $host"
su -c "sshpass -p $USER_PASS ssh-copy-id -o StrictHostKeyChecking=no $host" - $USER

echo "UPDATE PACKAGES ON $host"
su -c "ssh $host -o StrictHostKeyChecking=no sudo yum update -y" - $USER

VALIDA_HOST=$(su -c "ssh $host -o StrictHostKeyChecking=no hostname" - $USER)
if [[ ( "$VALIDA_HOST" = "$LB1" ) || ( "$VALIDA_HOST" = "$LB2" ) ]]; then
	# PACOTES PARA O HA PROXY - LOAD BALANCE
	su -c "ssh $host -o StrictHostKeyChecking=no sudo yum install -y  epel-release git pyOpenSSL vim keepalived psmisc" - $USER
else
	su -c "ssh $host -o StrictHostKeyChecking=no sudo yum install -y $OPENSHIFT_PACKAGE epel-release docker git pyOpenSSL glusterfs-fuse vim" - $USER
fi
echo " "
done

yum update -y
yum install -y ansible

# BACKUP ANSIBLE
rsync -zvh /etc/ansible/hosts /etc/ansible/hosts_DEFAULT
rsync -zvh /etc/ansible/ansible.cfg /etc/ansible/ansible.cfg_DEFAULT

# CUSTOM FILE ANSIBLE
rsync -zvh /root/OPENSHIFTORIGIN/templates/hosts /etc/ansible/hosts
rsync -zvh /root/OPENSHIFTORIGIN/templates/ansible.cfg /etc/ansible/ansible.cfg

rsync -avzh /root/OPENSHIFTORIGIN/install-prepare /home/$USER/
rsync -avzh /root/OPENSHIFTORIGIN/install-run /home/$USER/
rsync -avzh /root/OPENSHIFTORIGIN/install-metrics /home/$USER/
rsync -avzh /root/OPENSHIFTORIGIN/scripts /home/$USER/

touch /etc/ansible/ansible.log
chown $USER:$USER /home/$USER -R
chown $USER:$USER /etc/ansible/ansible.log
