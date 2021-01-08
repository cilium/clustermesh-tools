#!/bin/bash

set -e

DIR="${OUTPUT:-config}"
KUBECONFIG="${KUBECONFIG:+--kubeconfig=${KUBECONFIG}}"

# NOTE: --dry-run=true is deprecated starting kubectl v1.18 and
# --dry-run=client should be used instead.
DRYRUN=true
MAJOR=$(kubectl version -o json | jq -r '.clientVersion.major')
MINOR=$(kubectl version -o json | jq -r '.clientVersion.minor')
if [ $MAJOR -gt 1 ] || [ $MAJOR -eq 1 -a $MINOR -ge 18 ]; then
    DRYRUN=client
fi

kubectl="kubectl $KUBECONFIG"

for SECRET in "$DIR"/*; do
	if [[ ! "$SECRET" =~ .ips$ ]]; then
		echo "--from-file=$SECRET"
	fi
done | xargs kubectl create --dry-run=$DRYRUN secret generic cilium-clustermesh -o yaml
