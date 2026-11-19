# 🧪 Lab setup: a 3-node kubeadm cluster you can rebuild in minutes

Every lab in this repo runs on one cluster: **1 control plane + 2 workers**, built with `kubeadm`, `containerd` and Calico, exactly like the exam environment (a real kubeadm cluster, not a toy).

| Node | Role | IP (default) | vCPU | RAM |
|------|------|--------------|------|-----|
| `cp1` | control plane | 192.168.56.11 | 2 | 3 GB |
| `w1`  | worker        | 192.168.56.21 | 2 | 2 GB |
| `w2`  | worker        | 192.168.56.22 | 2 | 2 GB |

Host needs: ~8 GB free RAM, ~30 GB disk, virtualization enabled.

---

## Option A: Vagrant (one command)

Requires [Vagrant](https://developer.hashicorp.com/vagrant) and VirtualBox (or the `vagrant-vmware-desktop` plugin for VMware).

```bash
cd lab-setup
vagrant up                 # ~10-15 min the first time
vagrant ssh cp1
kubectl get nodes          # all three Ready (give Calico a minute)
```

Build **one minor version behind** when you want to practise the upgrade lab:

```bash
K8S_MINOR=v1.36 vagrant up
```

> Different host network? Edit the `NODES` IPs at the top of the [Vagrantfile](Vagrantfile).

## Option B: your own Ubuntu 24.04 VMs (VMware, Proxmox, cloud, bare metal)

Create three Ubuntu 24.04 VMs with the specs above, make sure they can reach each other and the internet, then:

```bash
# on ALL three nodes (as root). Add NODE_IP=<this node's IP> if the VM has more than one NIC
sudo K8S_MINOR=v1.37 NODE_IP=<this-node-ip> bash scripts/00-common.sh

# on the control plane only
sudo NODE_IP=<control-plane-ip> bash scripts/10-control-plane.sh
#   -> writes ./join.sh (contains a bootstrap token, it is git-ignored)

# on each worker
sudo bash scripts/20-worker.sh            # needs ./join.sh, or paste the join command by hand:
#   kubeadm token create --print-join-command   (run on the control plane)
```

Add each node's name and IP to `/etc/hosts` on every node (nice to have, so `ssh w1` works).

## Add-ons used by later labs

| Script | Run on | Needed for |
|--------|--------|------------|
| [`scripts/install-metrics-server.sh`](scripts/install-metrics-server.sh) | anywhere `kubectl` works | `kubectl top`, HPA (unit 02) |
| [`scripts/install-etcd-tools.sh`](scripts/install-etcd-tools.sh) | control plane, as root | etcd backup/restore (unit 01) |

Helm is installed per the [official guide](https://helm.sh/docs/intro/install/) on the control plane.

## Snapshots: your safety net 📸

Take a snapshot of all three nodes the moment `kubectl get nodes` shows **Ready**. Break things freely, then revert.

```bash
vagrant snapshot save clean      # after the cluster is healthy
vagrant snapshot restore clean   # back to a known-good cluster
```

On VMware / Proxmox use the hypervisor's snapshot feature on all three VMs at the same time.

## Versions: record yours

Calico, etcd, metrics-server and the Gateway controller are resolved to **the latest release at install time**, unless you pin them (`CALICO_VERSION=v3.x.y` and friends). Kubernetes itself follows `K8S_MINOR`. Write the versions you actually got into [VERSIONS.md](VERSIONS.md) so a lab result is reproducible.

## Status of these scripts

- ✅ Shell syntax checked, Vagrantfile and YAML parsed in CI.
- 🔲 **A full live run on a fresh set of VMs is yours to confirm.** Tick it in [VERSIONS.md](VERSIONS.md) the first time it works for you, and open an issue or fix the script if it does not.

## Tear down

```bash
vagrant destroy -f
```
