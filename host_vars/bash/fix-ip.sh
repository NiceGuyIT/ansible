#!/bin/bash

for file in $(find /home/lukepafford/IT/git/lukepafford-ansible/ansible/host_vars -type f); do
	
	CORRECT=$(awk '{if ($0 ~ "^ipv4") {print substr($0, 1, length($0)-1);}}' $file | awk '{ print $0"/24'\''"}')

	sed -i -e "s|^ipv4.*[^2][^4]'$|$CORRECT|" $file
done
