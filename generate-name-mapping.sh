#!/bin/bash

set -e

DIR="${OUTPUT:-config}"

echo "hostAliases:"

for IPFILE in $DIR/*.ips; do
	for IP in $(cat $IPFILE); do
		echo "- ip: \"$IP\""
		echo "  hostnames:"
		echo "  - $(basename $IPFILE | sed -e s/.ips$//)"
	done
done
