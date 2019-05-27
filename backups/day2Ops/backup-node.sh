#!/bin/sh

# VARIABLES
BACKUPNODEDIR=/backup/$(hostname)/$(date +%Y%m%d)

# CREATE BACKUP DIRECTORY
sudo mkdir -p ${BACKUPNODEDIR}/etc/sysconfig

# COPY CONFIG FILES AND NETWORK
sudo cp -aR /etc/origin ${BACKUPNODEDIR}/etc
sudo cp -aR /etc/sysconfig/atomic-openshift-node ${BACKUPNODEDIR}/etc/sysconfig/
sudo cp -aR /etc/dnsmasq* /etc/cni ${BACKUPNODEDIR}/etc/


# LIST OF INSTALL PACKAGES
rpm -qa | sort | sudo tee $BACKUPNODEDIR/packages.txt

# FILES COMPRESS
tar -zcvf /backup/$(hostname)/$(hostname)-$(date +%Y%m%d).tar.gz $BACKUPMASTERDIR &> /dev/null
rm -Rf ${BACKUPMASTERDIR}

# EXCLUDE COMPRESSED FILES WITH MORE THEN 7 DAYS
find /backup/ -type f -mtime +7 -name '*.tar.gz' -execdir rm -- '{}' \;
exit 0
