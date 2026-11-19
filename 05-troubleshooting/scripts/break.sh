#!/usr/bin/env bash
# break.sh - break your own cluster on purpose, then fix it. Troubleshooting is 30% of the exam.
#
#   sudo ./break.sh list              show scenarios
#   sudo ./break.sh <scenario>        break something (prints a "ticket" with the symptom only)
#   sudo ./break.sh reset             undo everything this script did, on THIS node
#
# Run as root. Scenarios marked [worker] run on a worker node; the rest on the control plane.
# Take a VM snapshot first. Solutions are in ../labs/SOLUTIONS.md: do not peek until you are stuck.
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "Run as root: sudo $0 ${1:-list}"; exit 1; }

BACKUP_DIR=/root/cka-break-backup
MANIFESTS=/etc/kubernetes/manifests
[[ -n "${KUBECONFIG:-}" && -f "${KUBECONFIG}" ]] || export KUBECONFIG=/etc/kubernetes/admin.conf

ticket() { printf '\n🎫 TICKET: %s\n   Find the cause and fix it. Then run:  %s reset   (only to clean up leftovers)\n\n' "$1" "$0"; }
need_cp() { [[ -f "$MANIFESTS/kube-apiserver.yaml" ]] || { echo "This scenario must run on the control-plane node."; exit 1; }; }
backup_manifest() { mkdir -p "$BACKUP_DIR"; [[ -f "$BACKUP_DIR/$1" ]] || cp "$MANIFESTS/$1" "$BACKUP_DIR/$1"; }

scenarios() {
  cat <<'EOF'
  kubelet-stopped     [worker] a node goes NotReady
  containerd-stopped  [worker] a node goes NotReady (different cause)
  bad-scheduler                new pods never get scheduled
  bad-apiserver                kubectl stops working entirely
  wrong-selector               a Service that has no endpoints
  bad-image                    pods that never start
  pending-resources            pods that stay Pending
  tainted-workers              pods that stay Pending (different cause)
  coredns-config               DNS fails inside the cluster
EOF
}

do_reset() {
  echo "==> restoring services on this node"
  systemctl enable --now containerd 2>/dev/null || true
  systemctl enable --now kubelet 2>/dev/null || true
  if [[ -d "$BACKUP_DIR" ]]; then
    for f in kube-scheduler.yaml kube-apiserver.yaml; do
      if [[ -f "$BACKUP_DIR/$f" ]]; then
        echo "==> restoring $f"
        cp "$BACKUP_DIR/$f" "$MANIFESTS/$f"
        rm -f "$BACKUP_DIR/$f"
      fi
    done
  fi
  if [[ -f "$MANIFESTS/kube-apiserver.yaml" ]]; then
    echo "==> waiting for the API server"
    for _ in $(seq 1 60); do kubectl get nodes >/dev/null 2>&1 && break; sleep 5; done
    kubectl delete namespace break-svc break-img break-res break-taint --ignore-not-found --wait=false || true
    kubectl taint nodes --all maintenance=true:NoSchedule- >/dev/null 2>&1 || true
    if [[ -f "$BACKUP_DIR/Corefile" ]]; then
      echo "==> restoring the CoreDNS Corefile"
      kubectl -n kube-system create configmap coredns --from-file=Corefile="$BACKUP_DIR/Corefile" --dry-run=client -o yaml \
        | kubectl apply -f -
      kubectl -n kube-system rollout restart deployment coredns
      rm -f "$BACKUP_DIR/Corefile"
    fi
  fi
  echo "Reset done on this node. On other nodes run: sudo $0 reset"
}

case "${1:-list}" in
  list) echo "Scenarios:"; scenarios ;;

  kubelet-stopped)
    systemctl disable --now kubelet
    ticket "Node $(hostname -s) shows NotReady in 'kubectl get nodes'. Make it Ready again." ;;

  containerd-stopped)
    systemctl stop containerd
    ticket "Node $(hostname -s) goes NotReady shortly after, and pods on it are failing. Restore it." ;;

  bad-scheduler)
    need_cp; backup_manifest kube-scheduler.yaml
    sed -i 's#--kubeconfig=/etc/kubernetes/scheduler.conf#--kubeconfig=/etc/kubernetes/scheduler.conff#' "$MANIFESTS/kube-scheduler.yaml"
    ticket "New pods stay Pending forever with no events. Existing pods are fine. Fix the cluster. (Try: kubectl create deployment t --image=nginx)" ;;

  bad-apiserver)
    need_cp; backup_manifest kube-apiserver.yaml
    sed -i 's#--etcd-servers=https://127.0.0.1:2379#--etcd-servers=https://127.0.0.1:2378#' "$MANIFESTS/kube-apiserver.yaml"
    ticket "kubectl returns 'connection refused' on port 6443. You cannot rely on kubectl. Bring the API back." ;;

  wrong-selector)
    kubectl create namespace break-svc
    kubectl -n break-svc create deployment web --image=nginx:1.26 --replicas=2
    kubectl -n break-svc expose deployment web --port=80 --name=web-svc
    kubectl -n break-svc patch service web-svc -p '{"spec":{"selector":{"app":"webb"}}}'
    ticket "Service web-svc in namespace break-svc does not serve traffic although both pods are Running." ;;

  bad-image)
    kubectl create namespace break-img
    kubectl -n break-img create deployment shop --image=nginx:1.99.99 --replicas=2
    ticket "Deployment shop in namespace break-img never becomes available. Get it running with a valid nginx image." ;;

  pending-resources)
    kubectl create namespace break-res
    kubectl -n break-res apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hungry
spec:
  replicas: 2
  selector:
    matchLabels:
      app: hungry
  template:
    metadata:
      labels:
        app: hungry
    spec:
      containers:
      - name: nginx
        image: nginx:1.26
        resources:
          requests:
            cpu: "64"
            memory: 512Gi
EOF
    ticket "Deployment hungry in namespace break-res has pods stuck Pending. Make them run without touching the nodes." ;;

  tainted-workers)
    kubectl taint nodes -l '!node-role.kubernetes.io/control-plane' maintenance=true:NoSchedule --overwrite
    kubectl create namespace break-taint
    kubectl -n break-taint create deployment web --image=nginx:1.26 --replicas=2
    ticket "Deployment web in namespace break-taint has Pending pods. Another admin did something to the nodes. Fix it WITHOUT editing the deployment." ;;

  coredns-config)
    need_cp; mkdir -p "$BACKUP_DIR"
    [[ -f "$BACKUP_DIR/Corefile" ]] || kubectl -n kube-system get configmap coredns -o jsonpath='{.data.Corefile}' >"$BACKUP_DIR/Corefile"
    kubectl -n kube-system get configmap coredns -o yaml | sed 's/forward \./forwrd ./' | kubectl apply -f -
    kubectl -n kube-system delete pod -l k8s-app=kube-dns
    ticket "Pods cannot resolve any name: 'nslookup kubernetes.default' fails. Restore DNS." ;;

  reset) do_reset ;;

  *) echo "Unknown scenario '${1}'"; scenarios; exit 1 ;;
esac
