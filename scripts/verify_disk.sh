#!/bin/bash


#MASTERS
COUNT=1
while [  $COUNT -lt 4 ]; do
	for host in master$COUNT;
		do
			QTD_LINHA=$(su -c "ssh $host lsblk /dev/sdc | wc -l" - okd)

			if [ $QTD_LINHA -gt 2 ]; then
				echo "Disk in use, execute clean up"
				su -c "ssh $host wipe -a /dev/sdc" - okd

			if [ $? -ne 0 ]; then
				echo "Failed to clean up host $host, verify disk /dev/sdc"					
			fi
			else
				echo "disk /dev/sdc on node $host, Clean up!"
			fi
		done
let COUNT=COUNT+1;
done

#NODES
COUNT=1
while [  $COUNT -lt 6 ]; do
	for host in node$COUNT;
		do
			QTD_LINHA=$(su -c "ssh $host lsblk /dev/sdc | wc -l" - okd)

			if [ $QTD_LINHA -gt 2 ]; then
				echo "Disk in use, execute clean up"
				su -c "ssh $host wipe -a /dev/sdc" - okd

			if [ $? -ne 0 ]; then
				echo "Failed to clean up host $host, verify disk /dev/sdc"					
			fi
			else
				echo "disk /dev/sdc on node $host, Clean up!"
			fi
		done
let COUNT=COUNT+1;
done
