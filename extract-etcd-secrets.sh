#!/bin/bash

set -e

NAMESPACE="${NAMESPACE:-kube-system}"
DIR="${OUTPUT:-config}"

if [ -z "$CLUSTER_NAME" ]; then
	CM_NAME=$(kubectl -n $NAMESPACE get cm cilium-config -o json | jq -r -c '.data."cluster-name"')
	if [ "$CM_NAME" != "" -a "$CM_NAME" != "default" ]; then
		echo "Derived cluster-name $CM_NAME from present ConfigMap"
		CLUSTER_NAME=$CM_NAME
	else
		echo "CLUSTER_NAME is not set"
		echo "Set CLUSTER_NAME to the name of the cluster"
		exit 1
	fi
fi

mkdir -p $DIR

SECRETS=$(kubectl -n $NAMESPACE get secret "cilium-etcd-secrets" -o json | jq -c '.data | to_entries[]')
for SECRET in $SECRETS; do
  KEY=$(echo "$SECRET" | jq -r '.key')
  echo "$SECRET" | jq -r '.value' | base64 --decode > $DIR/$CLUSTER_NAME.$KEY
done


IPS=$(kubectl -n $NAMESPACE get svc cilium-etcd-external -o json | jq -r -c '.status.loadBalancer.ingress[0].ip')
if [ -z "$IPS" -o $IPS = null ]; then
	HOSTNAME=$(kubectl -n $NAMESPACE get svc cilium-etcd-external -o json | jq -r -c '.status.loadBalancer.ingress[0].hostname')
	if [ -z "$HOSTNAME" -o $HOSTNAME = null ]; then
		echo "Unable to determine hostname for service cilium-etcd-external. .status.loadBalancer.ingress[0].hostname is empty"
		exit 1
	fi
	IPS=$(host $HOSTNAME | grep address | awk '{print $NF}')
	if [ -z "$IPS" ]; then
		echo "Unable to resolve hostname $HOSTNAME to IP"
		exit 1
	fi
fi

SERVICE_NAME="${CLUSTER_NAME}.mesh.cilium.io"

cat > $DIR/$CLUSTER_NAME << EOF
endpoints:
- https://${SERVICE_NAME}:2379
EOF

echo "$IPS"  > $DIR/${SERVICE_NAME}.ips

cat >> $DIR/$CLUSTER_NAME << EOF
ca-file: '/var/lib/cilium/clustermesh/${CLUSTER_NAME}.etcd-client-ca.crt'
key-file: '/var/lib/cilium/clustermesh/${CLUSTER_NAME}.etcd-client.key'
cert-file: '/var/lib/cilium/clustermesh/${CLUSTER_NAME}.etcd-client.crt'
EOF

echo "===================================================="
echo " WARNING: The directory $DIR contains private keys."
echo "          Delete after use."
echo "===================================================="
