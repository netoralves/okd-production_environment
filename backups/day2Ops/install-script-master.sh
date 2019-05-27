#!/bin/bash

USER="okd"
USER_PASS="password"
PATH_SCRIPT="./backup-master.sh"

COUNT=1
while [  $COUNT -lt 4 ]; do
	for host in master$COUNT;
		do
    			sshpass -p $USER_PASS scp -o 'StrictHostKeyChecking no' $PATH_SCRIPT $USER@$host:~
    			sshpass -p $USER_PASS ssh -o 'StrictHostKeyChecking no' $USER@$host "sudo cp ~/backup-master.sh /etc/cron.daily/; rm -Rf ~/backup-master.sh"
			echo "Script installed - $host"
		done
let COUNT=COUNT+1;
done
