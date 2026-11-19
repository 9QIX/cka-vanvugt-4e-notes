#!/usr/bin/env bash
# 20-worker.sh - run as root on each WORKER node, after 00-common.sh.
# Joins the node to the cluster using the join file written by 10-control-plane.sh.
#
# Environment variables:
#   JOIN_FILE  path to the join script (default /vagrant/join.sh or ./join.sh)
#
# Without Vagrant, run this on the control plane and paste the output on the worker:
#   kubeadm token create --print-join-command
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "Run as root (sudo -E $0)"; exit 1; }
if [[ -d /vagrant ]]; then JOIN_FILE="${JOIN_FILE:-/vagrant/join.sh}"; else JOIN_FILE="${JOIN_FILE:-./join.sh}"; fi

for _ in $(seq 1 60); do
  [[ -s "$JOIN_FILE" ]] && break
  echo "waiting for ${JOIN_FILE} ..."
  sleep 5
done
[[ -s "$JOIN_FILE" ]] || { echo "No join file at ${JOIN_FILE}. Create one on the control plane (see header)."; exit 1; }

bash "$JOIN_FILE"
echo "Joined. Check from the control plane:  kubectl get nodes"
