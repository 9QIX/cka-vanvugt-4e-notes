#!/usr/bin/env bash
# install-etcd-tools.sh - run as root on the CONTROL-PLANE node.
# Installs etcdctl + etcdutl matching the etcd version your cluster runs.
# (On the real exam these are already installed; this is only for your own lab.)
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "Run as root"; exit 1; }
export KUBECONFIG="${KUBECONFIG:-/etc/kubernetes/admin.conf}"

IMAGE="$(kubectl -n kube-system get pod -l component=etcd -o jsonpath='{.items[0].spec.containers[0].image}')"
VER="${IMAGE##*:}"   # e.g. 3.6.5-0
VER="${VER%-*}"      # e.g. 3.6.5
case "$(uname -m)" in
  x86_64)  ARCH=amd64 ;;
  aarch64) ARCH=arm64 ;;
  *) echo "Unsupported arch $(uname -m)"; exit 1 ;;
esac

echo "==> etcd ${VER} (${ARCH}) from the official release"
TMP="$(mktemp -d)"
curl -fsSL "https://github.com/etcd-io/etcd/releases/download/v${VER}/etcd-v${VER}-linux-${ARCH}.tar.gz" | tar -xz -C "$TMP"
install -m 0755 "$TMP"/etcd-v"${VER}"-linux-"${ARCH}"/etcdctl /usr/local/bin/etcdctl
install -m 0755 "$TMP"/etcd-v"${VER}"-linux-"${ARCH}"/etcdutl /usr/local/bin/etcdutl
rm -rf "$TMP"
etcdctl version
etcdutl version
