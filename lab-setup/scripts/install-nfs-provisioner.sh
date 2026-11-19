#!/usr/bin/env bash
# install-nfs-provisioner.sh - run as root on the CONTROL-PLANE node (needs helm + kubectl).
# Turns the control plane into a tiny NFS server and installs the NFS subdir external provisioner,
# which creates the StorageClass "nfs-client" (dynamic provisioning for unit 04).
# The worker nodes already have nfs-common from 00-common.sh.
#
#   NFS_SERVER   (required) IP of this node that workers can reach
#   NFS_PATH     export directory           (default /srv/nfs/k8s)
#   NFS_NETWORK  CIDR allowed to mount it   (default: the /24 of NFS_SERVER)
#
# LAB ONLY: the export is world-writable and uses no_root_squash.
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "Run as root (sudo -E $0)"; exit 1; }
command -v helm >/dev/null || { echo "helm not found: https://helm.sh/docs/intro/install/"; exit 1; }
NFS_SERVER="${NFS_SERVER:?Set NFS_SERVER to the IP address of this node}"
NFS_PATH="${NFS_PATH:-/srv/nfs/k8s}"
NFS_NETWORK="${NFS_NETWORK:-${NFS_SERVER%.*}.0/24}"
export KUBECONFIG="${KUBECONFIG:-/etc/kubernetes/admin.conf}"
export DEBIAN_FRONTEND=noninteractive

echo "==> NFS server exporting ${NFS_PATH} to ${NFS_NETWORK}"
apt-get install -y nfs-kernel-server
mkdir -p "$NFS_PATH"
chmod 0777 "$NFS_PATH"
LINE="${NFS_PATH} ${NFS_NETWORK}(rw,sync,no_subtree_check,no_root_squash)"
grep -qxF "$LINE" /etc/exports || echo "$LINE" >>/etc/exports
exportfs -ra
systemctl enable --now nfs-kernel-server

echo "==> NFS subdir external provisioner"
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/ >/dev/null
helm repo update >/dev/null
helm upgrade --install nfs-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
  --namespace nfs-provisioner --create-namespace \
  --set nfs.server="${NFS_SERVER}" \
  --set nfs.path="${NFS_PATH}" \
  --set storageClass.name=nfs-client \
  --wait --timeout 5m

kubectl get storageclass
