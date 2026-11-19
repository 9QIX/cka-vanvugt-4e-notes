#!/usr/bin/env bash
# install-gateway-controller.sh - run where kubectl + helm + git work.
# Installs the Gateway API standard-channel CRDs and NGINX Gateway Fabric (a Gateway API controller).
# Creates the GatewayClass "nginx".
#
#   NGF_VERSION  e.g. v2.1.0  (default: latest GitHub release; override to pin)
#
# Chart values change between releases: if the install fails, run
#   helm show values oci://ghcr.io/nginx/charts/nginx-gateway-fabric --version <ver>
# and check the official install guide at docs.nginx.com/nginx-gateway-fabric.
set -euo pipefail

if [[ -z "${NGF_VERSION:-}" ]]; then
  NGF_VERSION="$(curl -fsSL https://api.github.com/repos/nginx/nginx-gateway-fabric/releases/latest | jq -r .tag_name)"
fi
[[ "$NGF_VERSION" =~ ^v[0-9]+\.[0-9]+ ]] || { echo "Could not resolve a version; set NGF_VERSION=vX.Y.Z"; exit 1; }
echo "==> NGINX Gateway Fabric ${NGF_VERSION}"

echo "==> Gateway API CRDs (standard channel)"
kubectl kustomize "https://github.com/nginx/nginx-gateway-fabric/config/crd/gateway-api/standard?ref=${NGF_VERSION}" \
  | kubectl apply --server-side -f -

echo "==> NGINX Gateway Fabric (Helm)"
helm upgrade --install ngf oci://ghcr.io/nginx/charts/nginx-gateway-fabric \
  --version "${NGF_VERSION#v}" \
  --namespace nginx-gateway --create-namespace \
  --set nginx.service.type=NodePort \
  --wait --timeout 5m

kubectl get gatewayclass
echo
echo "Gateway API version installed:"
kubectl get crd gateways.gateway.networking.k8s.io \
  -o jsonpath='{.metadata.annotations.gateway\.networking\.k8s\.io/bundle-version}{"\n"}'
