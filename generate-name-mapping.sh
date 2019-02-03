#!/bin/bash

set -e

DIR="${OUTPUT:-config}"

cat << EOF
spec:
  template:
    spec:
      hostAliases:
EOF

for IPFILE in $DIR/*.ips; do
	for IP in $(cat $IPFILE); do
		echo "      - ip: \"$IP\""
		echo "        hostnames:"
		echo "        - $(basename $IPFILE | sed -e s/.ips$//)"
	done
done
