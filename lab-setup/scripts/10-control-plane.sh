#!/usr/bin/env bash
# 10-control-plane.sh - run as root on the FIRST control-plane node, after 00-common.sh.
# Runs kubeadm init (config file, kubeadm.k8s.io/v1beta4), installs Calico via the
# Tigera operator, and writes the worker join command to a file.
#
# Environment variables:
#   NODE_IP         (required) this node's IP, used as the API advertise address
#   POD_CIDR        pod network            (default 10.244.0.0/16)
#   SVC_CIDR        service network        (default 10.96.0.0/12)
#   CALICO_VERSION  e.g. v3.32.2           (default: latest GitHub release)
#   JOIN_OUT        where to write the join command (default /vagrant/join.sh,
#                   falls back to ./join.sh when /vagrant does not exist)
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "Run as root (sudo -E $0)"; exit 1; }
NODE_IP="${NODE_IP:?Set NODE_IP to the IP address of this node}"
POD_CIDR="${POD_CIDR:-10.244.0.0/16}"
SVC_CIDR="${SVC_CIDR:-10.96.0.0/12}"
NODE_NAME="$(hostname -s)"
K8S_VERSION="$(kubeadm version -o short)"
if [[ -d /vagrant ]]; then JOIN_OUT="${JOIN_OUT:-/vagrant/join.sh}"; else JOIN_OUT="${JOIN_OUT:-./join.sh}"; fi

echo "==> kubeadm init (${K8S_VERSION}, advertise ${NODE_IP}, pods ${POD_CIDR})"
cat >/root/kubeadm-config.yaml <<EOF
apiVersion: kubeadm.k8s.io/v1beta4
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: ${NODE_IP}
  bindPort: 6443
nodeRegistration:
  name: ${NODE_NAME}
  criSocket: unix:///run/containerd/containerd.sock
---
apiVersion: kubeadm.k8s.io/v1beta4
kind: ClusterConfiguration
kubernetesVersion: ${K8S_VERSION}
networking:
  podSubnet: ${POD_CIDR}
  serviceSubnet: ${SVC_CIDR}
EOF
kubeadm init --config /root/kubeadm-config.yaml

echo "==> kubeconfig for root and the invoking user"
mkdir -p /root/.kube
cp -f /etc/kubernetes/admin.conf /root/.kube/config
for u in "${SUDO_USER:-}" vagrant; do
  [[ -n "$u" ]] && id "$u" &>/dev/null || continue
  h="$(getent passwd "$u" | cut -d: -f6)"
  mkdir -p "$h/.kube"
  cp -f /etc/kubernetes/admin.conf "$h/.kube/config"
  chown -R "$u:$(id -gn "$u")" "$h/.kube"
done
export KUBECONFIG=/etc/kubernetes/admin.conf

echo "==> Calico (Tigera operator)"
if [[ -z "${CALICO_VERSION:-}" ]]; then
  CALICO_VERSION="$(curl -fsSL https://api.github.com/repos/projectcalico/calico/releases/latest | jq -r .tag_name)"
fi
[[ "$CALICO_VERSION" =~ ^v[0-9]+\.[0-9]+ ]] || { echo "Could not resolve Calico version; set CALICO_VERSION=vX.Y.Z"; exit 1; }
echo "    using Calico ${CALICO_VERSION}"
kubectl create -f "https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/tigera-operator.yaml"
cat <<EOF | kubectl apply -f -
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  calicoNetwork:
    nodeAddressAutodetectionV4:
      kubernetes: NodeInternalIP
    ipPools:
    - name: default-ipv4-ippool
      cidr: ${POD_CIDR}
      blockSize: 26
      encapsulation: VXLANCrossSubnet
      natOutgoing: Enabled
      nodeSelector: all()
EOF

echo "==> Writing worker join command to ${JOIN_OUT}"
{
  echo '#!/usr/bin/env bash'
  echo "$(kubeadm token create --print-join-command)"
} >"$JOIN_OUT"
chmod 600 "$JOIN_OUT"

echo
echo "Control plane is up. Watch it settle with:  kubectl get nodes -w"
echo "Calico pods:                               kubectl get pods -n calico-system"
