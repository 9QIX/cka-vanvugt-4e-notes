#!/usr/bin/env bash
# install-metrics-server.sh - run where kubectl works. Needed for `kubectl top` and HPA labs.
# Adds --kubelet-insecure-tls because kubeadm kubelet certs are self-signed (LAB ONLY).
set -euo pipefail

kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl -n kube-system patch deployment metrics-server --type=json \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
kubectl -n kube-system rollout status deployment/metrics-server --timeout=180s
echo "Try in ~1 minute:  kubectl top nodes"
