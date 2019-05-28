# Deploy the STAGE(HMLG) and PRD environment with OKD 3.11
Documentation of deploy based on bash scripts and playbooks.

## Architecture

![](images/topologia2.png?raw=true)

## Config Management

### Inventory
Hostname | IP Address | Function | Proc | Memory | Disk
--- | --- | --- | --- | --- | ---
MASTER1 | 192.168.0.12 | Master + NFS Server (etcd) + Gluster Server + Gluster Volume (app-storage) | 8 Cores | 16 GB | 60GB /dev/sda - S.O / 20GB /dev/sdb - Docker-storage / 80GB /dev/sdc - GlusterFS
MASTER2 | 192.168.0.13 | Master + Gluster Server + Gluster Volume (infra-storage) | 8 Cores | 16 GB | 60GB /dev/sda - S.O / 20GB /dev/sdb - Docker-storage / 80GB /dev/sdc - GlusterFS
MASTER3 | 192.168.0.14 | Master + Gluster Server + Gluster Volume (app-storage) | 8 Cores | 16 GB | 60GB /dev/sda - S.O / 20GB /dev/sdb - Docker-storage / 80GB /dev/sdc - GlusterFS
NODE1 | 192.168.0.15 | Infra Node + Gluster Server + Gluster Volume (infra-storage) | 8 Cores | 16 GB | 60GB /dev/sda - S.O / 20GB /dev/sdb - Docker-storage / 80GB /dev/sdc - GlusterFS
NODE2 | 192.168.0.16 | Infra Node + Gluster Server + Gluster Volume (infra-storage) | 8 Cores | 16 GB | 60GB /dev/sda - S.O / 20GB /dev/sdb - Docker-storage / 80GB /dev/sdc - GlusterFS
NODE3 | 192.168.0.17 | Infra Node + Gluster Server + Gluster Volume (infra-storage) | 8 Cores |  16 GB | 60GB /dev/sda - S.O / 20GB /dev/sdb - Docker-storage / 80GB /dev/sdc - GlusterFS
NODE4 | 192.168.0.18 | Compute Node + Gluster Server + Gluster Volume (app-storage) | 8 Cores | 16 GB | 60GB /dev/sda - S.O / 20GB /dev/sdb - Docker-storage / 80GB /dev/sdc - GlusterFS
NODE5 | 192.168.0.19 | Compute Node + Gluster Server + Gluster Volume (app-storage) | 8 Cores | 16 GB | 60GB /dev/sda - S.O / 20GB /dev/sdb - Docker-storage / 80GB /dev/sdc - GlusterFS
LB1 | 192.168.0.10 | Load Balancer | 8 Cores | 16 GB | 60GB /dev/sda - S.O
LB2 | 192.168.0.11 | Load Balancer | 8 Cores | 16 GB | 60GB /dev/sda - S.O


### Topologia DNS

Resolução de Nome 	  | 	IP 	    | Hosts
--- 			  | 	--- 	    | ---
master-okd.yourdomain.com | xxx.xxx.xxx.xxx | VIP (keepalived) LB1 AND LB2
okd.yourdomain.com	  | xxx.xxx.xxx.xxx | VIP (keepalived) LB1 AND LB2
.cloudapps.yourdomain.com | xxx.xxx.xxx.xxx / xxx.xxx.xxx.xxx | NODE3 / NODE4

### Keepalived

![](images/keepalived.png?raw=true)


### URLs
URI | Descrição
--- | ---
https://okd.yourdomain.com:8443/console/ | Web Console UI
https://console.cloudapps.yourdomain.com | Cluster Console
https://grafana-openshift-monitoring.cloudapps.yourdomain.com | Dashboards - Monitor
https://prometheus-k8s-openshift-monitoring.cloudapps.yourdomain.com | Datasource Dashboards
https://console.cloudapps.yourdomain.com/status/all-namespaces | Cluster Overview
https://console.cloudapps.yourdomain.com/k8s/all-namespaces/events | Overview of last register events
http://okd.yourdomain.com:9000				       | status of external LB
http://node4.yourdomain.com:1936			       | status of internal router
http://node5.yourdomain.com:1936			       | status of internal router

## Requirements
Install procedure performed  on 10 hosts with S.O CentOS

```
CentOS Linux release 7.6.1810 (Core)
```
## Installation

The related Playbooks was manented on ansible / playbooks project directory, and contains basically the following content:

• Ansible Configuration file (ansible.cfg)
• A playbooks directory.
• Inventory file (inventory.ini).

1. Make checkout of this repository on root directory:
```
git clone https://github.com/netoralves/okd-production_environment.git
```
Note: If it is necessary to install the git package to perform the repository clone.

2. Execute the basic_config.sh script:

2.1. Validate the configured variables in the script header:
* There is a restriction for the script to run on the MASTER1 machine (master) and the running user is root.
* The variables must be validated for the environment, following the configuration model provisioned for the HMLG and PRD environment:


```
	MASTER1="MASTER1"
	MASTER2="MASTER2"
	MASTER3="MASTER3"
	NODE1_INFRA="NODE1"
	NODE2_INFRA="NODE2"
	NODE3_INFRA="NODE3"
	NODE1_COMPUTE="NODE4"
	NODE2_COMPUTE="NODE5"
	LB1="LB1"
	LB2="LB2"
	USER="okd"
	USER_PASS="password"
	ROOT_PASS="password"
	OPENSHIFT_PACKAGE="centos-release-openshift-origin311"
```

1.2. After validating the variables execute the script, it will validate the following configurations:
  * Creating a local user with root privileges that will be used by ansible (become)
  * Creating a user on each node with the same privileges
  * Copy ssh key between users created in all nos (for master access without password)
  * Generates the root user's ssh key (which will be used by the playbook)
  * Updates the packages of all cluster hosts
  * Install ansible on master host

```
    ./basic_config.sh
```

3. Restart the 10 machines.

```
su - okd

ssh lb1 sudo systemctl reboot
ssh lb2 sudo systemctl reboot
ssh master2 sudo systemctl reboot
ssh master3 sudo systemctl reboot
ssh node1 sudo systemctl reboot
ssh node2 sudo systemctl reboot
ssh node3 sudo systemctl reboot
ssh node4 sudo systemctl reboot
ssh node5 sudo systemctl reboot
ssh master1 sudo systemctl reboot
```

4. Validation of access to hosts without password request by user okd (with the exception of Load Balancer)

``` 
[okd@MASTER1 ~]$ ssh master2
[okd@MASTER1 ~]$ ssh master3
[okd@MASTER1 ~]$ ssh node1
[okd@MASTER1 ~]$ ssh node2
[okd@MASTER1 ~]$ ssh node3
[okd@MASTER1 ~]$ ssh node4
[okd@MASTER1 ~]$ ssh node5
```

4.2. verify the ansible version
```
[okd@MASTER1 ~]$ ansible --version
ansible 2.6.5
```

5. Access the host master to execute the follow command:

```
ssh okd@master1
cd install-prepare/
[okd@MASTER1 install-run]$ ansible-playbook install-prepare.yml

cd ../install-run/
[okd@MASTER1 install-run]$ ./install-run.sh
```
# Administration

## User ang grant access table

### Usuários do S.O
Usuário | Descrição | Senha
--- | --- | ---
okd | user with root privilegies (sudo) | password
root | root | password

### OKD Users
Users | Description | Password
--- | --- | ---
admin | Admin Cluster  | admin@123
hmlg  | Project admin: hmlg; Project view: cicd | hmlg@123
prd   | Project admin: prd; Project view: cicd | prd@123
integracao | Project admin: cicd; Project view: hmlg, prd | ocb@123


## Prune policy builds and deployments

* Delete all deployments whose deployment configuration no longer exists, the status is complete or failed, and the replica count is zero.
* By deployment configuration, keep the latest N deployments whose status is complete and the replica count is zero. (Default 5)
* By deployment configuration, keep the latest N deployments whose status has been deprecated and the replica count is zero. (Default 1)

1. To CICD Project
* Keep the last 10 builds and deployments that have been successfully completed, keep 1 that has failed, and maintain a 60minute build or deployment minimum if it meets one of the purge requirements quoted above.
```
[okd@MASTER1 ~]$ oc adm prune builds --orphans --keep-complete=10 --keep-failed=1 --keep-younger-than=60m --confirm -n cicd
[okd@MASTER1 ~]$ oc adm prune deployments --orphans --keep-complete=10 --keep-failed=1 --keep-younger-than=60m --confirm -n cicd
```

2. To HMLG Project
* Keep the last 10 builds and deployments that have been successfully completed, keep 1 that has failed, and maintain a build or deployment for at least 60 minutes if it meets one of the purge requirements listed above.
```
[okd@MASTER1 ~]$ oc adm prune builds --orphans --keep-complete=10 --keep-failed=1 --keep-younger-than=60m --confirm -n hmlg
[okd@MASTER1 ~]$ oc adm prune deployments --orphans --keep-complete=10 --keep-failed=1 --keep-younger-than=60m --confirm -n hmlg
```

3. Images clean up
* Keep up to three tag revisions and keep resources (images, image streams and pods) less than sixty minutes, and clean any image that exceeds the defined limits.
```
[okd@MASTER1 ~]$ oc adm prune images --keep-tag-revisions=3 --keep-younger-than=60m --confirm
[okd@MASTER1 ~]$ oc adm prune images --prune-over-size-limit --confirm
```

## Backup Policy

Creating a full backup environment involves copying important data to assist in restoring in the event of failed instances or corrupted data. After backups are created, they can be restored in a newly installed version of the relevant component.


On OKD, you can backup, saving the state for separate storage, at the cluster level. The complete state of an environment backup includes:

      * Cluster files

      * etcd data on each master

      * API Objects

      * Registry storage

      * Storage of volumes

In this example I took backup of the cluster files, it was developed and made available! [In this repository] (backups/day2Ops)


* Para realização dos backups nos hosts diariamente, execute os scripts ![instala-script-master.sh](backups/dia2Ops/instala-script-master.sh) e ![instala-script-node.sh](backups/dia2Ops/instala-script-node.sh), conforme imagem abaixo:
* For daily backups, run the scripts! [Install-script-master.sh] (backups/day2Ops/install-script-master.sh) and! [Install-script-node.sh] (backups/day2Ops/install-script-node.sh), as shown below:

![](images/instala-script-backup.png?raw=true)


### IMPORTANT

1. Backup files will be available in the /backup/HOSTNAME/HOSTNAME-DATA.tar.gz directory, a backup routine is suggested for collecting these files.

2. Backup starts at 03:05 every day

3. The last 7 old * .tar.gz files are deleted in the / backup directory.


# Pontos de Atenção

## Paths para backup / Monitoração

### GlusterFS

Como pré requisito de todos os pods de infra e app persistentes, é necessario que a infraestrutura do gluster server esteja no ar, valide se todos os PODs estão em execução:


```
[okd@MASTER1 ~]$ oc get pods -o wide -n infra-storage
NAME                                           READY     STATUS    RESTARTS   AGE       IP             NODE        NOMINATED NODE
glusterblock-registry-provisioner-dc-1-4kp45   1/1       Running   1          1d        10.129.0.212   mas        <none>
glusterfs-registry-v6j4s                       1/1       Running   0          6h        192.168.0.     huracan     <none>
glusterfs-registry-v9mgr                       1/1       Running   0          6h        10.1.0.196     urus        <none>
glusterfs-registry-xt58f                       1/1       Running   0          6h        10.1.0.198     aventador   <none>
heketi-registry-1-7czl4                        1/1       Running   1          1d        10.128.1.230   sorento     <none>
[okd@MASTER1 ~]$ oc get pods -o wide -n app-storage
NAME                                          READY     STATUS    RESTARTS   AGE       IP             NODE        NOMINATED NODE
glusterblock-storage-provisioner-dc-1-xxpzn   1/1       Running   0          1d        10.129.0.217   urus        <none>
glusterfs-storage-6scmz                       1/1       Running   0          6h        10.1.0.144     sorento     <none>
glusterfs-storage-cwt4v                       1/1       Running   0          6h        10.1.0.145     tiguan      <none>
glusterfs-storage-t26rn                       1/1       Running   0          6h        10.1.0.146     outlander   <none>
heketi-storage-1-7fwsh                        1/1       Running   18         36d       10.129.0.218   urus        <none>
[okd@MASTER1 ~]$ oc get events -n infra-storage
No resources found.
[okd@MASTER1 ~]$ oc get events -n app-storage
No resources found.
[okd@MASTER1 ~]$
```

![](images/infra-storage.png?raw=true)
![](images/app-storage.png?raw=true)

### Pipelines

Caso o pipeline esteja demorando muito para iniciar as etapas de deploy, valide se GlusterFS esta em correto funcionamento citado conforme comandos listados anteriormente.

Em caso positivo, valide se o container jenkins-slave esta em execução:

```
[okd@MASTER1 ~]$ oc get pods -o wide -n cicd
NAME              READY     STATUS    RESTARTS   AGE       IP             NODE        NOMINATED NODE
jenkins-7-92n9p   1/1       Running   0          6h        10.128.2.228   outlander   <none>
maven-1-xkjvk	  1/1	    Running   0		 1m	   10.128.2.119	  sorento     <none>
```

Caso esteja em execução acompanhe o pipeline em execução, caso falhe aguarde 5min para que o pod possa ser excluido, caso contrario exclua o pod conforme comando abaixo:

```
[okd@MASTER1 ~]$ oc delete pods maven-1-xkjvk -n cicd
```

### MASTER1

1. Diretorio de compartilhamento NFS
```
[root@MASTER1 ~]# showmount -e
Export list for MASTER1:
/opt/osev3-etcd/etcd-vol2 *
/exports/logging-es-ops   *
/exports/logging-es       *
/exports/metrics          *
/exports/registry         *
```

O unico compartilhamento NFS utilizado é para armazenamento persistente dos dados do elasticsearch-storage, conforme listado abaixo:

```
[okd@MASTER1 ~]$ oc get pods -o wide
NAME                                      READY     STATUS      RESTARTS   AGE       IP             NODE        NOMINATED NODE
logging-curator-1550633400-cr2zv          0/1       Completed   0          15h       10.129.3.176   huracan     <none>
logging-es-data-master-w8kahjwo-3-t5pkl   2/2       Running     0          1d        10.131.0.187   aventador   <none>
logging-fluentd-6jrlj                     1/1       Running     34         37d       10.131.0.177   aventador   <none>
logging-fluentd-9dl5j                     1/1       Running     20         37d       10.130.0.23    tiguan      <none>
logging-fluentd-j94p4                     1/1       Running     2          1d        10.128.1.229   sorento     <none>
logging-fluentd-n8nv9                     1/1       Running     21         39d       10.128.2.225   outlander   <none>
logging-fluentd-pf6zt                     1/1       Running     21         36d       10.129.3.172   huracan     <none>
logging-fluentd-zjpq5                     1/1       Running     29         1d        10.129.0.216   urus        <none>
logging-kibana-1-qxgwp                    2/2       Running     0          1d        10.131.0.184   aventador   <none>

[okd@MASTER1 ~]$ ssh aventador
Last login: Wed Feb 20 10:50:49 2019 from 10.0.10.82

[okd@NODE2 ~]$ mount | grep nfs
sunrpc on /var/lib/nfs/rpc_pipefs type rpc_pipefs (rw,relatime)
sorento.yourdomain.com:/opt/osev3-etcd/etcd-vol2 on /var/lib/origin/openshift.local.volumes/pods/a6869996-3446-11e9-b1a7-506b8d925c9c/volumes/kubernetes.io~nfs/etcd-vol2-volume type nfs4 (rw,relatime,vers=4.1,rsize=1048576,wsize=1048576,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,clientaddr=10.1.0.198,local_lock=none,addr=10.1.0.144)
```

![](images/pv.png?raw=true)

![](images/loggins-es-data-master.png?raw=true)

2. Partição GlusterFS
```
[root@MASTER1 ~]# fdisk -l /dev/sdc

[root@MASTER1 ~]# fdisk -l /dev/sdc

Disk /dev/sdc: 85.9 GB, 85899345920 bytes, 167772160 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 1048576 bytes
```

3. Partição de imagens Docker
```
[root@MASTER1 ~]# fdisk -l /dev/sdb

Disk /dev/sdb: 21.5 GB, 21474836480 bytes, 41943040 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk label type: dos
Disk identifier: 0x0005a746

   Device Boot      Start         End      Blocks   Id  System
/dev/sdb1            2048    41943039    20970496   8e  Linux LVM

[root@MASTER1 ~]# vgs docker-vg
  VG        #PV #LV #SN Attr   VSize   VFree
  docker-vg   1   1   0 wz--n- <20.00g    0

[root@MASTER1 ~]# lvs /dev/docker-vg/docker-pool
  LV          VG        Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  docker-pool docker-vg -wi-ao---- <20.00g
```

### MASTER2

1. Partição GlusterFS
```
[root@MASTER2 ~]# fdisk -l /dev/sdc

Disk /dev/sdc: 85.9 GB, 85899345920 bytes, 167772160 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 1048576 bytes
```

3. Partição de imagens Docker
```
[root@MASTER2 ~]# fdisk -l /dev/sdb

Disk /dev/sdb: 21.5 GB, 21474836480 bytes, 41943040 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk label type: dos
Disk identifier: 0x0005a746

   Device Boot      Start         End      Blocks   Id  System
/dev/sdb1            2048    41943039    20970496   8e  Linux LVM

[root@MASTER2 ~]# vgs docker-vg
  VG        #PV #LV #SN Attr   VSize   VFree
  docker-vg   1   1   0 wz--n- <20.00g    0

[root@MASTER2 ~]# lvs /dev/docker-vg/docker-pool
  LV          VG        Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  docker-pool docker-vg -wi-ao---- <20.00g
```

### NODE2

1. Partição GlusterFS
```
[root@NODE2 ~]# fdisk -l /dev/sdc

Disk /dev/sdc: 85.9 GB, 85899345920 bytes, 167772160 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 1048576 bytes
```

3. Partição de imagens Docker
```
[root@NODE2 ~]# fdisk -l /dev/sdb

Disk /dev/sdb: 21.5 GB, 21474836480 bytes, 41943040 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk label type: dos
Disk identifier: 0x0005a746

   Device Boot      Start         End      Blocks   Id  System
/dev/sdb1            2048    41943039    20970496   8e  Linux LVM

[root@NODE2 ~]# vgs docker-vg
  VG        #PV #LV #SN Attr   VSize   VFree
  docker-vg   1   1   0 wz--n- <20.00g    0

[root@NODE2 ~]# lvs /dev/docker-vg/docker-pool
  LV          VG        Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  docker-pool docker-vg -wi-ao---- <20.00g
```

### NODE1

1. Partição GlusterFS
```
[root@NODE1 ~]# fdisk -l /dev/sdc

Disk /dev/sdc: 85.9 GB, 85899345920 bytes, 167772160 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 1048576 bytes
```

3. Partição de imagens Docker
```
[root@NODE1 ~]# fdisk -l /dev/sdb

Disk /dev/sdb: 21.5 GB, 21474836480 bytes, 41943040 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk label type: dos
Disk identifier: 0x0005a746

   Device Boot      Start         End      Blocks   Id  System
/dev/sdb1            2048    41943039    20970496   8e  Linux LVM

[root@NODE1 ~]# vgs docker-vg
  VG        #PV #LV #SN Attr   VSize   VFree
  docker-vg   1   1   0 wz--n- <20.00g    0

[root@NODE1 ~]# lvs /dev/docker-vg/docker-pool
  LV          VG        Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  docker-pool docker-vg -wi-ao---- <20.00g
```

### NODE4

1. Partição GlusterFS
```
[root@NODE4 ~]# fdisk -l /dev/sdc

Disk /dev/sdc: 85.9 GB, 85899345920 bytes, 167772160 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 1048576 bytes
```

3. Partição de imagens Docker
```
[root@NODE4 ~]# fdisk -l /dev/sdb

Disk /dev/sdb: 21.5 GB, 21474836480 bytes, 41943040 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk label type: dos
Disk identifier: 0x0005a746

   Device Boot      Start         End      Blocks   Id  System
/dev/sdb1            2048    41943039    20970496   8e  Linux LVM

[root@NODE4 ~]# vgs docker-vg
  VG        #PV #LV #SN Attr   VSize   VFree
  docker-vg   1   1   0 wz--n- <20.00g    0

[root@NODE4 ~]# lvs /dev/docker-vg/docker-pool
  LV          VG        Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  docker-pool docker-vg -wi-ao---- <20.00g
```

### NODE5

1. Partição GlusterFS
```
[root@NODE5 ~]# fdisk -l /dev/sdc

Disk /dev/sdc: 85.9 GB, 85899345920 bytes, 167772160 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 1048576 bytes
```

3. Partição de imagens Docker
```
[root@NODE5 ~]# fdisk -l /dev/sdb

Disk /dev/sdb: 21.5 GB, 21474836480 bytes, 41943040 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk label type: dos
Disk identifier: 0x0005a746

   Device Boot      Start         End      Blocks   Id  System
/dev/sdb1            2048    41943039    20970496   8e  Linux LVM

[root@NODE5 ~]# vgs docker-vg
  VG        #PV #LV #SN Attr   VSize   VFree
  docker-vg   1   1   0 wz--n- <20.00g    0

[root@NODE5 ~]# lvs /dev/docker-vg/docker-pool
  LV          VG        Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  docker-pool docker-vg -wi-ao---- <20.00g
```

## Troubleshoot

### Daemons do S.O

```
[root@MASTER1 ~]# systemctl status origin-node.service
● origin-node.service - OpenShift Node
   Loaded: loaded (/etc/systemd/system/origin-node.service; enabled; vendor preset: disabled)
   Active: active (running) since Mon 2018-10-15 14:01:22 -03; 6 days ago
     Docs: https://github.com/openshift/origin
 Main PID: 4173 (hyperkube)
   Memory: 120.2M
   CGroup: /system.slice/origin-node.service
           └─4173 /usr/bin/hyperkube kubelet --v=2 --address=0.0.0.0 --allow-privileged=true --anonymous-auth=true --authentication-token-webhook=true --authentication-t...
```

```
[root@MASTER2 ~]# systemctl status origin-node.service
● origin-node.service - OpenShift Node
   Loaded: loaded (/etc/systemd/system/origin-node.service; enabled; vendor preset: disabled)
   Active: active (running) since Mon 2018-10-15 14:01:22 -03; 6 days ago
     Docs: https://github.com/openshift/origin
 Main PID: 4173 (hyperkube)
   Memory: 120.2M
   CGroup: /system.slice/origin-node.service
           └─4173 /usr/bin/hyperkube kubelet --v=2 --address=0.0.0.0 --allow-privileged=true --anonymous-auth=true --authentication-token-webhook=true --authentication-t...
```

```
[root@NODE2 ~]# systemctl status origin-node.service
● origin-node.service - OpenShift Node
   Loaded: loaded (/etc/systemd/system/origin-node.service; enabled; vendor preset: disabled)
   Active: active (running) since Mon 2018-10-15 14:01:22 -03; 6 days ago
     Docs: https://github.com/openshift/origin
 Main PID: 4173 (hyperkube)
   Memory: 120.2M
   CGroup: /system.slice/origin-node.service
           └─4173 /usr/bin/hyperkube kubelet --v=2 --address=0.0.0.0 --allow-privileged=true --anonymous-auth=true --authentication-token-webhook=true --authentication-t...
```

```
[root@NODE1 ~]# systemctl status origin-node.service
● origin-node.service - OpenShift Node
   Loaded: loaded (/etc/systemd/system/origin-node.service; enabled; vendor preset: disabled)
   Active: active (running) since Mon 2018-10-15 14:01:22 -03; 6 days ago
     Docs: https://github.com/openshift/origin
 Main PID: 4173 (hyperkube)
   Memory: 120.2M
   CGroup: /system.slice/origin-node.service
           └─4173 /usr/bin/hyperkube kubelet --v=2 --address=0.0.0.0 --allow-privileged=true --anonymous-auth=true --authentication-token-webhook=true --authentication-t...
```

```
[root@NODE4 ~]# systemctl status origin-node.service
● origin-node.service - OpenShift Node
   Loaded: loaded (/etc/systemd/system/origin-node.service; enabled; vendor preset: disabled)
   Active: active (running) since Mon 2018-10-15 14:59:32 -03; 6 days ago
     Docs: https://github.com/openshift/origin
 Main PID: 2052 (hyperkube)
   Memory: 207.1M
   CGroup: /system.slice/origin-node.service
           └─2052 /usr/bin/hyperkube kubelet --v=2 --address=0.0.0.0 --allow-privileged=true --anon...
```

```
[root@NODE5 ~]# systemctl status origin-node.service
● origin-node.service - OpenShift Node
   Loaded: loaded (/etc/systemd/system/origin-node.service; enabled; vendor preset: disabled)
   Active: active (running) since Mon 2018-10-15 15:18:42 -03; 6 days ago
     Docs: https://github.com/openshift/origin
 Main PID: 2075 (hyperkube)
   Memory: 175.9M
   CGroup: /system.slice/origin-node.service
           └─2075 /usr/bin/hyperkube kubelet --v=2 --address=0.0.0.0 --allow-privileged=true --anon...
```

## Arquivos e diretorios de configuração

### Master
```
/etc/origin/master
```

* Principal arquivo de configuração do master
```
/etc/origin/master/master-config.yaml
```

* Arquivo de usuario/senha
```
/etc/origin/master/htpasswd
```

* Principal arquivo de configuracao do node
```
/etc/origin/node/node-config.yaml
```

```
/etc/origin/master/
```


## Utilitário oc

```
[okd@MASTER1 ~]$ oc whoami
system:admin
```

* Acesso com usuario local
```
[okd@MASTER1 ~]$ oc login -u system:admin
Logged into "https://sorento.yourdomain.com:8443" as "system:admin" using existing credentials.

You have access to the following projects and can switch between them with 'oc project <projectname>':

  * cicd
    default
    hmlg
    kube-public
    kube-service-catalog
    kube-system
    management-infra
    openshift
    openshift-ansible-service-broker
    openshift-infra
    openshift-logging
    openshift-node
    openshift-sdn
    openshift-template-service-broker
    openshift-web-console
    teste-pipeline

Using project "cicd".
```

* Acesso remoto

![](images/login-externo.png?raw=true)

Obs.: Caso não tenha, instale o utilitário [oc](https://www.okd.io/download.html).

```
[okd@MASTER1 ~]$ oc login
Authentication required for https://okd.yourdomain.com:8443 (openshift)
Username: integracao
Password:
Login successful.

You have access to the following projects and can switch between them with 'oc project <projectname>':

  * cicd
    hmlg

Using project "cicd".
```

```
[okd@MASTER1 ~]$ oc get nodes
NAME        STATUS    ROLES          AGE       VERSION
outlander   Ready     compute        19d       v1.10.0+b81c8f8
sorento     Ready     infra,master   19d       v1.10.0+b81c8f8
tiguan      Ready     compute        19d       v1.10.0+b81c8f8
```

```
[okd@MASTER1 ~]$ oc describe node sorento
Name:               sorento
Roles:              infra,master
Labels:             beta.kubernetes.io/arch=amd64
                    beta.kubernetes.io/os=linux
                    glusterfs=registry-host
                    kubernetes.io/hostname=sorento
                    node-role.kubernetes.io/infra=true
                    node-role.kubernetes.io/master=true
Annotations:        volumes.kubernetes.io/controller-managed-attach-detach=true
CreationTimestamp:  Tue, 02 Oct 2018 15:36:37 -0300
Taints:             <none>
Unschedulable:      false
Conditions:
  Type             Status  LastHeartbeatTime                 LastTransitionTime                Reason                       Message
  ----             ------  -----------------                 ------------------                ------                       -------
  OutOfDisk        False   Mon, 22 Oct 2018 11:41:59 -0300   Tue, 02 Oct 2018 15:36:27 -0300   KubeletHasSufficientDisk     kubelet has sufficient disk space available
  MemoryPressure   False   Mon, 22 Oct 2018 11:41:59 -0300   Tue, 02 Oct 2018 15:36:27 -0300   KubeletHasSufficientMemory   kubelet has sufficient memory available
  DiskPressure     False   Mon, 22 Oct 2018 11:41:59 -0300   Tue, 02 Oct 2018 15:36:27 -0300   KubeletHasNoDiskPressure     kubelet has no disk pressure
  PIDPressure      False   Mon, 22 Oct 2018 11:41:59 -0300   Tue, 02 Oct 2018 15:36:27 -0300   KubeletHasSufficientPID      kubelet has sufficient PID available
  Ready            True    Mon, 22 Oct 2018 11:41:59 -0300   Tue, 02 Oct 2018 16:18:09 -0300   KubeletReady                 kubelet is posting ready status
Addresses:
  InternalIP:  10.1.0.144
  Hostname:    sorento
Capacity:
 cpu:            8
 hugepages-1Gi:  0
 hugepages-2Mi:  0
 memory:         16266716Ki
 pods:           250
Allocatable:
 cpu:            8
 hugepages-1Gi:  0
 hugepages-2Mi:  0
 memory:         16164316Ki
 pods:           250
System Info:
 Machine ID:                         eb49ea7961254dcf91b975c2336dd81c
 System UUID:                        423A2782-89E3-27EF-9F13-AC18572B90E2
 Boot ID:                            666abe90-9e60-4681-b6e4-f5a7a168bbc1
 Kernel Version:                     3.10.0-862.14.4.el7.x86_64
 OS Image:                           CentOS Linux 7 (Core)
 Operating System:                   linux
 Architecture:                       amd64
 Container Runtime Version:          docker://1.13.1
 Kubelet Version:                    v1.10.0+b81c8f8
 Kube-Proxy Version:                 v1.10.0+b81c8f8
ExternalID:                          sorento
Non-terminated Pods:                 (16 in total)
  Namespace                          Name                          CPU Requests  CPU Limits  Memory Requests  Memory Limits
  ---------                          ----                          ------------  ----------  ---------------  -------------
  default                            docker-registry-1-nzq49       100m (1%)     0 (0%)      256Mi (1%)       0 (0%)
  default                            glusterfs-registry-qsbnd      100m (1%)     0 (0%)      100Mi (0%)       0 (0%)
  default                            registry-console-1-5hrkl      0 (0%)        0 (0%)      0 (0%)           0 (0%)
  default                            router-1-4plwt                100m (1%)     0 (0%)      256Mi (1%)       0 (0%)
  kube-service-catalog               apiserver-hc7dl               0 (0%)        0 (0%)      0 (0%)           0 (0%)
  kube-service-catalog               controller-manager-q27dk      0 (0%)        0 (0%)      0 (0%)           0 (0%)
  kube-system                        master-api-sorento            0 (0%)        0 (0%)      0 (0%)           0 (0%)
  kube-system                        master-controllers-sorento    0 (0%)        0 (0%)      0 (0%)           0 (0%)
  kube-system                        master-etcd-sorento           0 (0%)        0 (0%)      0 (0%)           0 (0%)
  openshift-ansible-service-broker   asb-1-jt5b7                   0 (0%)        0 (0%)      0 (0%)           0 (0%)
  openshift-infra                    hawkular-metrics-zjvjx        0 (0%)        0 (0%)      1500M (9%)       2500M (15%)
  openshift-node                     sync-mgpr9                    0 (0%)        0 (0%)      0 (0%)           0 (0%)
  openshift-sdn                      ovs-rjzqn                     100m (1%)     200m (2%)   300Mi (1%)       400Mi (2%)
  openshift-sdn                      sdn-q5xwv                     100m (1%)     0 (0%)      200Mi (1%)       0 (0%)
  openshift-template-service-broker  apiserver-66j8w               0 (0%)        0 (0%)      0 (0%)           0 (0%)
  openshift-web-console              webconsole-55c4d867f-4brvw    100m (1%)     0 (0%)      100Mi (0%)       0 (0%)
Allocated resources:
  (Total limits may be over 100 percent, i.e., overcommitted.)
  CPU Requests  CPU Limits  Memory Requests   Memory Limits
  ------------  ----------  ---------------   -------------
  600m (7%)     200m (2%)   2770874112 (16%)  2919430400 (17%)
Events:         <none>
```

```
[okd@MASTER1 ~]$ oc describe node tiguan
Name:               tiguan
Roles:              compute
Labels:             beta.kubernetes.io/arch=amd64
                    beta.kubernetes.io/os=linux
                    glusterfs=registry-host
                    kubernetes.io/hostname=tiguan
                    node-role.kubernetes.io/compute=true
Annotations:        volumes.kubernetes.io/controller-managed-attach-detach=true
CreationTimestamp:  Tue, 02 Oct 2018 16:18:09 -0300
Taints:             <none>
Unschedulable:      false
Conditions:
  Type             Status  LastHeartbeatTime                 LastTransitionTime                Reason                       Message
  ----             ------  -----------------                 ------------------                ------                       -------
  OutOfDisk        False   Mon, 22 Oct 2018 11:43:12 -0300   Mon, 15 Oct 2018 14:59:32 -0300   KubeletHasSufficientDisk     kubelet has sufficient disk space available
  MemoryPressure   False   Mon, 22 Oct 2018 11:43:12 -0300   Mon, 15 Oct 2018 14:59:32 -0300   KubeletHasSufficientMemory   kubelet has sufficient memory available
  DiskPressure     False   Mon, 22 Oct 2018 11:43:12 -0300   Mon, 15 Oct 2018 14:59:32 -0300   KubeletHasNoDiskPressure     kubelet has no disk pressure
  PIDPressure      False   Mon, 22 Oct 2018 11:43:12 -0300   Tue, 02 Oct 2018 16:18:09 -0300   KubeletHasSufficientPID      kubelet has sufficient PID available
  Ready            True    Mon, 22 Oct 2018 11:43:12 -0300   Mon, 15 Oct 2018 14:59:42 -0300   KubeletReady                 kubelet is posting ready status
Addresses:
  InternalIP:  10.1.0.145
  Hostname:    tiguan
Capacity:
 cpu:            8
 hugepages-1Gi:  0
 hugepages-2Mi:  0
 memory:         16266716Ki
 pods:           250
Allocatable:
 cpu:            8
 hugepages-1Gi:  0
 hugepages-2Mi:  0
 memory:         16164316Ki
 pods:           250
System Info:
 Machine ID:                 9b67f9de3ee849e88f47bee0eb828b15
 System UUID:                423AB5CA-ABAA-8A80-9CAD-B7E844F0B669
 Boot ID:                    03882476-9317-429d-9aec-30fb5063d2d1
 Kernel Version:             3.10.0-862.14.4.el7.x86_64
 OS Image:                   CentOS Linux 7 (Core)
 Operating System:           linux
 Architecture:               amd64
 Container Runtime Version:  docker://1.13.1
 Kubelet Version:            v1.10.0+b81c8f8
 Kube-Proxy Version:         v1.10.0+b81c8f8
ExternalID:                  tiguan
Non-terminated Pods:         (10 in total)
  Namespace                  Name                                            CPU Requests  CPU Limits  Memory Requests  Memory Limits
  ---------                  ----                                            ------------  ----------  ---------------  -------------
  cicd                       sonarqube-1-4fzzl                               200m (2%)     1 (12%)     1Gi (6%)         3Gi (19%)
  default                    glusterblock-registry-provisioner-dc-1-drzr5    0 (0%)        0 (0%)      0 (0%)           0 (0%)
  default                    glusterfs-registry-m4cpg                        100m (1%)     0 (0%)      100Mi (0%)       0 (0%)
  default                    heketi-registry-1-28mq6                         0 (0%)        0 (0%)      0 (0%)           0 (0%)
  hmlg                       email-2-8lkf5                                   0 (0%)        0 (0%)      0 (0%)           0 (0%)
  openshift-infra            hawkular-cassandra-1-7fjzj                      0 (0%)        0 (0%)      1G (6%)          2G (12%)
  openshift-infra            heapster-2lv95                                  0 (0%)        0 (0%)      937500k (5%)     3750M (22%)
  openshift-node             sync-b282k                                      0 (0%)        0 (0%)      0 (0%)           0 (0%)
  openshift-sdn              ovs-m2p6w                                       100m (1%)     200m (2%)   300Mi (1%)       400Mi (2%)
  openshift-sdn              sdn-2pphr                                       100m (1%)     0 (0%)      200Mi (1%)       0 (0%)
Allocated resources:
  (Total limits may be over 100 percent, i.e., overcommitted.)
  CPU Requests  CPU Limits   Memory Requests   Memory Limits
  ------------  ----------   ---------------   -------------
  500m (6%)     1200m (15%)  3640387424 (21%)  9390655872 (56%)
Events:         <none>
```

```
[okd@MASTER1 ~]$ oc describe node outlander
Name:               outlander
Roles:              compute
Labels:             beta.kubernetes.io/arch=amd64
                    beta.kubernetes.io/os=linux
                    glusterfs=registry-host
                    kubernetes.io/hostname=outlander
                    node-role.kubernetes.io/compute=true
Annotations:        volumes.kubernetes.io/controller-managed-attach-detach=true
CreationTimestamp:  Tue, 02 Oct 2018 16:18:08 -0300
Taints:             <none>
Unschedulable:      false
Conditions:
  Type             Status  LastHeartbeatTime                 LastTransitionTime                Reason                       Message
  ----             ------  -----------------                 ------------------                ------                       -------
  OutOfDisk        False   Mon, 22 Oct 2018 11:43:50 -0300   Mon, 15 Oct 2018 15:18:42 -0300   KubeletHasSufficientDisk     kubelet has sufficient disk space available
  MemoryPressure   False   Mon, 22 Oct 2018 11:43:50 -0300   Mon, 15 Oct 2018 15:18:42 -0300   KubeletHasSufficientMemory   kubelet has sufficient memory available
  DiskPressure     False   Mon, 22 Oct 2018 11:43:50 -0300   Mon, 15 Oct 2018 15:18:42 -0300   KubeletHasNoDiskPressure     kubelet has no disk pressure
  PIDPressure      False   Mon, 22 Oct 2018 11:43:50 -0300   Tue, 02 Oct 2018 16:18:08 -0300   KubeletHasSufficientPID      kubelet has sufficient PID available
  Ready            True    Mon, 22 Oct 2018 11:43:50 -0300   Mon, 15 Oct 2018 15:18:52 -0300   KubeletReady                 kubelet is posting ready status
Addresses:
  InternalIP:  10.1.0.146
  Hostname:    outlander
Capacity:
 cpu:            8
 hugepages-1Gi:  0
 hugepages-2Mi:  0
 memory:         16266716Ki
 pods:           250
Allocatable:
 cpu:            8
 hugepages-1Gi:  0
 hugepages-2Mi:  0
 memory:         16164316Ki
 pods:           250
System Info:
 Machine ID:                 2cbbd2d42edc443e974f74617846910c
 System UUID:                423A1D86-902F-872E-D52F-2FC14522DC47
 Boot ID:                    19b472da-ea8d-4b52-95fc-e39bbf88a0d3
 Kernel Version:             3.10.0-862.14.4.el7.x86_64
 OS Image:                   CentOS Linux 7 (Core)
 Operating System:           linux
 Architecture:               amd64
 Container Runtime Version:  docker://1.13.1
 Kubelet Version:            v1.10.0+b81c8f8
 Kube-Proxy Version:         v1.10.0+b81c8f8
ExternalID:                  outlander
Non-terminated Pods:         (14 in total)
  Namespace                  Name                           CPU Requests  CPU Limits  Memory Requests  Memory Limits
  ---------                  ----                           ------------  ----------  ---------------  -------------
  cicd                       jenkins-2-lvlz5                0 (0%)        0 (0%)      5Mi (0%)         5Gi (32%)
  default                    glusterfs-registry-czplt       100m (1%)     0 (0%)      100Mi (0%)       0 (0%)
  hmlg                       file-upload-1-tqsqw            0 (0%)        0 (0%)      0 (0%)           0 (0%)
  hmlg                       juris-5-8bp2k                  0 (0%)        0 (0%)      0 (0%)           0 (0%)
  hmlg                       juris-front-5-pv6qp            0 (0%)        0 (0%)      0 (0%)           0 (0%)
  hmlg                       keycloak-1-bnwjw               0 (0%)        0 (0%)      0 (0%)           0 (0%)
  hmlg                       keycloak-postgresql-1-4xqsv    200m (2%)     300m (3%)   512Mi (3%)       512Mi (3%)
  hmlg                       localizacao-3-fx9t5            0 (0%)        0 (0%)      0 (0%)           0 (0%)
  hmlg                       ocb-admin-server-1-r87wh       0 (0%)        0 (0%)      0 (0%)           0 (0%)
  hmlg                       ocb-config-server-11-2xbmp     0 (0%)        0 (0%)      0 (0%)           0 (0%)
  hmlg                       ramo-5-ksjr9                   0 (0%)        0 (0%)      0 (0%)           0 (0%)
  openshift-node             sync-rwlkq                     0 (0%)        0 (0%)      0 (0%)           0 (0%)
  openshift-sdn              ovs-xg4t5                      100m (1%)     200m (2%)   300Mi (1%)       400Mi (2%)
  openshift-sdn              sdn-82wcw                      100m (1%)     0 (0%)      200Mi (1%)       0 (0%)
Allocated resources:
  (Total limits may be over 100 percent, i.e., overcommitted.)
  CPU Requests  CPU Limits  Memory Requests  Memory Limits
  ------------  ----------  ---------------  -------------
  500m (6%)     500m (6%)   1117Mi (7%)      6032Mi (38%)
Events:         <none>
```

### Visualizar os pods de um projeto especifico:

```
[okd@MASTER1 ~]$ oc get pods -n hmlg -o wide
NAME                          READY     STATUS      RESTARTS   AGE       IP             NODE
email-2-8lkf5                 1/1       Running     0          3d        10.130.0.240   tiguan
email-2-build                 0/1       Completed   0          3d        10.130.0.237   tiguan
file-upload-1-tqsqw           1/1       Running     0          6d        10.129.0.161   outlander
juris-2-build                 0/1       Completed   0          3d        10.129.0.222   outlander
juris-3-build                 0/1       Completed   0          3d        10.130.0.236   tiguan
juris-4-build                 0/1       Completed   0          3d        10.130.0.245   tiguan
juris-5-8bp2k                 1/1       Running     0          3d        10.129.1.1     outlander
juris-5-build                 0/1       Completed   0          3d        10.130.1.9     tiguan
juris-front-1-build           0/1       Completed   0          11d       10.130.0.72    tiguan
juris-front-2-build           0/1       Completed   0          4d        10.130.0.219   tiguan
juris-front-3-build           0/1       Completed   0          3d        10.130.0.242   tiguan
juris-front-4-build           0/1       Completed   0          3d        10.130.1.11    tiguan
juris-front-5-build           0/1       Completed   0          1h        10.130.1.16    tiguan
juris-front-5-pv6qp           1/1       Running     0          1h        10.129.1.6     outlander
keycloak-1-bnwjw              1/1       Running     0          6d        10.129.0.156   outlander
keycloak-postgresql-1-4xqsv   1/1       Running     0          6d        10.129.0.149   outlander
localizacao-2-build           0/1       Error       0          3d        10.130.0.251   tiguan
localizacao-3-build           0/1       Completed   0          3d        10.130.0.252   tiguan
localizacao-3-fx9t5           1/1       Running     0          3d        10.129.0.252   outlander
localizacao-4-build           0/1       Error       0          3d        10.130.0.255   tiguan
localizacao-5-build           0/1       Error       0          3d        10.130.1.0     tiguan
localizacao-6-build           0/1       Completed   0          3d        10.130.1.1     tiguan
ocb-admin-server-1-build      0/1       Completed   0          11d       10.130.0.65    tiguan
ocb-admin-server-1-r87wh      1/1       Running     0          6d        10.129.0.158   outlander
ocb-config-server-10-build    0/1       Completed   0          4d        10.130.0.229   tiguan
ocb-config-server-11-2xbmp    1/1       Running     0          4d        10.129.0.219   outlander
ocb-config-server-11-build    0/1       Completed   0          4d        10.129.0.217   outlander
ocb-config-server-7-build     0/1       Completed   0          4d        10.130.0.222   tiguan
ocb-config-server-8-build     0/1       Completed   0          4d        10.130.0.225   tiguan
ocb-config-server-9-build     0/1       Completed   0          4d        10.129.0.213   outlander
ramo-2-build                  0/1       Completed   0          3d        10.130.0.248   tiguan
ramo-3-build                  0/1       Completed   0          3d        10.130.1.3     tiguan
ramo-4-build                  0/1       Completed   0          3d        10.130.1.6     tiguan
ramo-5-build                  0/1       Completed   0          2h        10.130.1.14    tiguan
ramo-5-ksjr9                  1/1       Running     0          2h        10.129.1.4     outlander
```

```
[okd@MASTER1 ~]$ oc get pods -n cicd
NAME                        READY     STATUS      RESTARTS   AGE
cicd-demo-installer-vx8jq   0/1       Completed   0          6d
jenkins-2-lvlz5             1/1       Running     0          3d
sonarqube-1-4fzzl           1/1       Running     2          6d
```

### Visualizar o status de um pod especifico
```
[okd@MASTER1 ~]$ oc describe pod jenkins-2-lvlz5
Name:           jenkins-2-lvlz5
Namespace:      cicd
Node:           outlander/10.1.0.146
Start Time:     Thu, 18 Oct 2018 14:34:25 -0300
Labels:         deployment=jenkins-2
                deploymentconfig=jenkins
                name=jenkins
Annotations:    openshift.io/deployment-config.latest-version=2
                openshift.io/deployment-config.name=jenkins
                openshift.io/deployment.name=jenkins-2
                openshift.io/scc=restricted
Status:         Running
IP:             10.129.0.221
Controlled By:  ReplicationController/jenkins-2
Containers:
  jenkins:
    Container ID:   docker://8e036040e4336002ff116aebfd0b2b34fd2c88f888589f55e874eb805877e769
    Image:          docker-registry.default.svc:5000/openshift/jenkins@sha256:26d9f54ff135d9a28c5e49a431328c9c49af5235c952ce2b9cb4afafdc336fa7
    Image ID:       docker-pullable://docker-registry.default.svc:5000/openshift/jenkins@sha256:26d9f54ff135d9a28c5e49a431328c9c49af5235c952ce2b9cb4afafdc336fa7
    Port:           <none>
    Host Port:      <none>
    State:          Running
      Started:      Thu, 18 Oct 2018 14:34:28 -0300
    Ready:          True
    Restart Count:  0
    Limits:
      memory:  5Gi
    Requests:
      memory:   5Mi
    Liveness:   http-get http://:8080/login delay=420s timeout=240s period=360s #success=1 #failure=2
    Readiness:  http-get http://:8080/login delay=3s timeout=240s period=10s #success=1 #failure=3
    Environment:
      OPENSHIFT_ENABLE_OAUTH:            true
      OPENSHIFT_ENABLE_REDIRECT_PROMPT:  true
      DISABLE_ADMINISTRATIVE_MONITORS:   false
      KUBERNETES_MASTER:                 https://kubernetes.default:443
      KUBERNETES_TRUST_CERTIFICATES:     true
      JENKINS_SERVICE_NAME:              jenkins
      JNLP_SERVICE_NAME:                 jenkins-jnlp
    Mounts:
      /var/lib/jenkins from jenkins-data (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from jenkins-token-q8zgb (ro)
Conditions:
  Type           Status
  Initialized    True
  Ready          True
  PodScheduled   True
Volumes:
  jenkins-data:
    Type:       PersistentVolumeClaim (a reference to a PersistentVolumeClaim in the same namespace)
    ClaimName:  jenkins
    ReadOnly:   false
  jenkins-token-q8zgb:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  jenkins-token-q8zgb
    Optional:    false
QoS Class:       Burstable
Node-Selectors:  node-role.kubernetes.io/compute=true
Tolerations:     node.kubernetes.io/memory-pressure:NoSchedule
Events:          <none>
```

### Visualizar os serviços de um projeto
```
[okd@MASTER1 ~]$ oc get svc -n hmlg
NAME                  TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)             AGE
email                 ClusterIP   172.30.113.2     <none>        8080/TCP            10d
file-upload           ClusterIP   172.30.141.35    <none>        8080/TCP            11d
juris                 ClusterIP   172.30.39.201    <none>        8080/TCP            10d
juris-front           ClusterIP   172.30.191.126   <none>        8080/TCP,8443/TCP   11d
keycloak              ClusterIP   172.30.110.231   <none>        8080/TCP            11d
keycloak-postgresql   ClusterIP   172.30.71.251    <none>        5432/TCP            11d
localizacao           ClusterIP   172.30.52.246    <none>        8080/TCP            11d
ocb-admin-server      ClusterIP   172.30.154.119   <none>        8080/TCP            11d
ocb-config-server     ClusterIP   172.30.169.139   <none>        8080/TCP            11d
ramo                  ClusterIP   172.30.154.219   <none>        8080/TCP            11d
```

```
[okd@MASTER1 ~]$ oc get svc -n cicd
NAME           TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)     AGE
jenkins        ClusterIP   172.30.110.149   <none>        80/TCP      6d
jenkins-jnlp   ClusterIP   172.30.46.240    <none>        50000/TCP   6d
nexus          ClusterIP   172.30.255.202   <none>        8081/TCP    6d
sonarqube      ClusterIP   172.30.213.26    <none>        9000/TCP    10d
```

```
[okd@MASTER1 ~]$ oc describe svc juris-front -n hmlg
Name:              juris-front
Namespace:         hmlg
Labels:            app=juris-front
Annotations:       openshift.io/generated-by=OpenShiftNewApp
Selector:          app=juris-front,deploymentconfig=juris-front
Type:              ClusterIP
IP:                172.30.191.126
Port:              8080-tcp  8080/TCP
TargetPort:        8080/TCP
Endpoints:         10.129.1.6:8080
Port:              8443-tcp  8443/TCP
TargetPort:        8443/TCP
Endpoints:         10.129.1.6:8443
Session Affinity:  None
Events:            <none>
```

### Visualizar eventos por projeto
```
[okd@MASTER1 ~]$ oc get event -n hmlg  --watch
```

```
[okd@MASTER1 ~]$ oc get event -n cicd  --watch
```


## Comandos úteis

### Excluir e adicionar uma rota em um projeto especifico
```
#oc delete route ROTA_A_SER_EXCLUIDA -n NOME_DO_PROJETO
#oc expose svc NOME_DO_SERVICO --hostname=URL_DE_ACESSO_EXTERNO --path=/CONTEXTO -n NOME_DO_PROJETO

oc delete route colaboradores
oc expose svc colaboradores --hostname=gestao-login-hmlg.cloudapps.yourdomain.com --path=/colaboradores -n hmlg
```

### Gerar hash para a senha do web-console (/etc/origin/master/htpasswd)
```
openssl passwd -apr1 SENHA
```

### Conceder privilegios de administrador no OKD
```
oc adm policy add-cluster-role-to-user cluster-admin USUARIO
```

### Criar um novo projeto
```
oc new-project PROJECT
```

### Provisionar uma nova aplicação baseada em um repositorio git
```
oc new-app CONTAINER:VERSION~https://URL.git --name APP_NAME
```
```
oc new-app --name=hello -i php:7.0  https://github.com/drnic/php-helloworld.git
```

### Acessar o terminal do POD

```
[okd@MASTER1 ~]$ oc rsh jenkins-2-lvlz5
sh-4.2$ ps -aux
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
default      1  0.0  0.0   4216   348 ?        Ss   Oct18   0:00 /usr/bin/dumb-init -- /usr/libexec/s2i/run
default      7  2.7  5.6 8592984 923720 ?      Ssl  Oct18 154:07 java -XX:+UseParallelGC -XX:MinHeapFreeRatio=5 -XX:MaxHeapFreeRatio=10 -XX:GCTimeRat
default   7218  0.8  0.0  15248  1740 ?        Ss   15:22   0:00 /bin/sh
default   7224  0.0  0.0  55140  1812 ?        R+   15:22   0:00 ps -aux
```

## How-To

### Como cancelar um pipeline e excluir um pod que esteja travado?

1. Acesse o ![console web](https://okd.yourdomain.com:8443), na caixa de projetos do lado superior esquerdo, altere para o o projeto CI/CD

2. Na pagina de Overview clique no pipeline que esta em execução e deseja cancelar, clique no numero da build que deseja cancelar, por exemplo: "Build #21", no canto superior direito clique em "Cancel Build"

3. Para excluir um pod que possa estar travado, no menu lateral esquerdo acesso Applications -> Pods

4. Na relaçao de Pods listada clique no Pod que deseja excluir, clique no botão superior esquerdo "Actions" em seguida "Delete", selecione a caixa de seleção "Delete pod immediately without waiting for the processes to terminate gracefully" para forçar sua exclusão, em seguida em "Delete".


![Vídeo de demonstração](movies/Cancelar_build_deleter_pod.mov?raw=true)

### Como expor a estatistica dos roteadores internos para o browser?

Para visualizar a estatistica dos routers, foi adotado os seguintes passos:

1. Acesse o projeto default
```
[okd@MASTER1 ~]$ oc project default
Already on project "default" on server "https://master-okd.yourdomain.com:8443".
```
2. Liste os pods com a opção de mais informação para visualizar o node que hospeda os routers:

Obs.: Foi criado uma label para o projeto default, para que ele sempre crie os pods em nodes da region=infra
```
[okd@MASTER1 ~]$ oc get pods -o wide
NAME                       READY     STATUS    RESTARTS   AGE       IP             NODE        NOMINATED NODE
docker-registry-3-nrp8w    1/1       Running   0          15h       10.131.0.233   aventador   <none>
registry-console-1-4wvrr   0/1       Evicted   0          43d       <none>         sorento     <none>
registry-console-1-c2njf   1/1       Running   15         9d        10.129.1.21    urus        <none>
router-3-pq6xl             1/1       Running   0          9m        10.1.0.197     huracan     <none>
router-3-zfsht             1/1       Running   0          9m        10.1.0.198     aventador   <none>
```
3. Liste as variaveis de ambiente para visualizar o usuario e senha para logar via browser
```
[okd@MASTER1 ~]$ oc set env pod router-3-pq6xl --list | tail -n 6
ROUTER_SERVICE_NAMESPACE=default
ROUTER_SUBDOMAIN=
ROUTER_THREADS=0
STATS_PASSWORD=FTWwfZyZEz
STATS_PORT=1936
STATS_USERNAME=admin
```
4. Acesse via browser os nodes ![Huracan](http://huracan:1936) ou ![Aventador](http://aventador:1936), e insira o usuario e senha informado na consulta as variaveis do pod, conforme imagem abaixo:
![](images/browser_auth_router.png?raw=true)

5. Após a autenticação voce ira visualizar as estatisticas de acesso a cada aplicação
![](images/browser_router.png?raw=true)


Obs.:Para solução deste acesso, foi identificado 2 erros conforme link informado abaixo para resolução:

https://access.redhat.com/solutions/3447991
https://bugzilla.redhat.com/show_bug.cgi?id=1663268


### Como Definir local de hospedagem para um grupo selector de PODs?


## Autor
* **Francisco Neto** - *Initial work* - [PurpleBooth](https://github.com/netoralves)

