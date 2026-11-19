#!/usr/bin/env bash
# install-ingress-controller.sh - run where kubectl + helm work.
# Installs the Traefik Ingress controller as NodePort (80 -> 30080, 443 -> 30443).
#
# Why Traefik? The community ingress-nginx project was retired in March 2026, so it is
# no longer a good thing to practise on. On the exam a controller is already installed.
set -euo pipefail

helm repo add traefik https://traefik.github.io/charts >/dev/null
helm repo update >/dev/null
helm upgrade --install traefik traefik/traefik \
  --namespace traefik --create-namespace \
  --set service.type=NodePort \
  --set ports.web.nodePort=30080 \
  --set ports.websecure.nodePort=30443 \
  --wait --timeout 5m

kubectl get ingressclass
echo
echo "Test from any machine that can reach a node:  curl -H 'Host: my.fruit' http://<node-ip>:30080/"
