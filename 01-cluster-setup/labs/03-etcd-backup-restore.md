# Lab 03 · etcd backup and restore

**Task:** back up etcd, delete some resources, restore the backup, and prove the resources are back.

> Run everything on the control plane (`cp1`). First time only: `sudo bash lab-setup/scripts/install-etcd-tools.sh` (the exam has the tools installed already).

## 1 · Create something to lose

```bash
kubectl create namespace etcd-lab
kubectl -n etcd-lab create deployment keepme --image=nginx --replicas=2
kubectl -n etcd-lab get deploy,pods
```

## 2 · Back up

```bash
sudo ETCDCTL_API=3 etcdctl snapshot save /opt/etcd-backup.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

sudo etcdutl snapshot status /opt/etcd-backup.db --write-out=table   # sanity check
```

## 3 · Destroy

```bash
kubectl delete namespace etcd-lab
kubectl get ns | grep etcd-lab || echo "gone"
```

## 4 · Restore into a new directory

```bash
sudo etcdutl snapshot restore /opt/etcd-backup.db --data-dir /var/lib/etcd-restore
```

## 5 · Point etcd at the restored data

```bash
sudo cp /etc/kubernetes/manifests/etcd.yaml /root/etcd.yaml.bak     # always keep a copy
sudo vi /etc/kubernetes/manifests/etcd.yaml
#   volumes:
#   - hostPath:
#       path: /var/lib/etcd-restore      # <- was /var/lib/etcd
#       type: DirectoryOrCreate
#     name: etcd-data
```

The kubelet notices the change and recreates etcd. Wait 1-2 minutes; `kubectl` will fail briefly.

```bash
sudo crictl ps | grep etcd           # container restarted
kubectl get nodes                    # API is back
```

## 6 · Prove it

```bash
kubectl -n etcd-lab get deploy,pods  # the namespace and deployment are back
```

Clean up: `kubectl delete ns etcd-lab`.

## If it goes wrong

| Symptom | Likely cause |
|---|---|
| `connection refused` on 6443 for > 3 min | typo in `etcd.yaml`; `sudo crictl ps -a`, `sudo journalctl -u kubelet -n 50`; restore `/root/etcd.yaml.bak` |
| Resources not back | the volume still points to the old `/var/lib/etcd` |
| `snapshot save` TLS errors | wrong cert paths; read them from `/etc/kubernetes/manifests/etcd.yaml` |

## Done when

- [ ] Whole backup+destroy+restore+verify cycle in under 7 minutes, docs allowed.
- [ ] You can find cert paths from the etcd manifest without help.
