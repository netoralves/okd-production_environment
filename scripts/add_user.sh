#!/bin/bash

if [ $# -lt 2 ]; then
   echo "Please write the arguments: USER PASSWORD"
   exit 1
elif [ $# -gt 2 ]; then
       echo "Please write JUST the arguments: USER PASSWORD"	
       exit 1
fi

USER_PASS="password"

COUNT=1
while [  $COUNT -lt 4 ]; do
	for host in master$COUNT;
		do
    			sshpass -p $USER_PASS ssh -o 'StrictHostKeyChecking no' okd@$host "sudo htpasswd -b /etc/origin/master/htpasswd $1 $2"
    			sshpass -p $USER_PASS ssh -o 'StrictHostKeyChecking no' okd@$host "oc policy add-role-to-user view $1 -n hmlg"
    			sshpass -p $USER_PASS ssh -o 'StrictHostKeyChecking no' okd@$host "oc policy add-role-to-user view $1 -n prd"
    			echo "Grant view privilegies on HMLG and PRD projects Usuario on host: $host"
		done
let COUNT=COUNT+1;
done
