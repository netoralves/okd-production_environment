#!/bin/bash

USER="okd"
USER_PASS="password"
PATH_SCRIPT="./backup-node.sh"

COUNT=1
while [  $COUNT -lt 6 ]; do

	for host in node$COUNT;
		do
    			sshpass -p $USER_PASS scp -o 'StrictHostKeyChecking no' $PATH_SCRIPT $USER@$host:~
    			sshpass -p $USER_PASS ssh -o 'StrictHostKeyChecking no' $USER@$host "sudo cp ~/backup-node.sh /etc/cron.daily/; rm -Rf ~/backup-node.sh"
			echo "Script installed - $host"
		done

let COUNT=COUNT+1;
done
