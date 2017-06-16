#!/bin/bash

# Get ip
for file in $(find /home/lukepafford/IT/git/lukepafford-ansible/ansible/host_vars -type f); do
        
	IP=$(grep ipv4 $file | awk -F \' '{ print $2 }' | cut -d '/' -f 1)
	FILENAME=$(basename $file)
	if [[ "${#IP}" -ge 1 ]]; then
		echo "$IP    $FILENAME" >> /etc/hosts
	fi
done
