# Deploy of STAGE and PRD containers environment with OKD 3.10

Automated Installation Procedure of OKD 3.10

## Architecture

![](images/topologia2.png?raw=true)


```
                              http://*.apps.openshift.local
                                             |
--------------+------------------------------+---------------------------------+----------------
              |10.211.55.100                       |10.211.55.101                          |10.211.55.102
+-------------+--------------+      +--------------+--------------+      +--------------+------------+
| [ master.openshift.local ] |      |   [ node1.openshift.local ] |      | [ node2.openshift.local ] |
|       (Master Node)        |      |        (Compute Node)       |      |      (Compute Node)       |
|       (Infra Node)         |      |                             |      |                           |
|      (Compute Node)        |      |                             |      |                           |
+----------------------------+      +-----------------------------+      +---------------------------+

```

```
================================================================================================
          MASTER:		           NODE1:			      NODE2:
8 Cores				   8 Cores			     8 Cores
16 GB RAM			   16 GB RAM			     16 GB RAM
60GB /dev/sda - S.O		   60GB /dev/sda - S.O 		     60GB /dev/sda - S.O
20GB /dev/sdb - Docker-storage	   20GB /dev/sdb - Docker-storage    20GB /dev/sdb - Docker-storage
10GB /dev/sdc - GlusterFS 	   10GB /dev/sdc - GlusterFS	     10GB /dev/sdc - GlusterFS

Persistence Storage Registry: GlusterFS
Persistence Storage etcd      : nfs
================================================================================================
```

## Requirements

This procedure was realized with 3 hosts with CentOS 7.5 S.O with upgrade packages to this release

```
CentOS Linux release 7.5.1804 (Core)
```
## Installation

Related playbooks are kept in the ansible/playbooks directory, and basically contain the following artifacts:

• Ansible configuration file (ansible.cfg)
• Playbooks directory.
• Inventory file (inventory.ini).

1. Make clone of repository to /root directory


git clone https://github.com/netoralves/okd-production_environment.git

2. Execute basic_config.sh:
  
  1.1. Validate configured variables in script's header:

    * Exist a restriction to the script be executed in machine where that short hostname was master and execution user was root.
    * The variables must be validated to their environment, next configuration template was provisioned to stage and production environment:


    #VARIAVEIS
    MASTER="master.openshift.local"
    NODE1="node1.openshift.local"
    NODE2="node2.openshift.local"
    USER=okd
    USER_PASS="*****"
    ROOT_PASS="*****"
    
    1.2. After validate the variables, execute the script, this will perform:
    
          * Create a local user with root grants that will used by ansible playbooks (become)
          * Create a user each nodes with default grants
          * Copy ssh key between all nodes.
          * Update all O.S packages
          * Install engine ansible on master host
    
    ./basic_config.sh
 

3. Validate access on allhosts without password by okd user.
    
[okd@master ~]$ ssh node1
[okd@master ~]$ ssh node2
[okd@master ~]$ ssh master
    
    4.2. Verify the ansible version
    	[okd@master ~]$ ansible --version
        ansible 2.6.3
        ...
 
4. Execute the playbook to prepare hosts
ssh okd@master
cd install-prepare/
[okd@master install-run]$ ansible-playbook install-prepare.yml

5. Execute okd cluster installation
cd ../install-run/
[okd@master install-run]$ ./install-run.sh

# Administration

## Users and Grant access Table

### Operating System
User | Description | Password
---  |  ---                         | ---
okd  | User with root grants (sudo) | *******
root | Super user		    | *******

### OKD Users
User | Description | Password
--- | --- | ---
admin | User with administration grants on cluster (cluster-admin)  | admin@123
stage  | User with adminstration grants on stage project  and viewed grants on cicd project | stage@123
integration | User with administration grants on cicd project and viewed grants on stage project | integration@123

## Prune policy to olders builds and deployments

* Delete all implementations whose configuration don't exist more, the status was completed or with fail and the replicas counter was zero.
* By deployment configuration, keep the last N deployments whose status was completed and replicas counter was zero. (default 5)
* By deployment configuration, keep the last N deployments whose status was fail and replicas counter was zero. (Default 1)

1. To cicd project
 * Keep the 10 lasts builds and deployments who was completed with success, keep 1 was look fail and keep it during 60 minutes a build or deployment to prune.
```
[okd@master ~]$ oc adm prune builds --orphans --keep-complete=10 --keep-failed=1 --keep-younger-than=60m --confirm -n cicd
[okd@master ~]$ oc adm prune deployments --orphans --keep-complete=10 --keep-failed=1 --keep-younger-than=60m --confirm -n cicd
```

2. To stage project
 * Keep the 10 lasts builds and deployments who was completed with success, keep 1 was look fail and keep it during 60 minutes a build or deployment to prune.
```
[okd@master ~]$ oc adm prune builds --orphans --keep-complete=10 --keep-failed=1 --keep-younger-than=60m --confirm -n stage
[okd@master ~]$ oc adm prune deployments --orphans --keep-complete=10 --keep-failed=1 --keep-younger-than=60m --confirm -n stage
```
3. To prod project
 * Keep the 10 lasts builds and deployments who was completed with success, keep 1 was look fail and keep it during 60 minutes a build or deployment to prune.
```
[okd@master ~]$ oc adm prune builds --orphans --keep-complete=10 --keep-failed=1 --keep-younger-than=60m --confirm -n prod
[okd@master ~]$ oc adm prune deployments --orphans --keep-complete=10 --keep-failed=1 --keep-younger-than=60m --confirm -n prod
```


## Paths to backup / Monitoring

### Master

1. NFS Share Directory
```
[okd@master exports]$ ls
jenkins-data  keycloak  logging-es  logging-es-ops  metrics  registry  sonarqube-data
[okd@master exports]$ pwd
/exports
```

```
[okd@master exports]$ cd /etc/exports.d/
[okd@master exports.d]$ ls
jenkins.exports  keycloak.exports  openshift-ansible.exports  sonarqube.exports
```

2. GlusterFS Partition
```
[root@master ~]# fdisk -l /dev/sdc

Disk /dev/sdc: 10.7 GB, 10737418240 bytes, 20971520 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
```

3. Docker-storage Partition
```
[root@master ~]# fdisk -l /dev/sdb

Disk /dev/sdb: 21.5 GB, 21474836480 bytes, 41943040 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk label type: dos
Disk identifier: 0x0005a746

   Device Boot      Start         End      Blocks   Id  System
/dev/sdb1            2048    41943039    20970496   8e  Linux LVM

[root@master ~]# vgs docker-vg
  VG        #PV #LV #SN Attr   VSize   VFree
  docker-vg   1   1   0 wz--n- <20.00g    0

[root@master ~]# lvs /dev/docker-vg/docker-pool
  LV          VG        Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  docker-pool docker-vg -wi-ao---- <20.00g
```

### Node1

1. GlusterFS Partition
```
[root@node1 ~]# fdisk -l /dev/sdc

Disk /dev/sdc: 10.7 GB, 10737418240 bytes, 20971520 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
```

3. Docker-storage Partition
```
[root@node1 ~]# fdisk -l /dev/sdb

Disk /dev/sdb: 21.5 GB, 21474836480 bytes, 41943040 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk label type: dos
Disk identifier: 0x0005a746

   Device Boot      Start         End      Blocks   Id  System
/dev/sdb1            2048    41943039    20970496   8e  Linux LVM

[root@node1 ~]# vgs docker-vg
  VG        #PV #LV #SN Attr   VSize   VFree
  docker-vg   1   1   0 wz--n- <20.00g    0

[root@node1 ~]# lvs /dev/docker-vg/docker-pool
  LV          VG        Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  docker-pool docker-vg -wi-ao---- <20.00g
```

### Node2

1. GlusterFS Partition
```
[root@node2 ~]# fdisk -l /dev/sdc

Disk /dev/sdc: 10.7 GB, 10737418240 bytes, 20971520 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
```

3. Docker-storage Partition
```
[root@node2 ~]# fdisk -l /dev/sdb

Disk /dev/sdb: 21.5 GB, 21474836480 bytes, 41943040 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk label type: dos
Disk identifier: 0x0005a746

   Device Boot      Start         End      Blocks   Id  System
/dev/sdb1            2048    41943039    20970496   8e  Linux LVM

[root@node2 ~]# vgs docker-vg
  VG        #PV #LV #SN Attr   VSize   VFree
  docker-vg   1   1   0 wz--n- <20.00g    0

[root@node2 ~]# lvs /dev/docker-vg/docker-pool
  LV          VG        Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  docker-pool docker-vg -wi-ao---- <20.00g
```

## Troubleshoot

### Daemons

```
[root@master ~]# systemctl status origin-node.service
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
[root@node1 ~]# systemctl status origin-node.service
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
[root@node2 ~]# systemctl status origin-node.service
● origin-node.service - OpenShift Node
   Loaded: loaded (/etc/systemd/system/origin-node.service; enabled; vendor preset: disabled)
   Active: active (running) since Mon 2018-10-15 15:18:42 -03; 6 days ago
     Docs: https://github.com/openshift/origin
 Main PID: 2075 (hyperkube)
   Memory: 175.9M
   CGroup: /system.slice/origin-node.service
           └─2075 /usr/bin/hyperkube kubelet --v=2 --address=0.0.0.0 --allow-privileged=true --anon...
```

## Configuration files and Directories

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

* Main file of nodes configuration
```
/etc/origin/node/node-config.yaml
```

```
/etc/origin/master/
```


## oc Tools

```
[okd@master ~]$ oc whoami
system:admin
```

* User local access
```
[okd@master ~]$ oc login -u system:admin
Logged into "https://master.openshift.local:8443" as "system:admin" using existing credentials.

You have access to the following projects and can switch between them with 'oc project <projectname>':

  * cicd
    default
    stage
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
    prod

Using project "cicd".
```

* Remote Access

![](images/login-externo.png?raw=true)

Obs.: To install [oc tools](https://www.okd.io/download.html).

```
[okd@master ~]$ oc login
Authentication required for https://master.openshift.local:8443 (openshift)
Username: integration
Password:
Login successful.

You have access to the following projects and can switch between them with 'oc project <projectname>':

  * cicd
    stage

Using project "cicd".
```

```
[okd@master ~]$ oc get nodes
NAME        STATUS    ROLES          AGE       VERSION
node2       Ready     compute        19d       v1.10.0+b81c8f8
master      Ready     infra,master   19d       v1.10.0+b81c8f8
node1       Ready     compute        19d       v1.10.0+b81c8f8
```

```
[okd@master ~]$ oc describe node master
Name:               master
Roles:              infra,master
Labels:             beta.kubernetes.io/arch=amd64
                    beta.kubernetes.io/os=linux
                    glusterfs=registry-host
                    kubernetes.io/hostname=master
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
  InternalIP:  10.211.55.100
  Hostname:    master
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
ExternalID:                          master
Non-terminated Pods:                 (16 in total)
  Namespace                          Name                          CPU Requests  CPU Limits  Memory Requests  Memory Limits
  ---------                          ----                          ------------  ----------  ---------------  -------------
  default                            docker-registry-1-nzq49       100m (1%)     0 (0%)      256Mi (1%)       0 (0%)
  default                            glusterfs-registry-qsbnd      100m (1%)     0 (0%)      100Mi (0%)       0 (0%)
  default                            registry-console-1-5hrkl      0 (0%)        0 (0%)      0 (0%)           0 (0%)
  default                            router-1-4plwt                100m (1%)     0 (0%)      256Mi (1%)       0 (0%)
  kube-service-catalog               apiserver-hc7dl               0 (0%)        0 (0%)      0 (0%)           0 (0%)
  kube-service-catalog               controller-manager-q27dk      0 (0%)        0 (0%)      0 (0%)           0 (0%)
  kube-system                        master-api-master            0 (0%)        0 (0%)      0 (0%)           0 (0%)
  kube-system                        master-controllers-master    0 (0%)        0 (0%)      0 (0%)           0 (0%)
  kube-system                        master-etcd-master           0 (0%)        0 (0%)      0 (0%)           0 (0%)
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
[okd@master ~]$ oc describe node node1
Name:               node1
Roles:              compute
Labels:             beta.kubernetes.io/arch=amd64
                    beta.kubernetes.io/os=linux
                    glusterfs=registry-host
                    kubernetes.io/hostname=node1
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
  InternalIP:  10.211.55.101
  Hostname:    node1
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
ExternalID:                  node1
Non-terminated Pods:         (10 in total)
  Namespace                  Name                                            CPU Requests  CPU Limits  Memory Requests  Memory Limits
  ---------                  ----                                            ------------  ----------  ---------------  -------------
  cicd                       sonarqube-1-4fzzl                               200m (2%)     1 (12%)     1Gi (6%)         3Gi (19%)
  default                    glusterblock-registry-provisioner-dc-1-drzr5    0 (0%)        0 (0%)      0 (0%)           0 (0%)
  default                    glusterfs-registry-m4cpg                        100m (1%)     0 (0%)      100Mi (0%)       0 (0%)
  default                    heketi-registry-1-28mq6                         0 (0%)        0 (0%)      0 (0%)           0 (0%)
  stage                       email-2-8lkf5                                   0 (0%)        0 (0%)      0 (0%)           0 (0%)
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
[okd@master ~]$ oc describe node node2
Name:               node2
Roles:              compute
Labels:             beta.kubernetes.io/arch=amd64
                    beta.kubernetes.io/os=linux
                    glusterfs=registry-host
                    kubernetes.io/hostname=node2
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
  InternalIP:  10.211.55.102
  Hostname:    node2
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
ExternalID:                  node2
Non-terminated Pods:         (14 in total)
  Namespace                  Name                           CPU Requests  CPU Limits  Memory Requests  Memory Limits
  ---------                  ----                           ------------  ----------  ---------------  -------------
  cicd                       jenkins-2-lvlz5                0 (0%)        0 (0%)      5Mi (0%)         5Gi (32%)
  default                    glusterfs-registry-czplt       100m (1%)     0 (0%)      100Mi (0%)       0 (0%)
  stage                       file-upload-1-tqsqw            0 (0%)        0 (0%)      0 (0%)           0 (0%)
  stage                       juris-5-8bp2k                  0 (0%)        0 (0%)      0 (0%)           0 (0%)
  stage                       juris-front-5-pv6qp            0 (0%)        0 (0%)      0 (0%)           0 (0%)
  stage                       keycloak-1-bnwjw               0 (0%)        0 (0%)      0 (0%)           0 (0%)
  stage                       keycloak-postgresql-1-4xqsv    200m (2%)     300m (3%)   512Mi (3%)       512Mi (3%)
  stage                       localizacao-3-fx9t5            0 (0%)        0 (0%)      0 (0%)           0 (0%)
  stage                       ocb-admin-server-1-r87wh       0 (0%)        0 (0%)      0 (0%)           0 (0%)
  stage                       ocb-config-server-11-2xbmp     0 (0%)        0 (0%)      0 (0%)           0 (0%)
  stage                       ramo-5-ksjr9                   0 (0%)        0 (0%)      0 (0%)           0 (0%)
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

### View PODs of a specific project

```
[okd@master ~]$ oc get pods -n stage -o wide
```

```
[okd@master ~]$ oc get pods -n cicd
NAME                        READY     STATUS      RESTARTS   AGE
cicd-demo-installer-vx8jq   0/1       Completed   0          6d
jenkins-2-lvlz5             1/1       Running     0          3d
sonarqube-1-4fzzl           1/1       Running     2          6d
```

### View status of a specific POD
```
[okd@master ~]$ oc describe pod jenkins-2-lvlz5
Name:           jenkins-2-lvlz5
Namespace:      cicd
Node:           node2/10.1.0.146
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

### View services of a projec
```
[okd@master ~]$ oc get svc -n stage
```

```
[okd@master ~]$ oc get svc -n cicd
NAME           TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)     AGE
jenkins        ClusterIP   172.30.110.149   <none>        80/TCP      6d
jenkins-jnlp   ClusterIP   172.30.46.240    <none>        50000/TCP   6d
nexus          ClusterIP   172.30.255.202   <none>        8081/TCP    6d
sonarqube      ClusterIP   172.30.213.26    <none>        9000/TCP    10d
```

```
[okd@master ~]$ oc describe svc app -n stage
```

### View events of a project
```
[okd@master ~]$ oc get event -n stage  --watch
```

```
[okd@master ~]$ oc get event -n cicd  --watch
```


## Useful commands

### Generate hash to web-console password (/etc/origin/master/htpasswd)
```
openssl passwd -apr1 PASS
```

### grants privilegies to cluster administration on OKD
```
oc adm policy add-cluster-role-to-user cluster-admin USER
```

### Create a new project
```
oc new-project PROJECT
```

## Autor
**Francisco Neto** - *Initial work* - [Profile](https://github.com/netoralves)

