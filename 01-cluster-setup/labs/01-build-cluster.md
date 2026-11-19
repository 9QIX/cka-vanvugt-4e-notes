# Lab 01 · Build a 3-node cluster

**Goal:** one control plane + two workers, all `Ready`, built by you.

## Do it the repeatable way

Follow [`lab-setup/README.md`](../../lab-setup/README.md) (Vagrant or your own VMs).

## Do it by hand (so you understand the scripts)

On a fresh Ubuntu 24.04 VM, read [`00-common.sh`](../../lab-setup/scripts/00-common.sh) and type each step yourself instead of running it. Then:

```bash
# control plane
sudo kubeadm init --apiserver-advertise-address=<cp-ip> --pod-network-cidr=10.244.0.0/16
mkdir -p ~/.kube && sudo cp /etc/kubernetes/admin.conf ~/.kube/config && sudo chown $(id -u):$(id -g) ~/.kube/config
# install a CNI (see 10-control-plane.sh for Calico via the Tigera operator)

# print a fresh join command any time
kubeadm token create --print-join-command
```

### Stretch: init from a config file

```bash
sudo kubeadm init --config manifests/kubeadm-config.yaml
```

[`manifests/kubeadm-config.yaml`](../manifests/kubeadm-config.yaml) uses `kubeadm.k8s.io/v1beta4`. Generate a fresh reference yourself with `kubeadm config print init-defaults`.

## Verify

```bash
kubectl get nodes -o wide                 # 3 x Ready
kubectl get pods -A                        # nothing CrashLoopBackOff
kubectl -n kube-system get pods            # etcd, apiserver, scheduler, controller-manager on cp1
kubectl run smoke --image=nginx && kubectl wait --for=condition=Ready pod/smoke --timeout=90s && kubectl delete pod smoke
```

## Done when

- [ ] Nodes `Ready` and a pod runs on a worker.
- [ ] You snapshotted all three VMs.
- [ ] Second time around you did it in a clean VM set without opening the scripts.
