#!/bin/sh
# By Francisco Neto
# netoralves@gmail.com

#VARIABLES
BACKUPMASTERDIR=/backup/$(hostname)/$(date +%Y%m%d)

# CREATE BACKUP DIRECTORY
sudo mkdir -p ${BACKUPMASTERDIR}/etc/sysconfig

# COPY FAILES FROM OKD CONFIG AND NETWORK
sudo cp -aR /etc/origin ${BACKUPMASTERDIR}/etc
sudo cp -aR /etc/sysconfig/ ${BACKUPMASTERDIR}/etc/sysconfig/
sudo cp -aR /etc/dnsmasq* /etc/cni ${BACKUPMASTERDIR}/etc/

# GENERATE LIST OF INSTALLED PACKAGES - DISASTER RECOVER
rpm -qa | sort | sudo tee $BACKUPMASTERDIR/packages.txt &> /dev/null

# FILES COMPRESS
tar -zcvf /backup/$(hostname)/$(hostname)-$(date +%Y%m%d).tar.gz $BACKUPMASTERDIR &> /dev/null
rm -Rf ${BACKUPMASTERDIR}

# EXCLUDE COMPRESSED FILES WITH MORE THEN 7 DAYS
find /backup/ -type f -mtime +7 -name '*.tar.gz' -execdir rm -- '{}' \;
exit 0
