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


### DNS Topology

Name 	  | 	IP 	    | Hosts
--- 			  | 	--- 	    | ---
master-okd.yourdomain.com | xxx.xxx.xxx.xxx | VIP (keepalived) LB1 AND LB2
okd.yourdomain.com	  | xxx.xxx.xxx.xxx | VIP (keepalived) LB1 AND LB2
.cloudapps.yourdomain.com | xxx.xxx.xxx.xxx / xxx.xxx.xxx.xxx | NODE3 / NODE4

### Keepalived

![](images/keepalived.png?raw=true)


### URLs
URI | Description
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

## User and grant access table

### S.O users
User | Description | Password
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


* Execute this scripts ![install-script-master.sh](backups/dia2Ops/install-script-master.sh) and ![install-script-node.sh](backups/dia2Ops/install-script-node.sh), follow image below:
* For daily backups, run the scripts! [Install-script-master.sh] (backups/day2Ops/install-script-master.sh) and! [Install-script-node.sh] (backups/day2Ops/install-script-node.sh).


### IMPORTANT

1. Backup files will be available in the /backup/HOSTNAME/HOSTNAME-DATA.tar.gz directory, a backup routine is suggested for collecting these files.

2. Backup starts at 03:05 every day

3. The last 7 old * .tar.gz files are deleted in the / backup directory.


### GlusterFS


```
[okd@MASTER1 ~]$ oc get pods -o wide -n infra-storage
NAME                                           READY     STATUS    RESTARTS   AGE       IP             NODE        NOMINATED NODE
glusterblock-registry-provisioner-dc-1-4kp45   1/1       Running   1          1d        10.129.0.212   master2        <none>
glusterfs-registry-v6j4s                       1/1       Running   0          6h        192.168.0.13   master2     <none>
glusterfs-registry-v9mgr                       1/1       Running   0          6h        192.168.0.15   node1       <none>
glusterfs-registry-xt58f                       1/1       Running   0          6h        192.168.0.16   node2   <none>
heketi-registry-1-7czl4                        1/1       Running   1          1d        10.128.1.230   node3     <none>
[okd@MASTER1 ~]$ oc get pods -o wide -n app-storage
NAME                                          READY     STATUS    RESTARTS   AGE       IP             NODE        NOMINATED NODE
glusterblock-storage-provisioner-dc-1-xxpzn   1/1       Running   0          1d        10.129.0.217   master3        <none>
glusterfs-storage-6scmz                       1/1       Running   0          6h        192.168.0.18   node4          <none>
glusterfs-storage-cwt4v                       1/1       Running   0          6h        192.168.0.19   node5          <none>
glusterfs-storage-t26rn                       1/1       Running   0          6h        10.1.0.146     master1        <none>
heketi-storage-1-7fwsh                        1/1       Running   18         36d       192.168.0.12   master1        <none>
[okd@MASTER1 ~]$ oc get events -n infra-storage
No resources found.
[okd@MASTER1 ~]$ oc get events -n app-storage
No resources found.
[okd@MASTER1 ~]$
```

![](images/infra-storage.png?raw=true)
![](images/app-storage.png?raw=true)

### Pipelines


```
[okd@MASTER1 ~]$ oc get pods -o wide -n cicd
NAME              READY     STATUS    RESTARTS   AGE       IP             NODE        NOMINATED NODE
jenkins-7-92n9p   1/1       Running   0          6h        10.128.2.228   node4        <none>
maven-1-xkjvk	  1/1	    Running   0		 1m	   10.128.2.119	  master1      <none>
```

### MASTER1

1. NFS share directory.
```
[root@MASTER1 ~]# showmount -e
Export list for MASTER1:
/opt/osev3-etcd/etcd-vol2 *
/exports/logging-es-ops   *
/exports/logging-es       *
/exports/metrics          *
/exports/registry         *
```

The only NFS share used is for persistent storage of elasticsearch-storage data, as listed below:

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

[okd@MASTER1 ~]$ ssh node2
Last login: Wed Feb 20 10:50:49 2019 from 10.0.10.82

[okd@NODE2 ~]$ mount | grep nfs
sunrpc on /var/lib/nfs/rpc_pipefs type rpc_pipefs (rw,relatime)
master1.yourdomain.com:/opt/osev3-etcd/etcd-vol2 on /var/lib/origin/openshift.local.volumes/pods/a6869996-3446-11e9-b1a7-506b8d925c9c/volumes/kubernetes.io~nfs/etcd-vol2-volume type nfs4 (rw,relatime,vers=4.1,rsize=1048576,wsize=1048576,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,clientaddr=192.168.0.16,local_lock=none,addr=192.168.0.12)
```

![](images/pv.png?raw=true)

![](images/loggins-es-data-master.png?raw=true)

2. GlusterFS partition
```
[root@MASTER1 ~]# fdisk -l /dev/sdc

[root@MASTER1 ~]# fdisk -l /dev/sdc

Disk /dev/sdc: 85.9 GB, 85899345920 bytes, 167772160 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 1048576 bytes
```

3. Docker images partition
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

1. GlusterFS partition
```
[root@MASTER2 ~]# fdisk -l /dev/sdc

Disk /dev/sdc: 85.9 GB, 85899345920 bytes, 167772160 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 1048576 bytes
```

3. Docker images partition
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

1. GlusterFS partition
```
[root@NODE2 ~]# fdisk -l /dev/sdc

Disk /dev/sdc: 85.9 GB, 85899345920 bytes, 167772160 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 1048576 bytes
```

3. Docker images partition
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

1. GlusterFS partition
```
[root@NODE1 ~]# fdisk -l /dev/sdc

Disk /dev/sdc: 85.9 GB, 85899345920 bytes, 167772160 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 1048576 bytes
```

3. Docker images partition
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

1. GlusterFS partition
```
[root@NODE4 ~]# fdisk -l /dev/sdc

Disk /dev/sdc: 85.9 GB, 85899345920 bytes, 167772160 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 1048576 bytes
```

3. Docker image partition
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

1. GlusterFS partition
```
[root@NODE5 ~]# fdisk -l /dev/sdc

Disk /dev/sdc: 85.9 GB, 85899345920 bytes, 167772160 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 1048576 bytes
```

3. Docker image partition
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

### S.O Daemons

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

## Configuration files and directories

### Master
```
/etc/origin/master
```

* Main file of master configuration
```
/etc/origin/master/master-config.yaml
```

* User/Pass file
```
/etc/origin/master/htpasswd
```

* Main file of node configuration
```
/etc/origin/node/node-config.yaml
```

```
/etc/origin/master/
```


## How-To

### How to expose the statistics of the internal routers to the browser?

1. Access the default project:
```
[okd@MASTER1 ~]$ oc project default
Already on project "default" on server "https://master-okd.yourdomain.com:8443".
```
2. List of pods with the -o wide option to see where node is hosted pod:

```
[okd@MASTER1 ~]$ oc get pods -o wide
NAME                       READY     STATUS    RESTARTS   AGE       IP             NODE        NOMINATED NODE
docker-registry-3-nrp8w    1/1       Running   0          15h       10.131.0.233   aventador   <none>
registry-console-1-4wvrr   0/1       Evicted   0          43d       <none>         sorento     <none>
registry-console-1-c2njf   1/1       Running   15         9d        10.129.1.21    urus        <none>
router-3-pq6xl             1/1       Running   0          9m        10.1.0.197     huracan     <none>
router-3-zfsht             1/1       Running   0          9m        10.1.0.198     aventador   <none>
```
3. List of environment variables to see the user and password to login browser
```
[okd@MASTER1 ~]$ oc set env pod router-3-pq6xl --list | tail -n 6
ROUTER_SERVICE_NAMESPACE=default
ROUTER_SUBDOMAIN=
ROUTER_THREADS=0
STATS_PASSWORD=FTWwfZyZEz
STATS_PORT=1936
STATS_USERNAME=admin
```
4. Access via browser on nodes ![node4](http://node4:1936) ou ![node5](http://node5:1936):
![](images/browser_auth_router.png?raw=true)

5. Before authentication you see the statistic dashboard:
![](images/browser_router.png?raw=true)


Note: For the solution of this access, 2 errors were identified according to the following link for resolution:

https://access.redhat.com/solutions/3447991
https://bugzilla.redhat.com/show_bug.cgi?id=1663268


## Autor
* **Francisco Neto** - *Initial work* - [GitHub](https://github.com/netoralves)

