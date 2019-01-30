#!/bin/bash

set -e

DIR="${OUTPUT:-config}"

for SECRET in $DIR/*; do
	if [[ ! "$SECRET" =~ .ips$ ]]; then
		ARGS="$ARGS --from-file=$SECRET"
	fi
done

kubectl create --dry-run=true secret generic cilium-clustermesh $ARGS -o yaml
