# Lab 04 · Upgrade the control plane and a worker (one minor version)

**Prerequisite:** a cluster built **one minor behind** the target. With Vagrant: `K8S_MINOR=v1.36 vagrant up`. Do this lab on a snapshot you can revert.

Set the two versions once (adjust to your reality):

```bash
OLD=v1.36   # what the cluster runs now
NEW=v1.37   # the target minor
```

> Always cross-check with the official page **Upgrading kubeadm clusters** on kubernetes.io. This lab mirrors it; the docs win if they differ.

## A · Control plane (`cp1`)

```bash
# 1. point apt at the new minor
sudo sed -i "s#/${OLD}/#/${NEW}/#" /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
apt-cache madison kubeadm | head -5          # pick the newest 1.37.x-* build
TARGET=1.37.0-1.1                            # <- replace with the version you picked from madison

# 2. upgrade kubeadm
sudo apt-mark unhold kubeadm && sudo apt-get install -y kubeadm="${TARGET}" && sudo apt-mark hold kubeadm
kubeadm version -o short

# 3. plan and apply
sudo kubeadm upgrade plan
sudo kubeadm upgrade apply "v${TARGET%%-*}"   # e.g. v1.37.0

# 4. drain, upgrade kubelet + kubectl, restart, uncordon
kubectl drain cp1 --ignore-daemonsets
sudo apt-mark unhold kubelet kubectl
sudo apt-get install -y kubelet="${TARGET}" kubectl="${TARGET}"
sudo apt-mark hold kubelet kubectl
sudo systemctl daemon-reload && sudo systemctl restart kubelet
kubectl uncordon cp1
```

## B · Worker (`w1`)

On **`w1`**:

```bash
sudo sed -i "s#/${OLD}/#/${NEW}/#" /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
TARGET=1.37.0-1.1                            # same build as the control plane
sudo apt-mark unhold kubeadm && sudo apt-get install -y kubeadm="${TARGET}" && sudo apt-mark hold kubeadm
sudo kubeadm upgrade node
```

On **`cp1`** (workers are drained from where `kubectl` works):

```bash
kubectl drain w1 --ignore-daemonsets --delete-emptydir-data
```

Back on **`w1`**:

```bash
sudo apt-mark unhold kubelet kubectl
sudo apt-get install -y kubelet="${TARGET}" kubectl="${TARGET}"
sudo apt-mark hold kubelet kubectl
sudo systemctl daemon-reload && sudo systemctl restart kubelet
```

On **`cp1`**:

```bash
kubectl uncordon w1
kubectl get nodes        # cp1 and w1 show the new version, w2 the old one (a skew that is allowed)
```

Repeat section B for `w2` if you want the full set.

## Verify

```bash
kubectl get nodes -o wide
kubectl -n kube-system get pods     # control-plane pods running the new version
kubectl version
```

## Done when

- [ ] Control plane **and** one worker upgraded, workloads still running.
- [ ] You can recite the per-node order: *kubeadm → upgrade apply/node → drain → kubelet+kubectl → restart → uncordon*.
- [ ] You reverted the snapshot and did it a second time using only the docs page.
