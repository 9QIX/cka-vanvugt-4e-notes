# Lab 04 · StorageClass and dynamic provisioning (NFS)

**Goal:** create a PVC and watch a PV appear *automatically*, then see `Delete` reclaim work.

The course uses a hostPath-based provisioner; this repo uses the **NFS subdir external provisioner** because it works on any CPU architecture and supports `ReadWriteMany`.

## 1 · Install (lab only: the exam has storage ready)

On the control plane, as root:

```bash
sudo NFS_SERVER=192.168.56.11 bash lab-setup/scripts/install-nfs-provisioner.sh   # use YOUR control-plane IP
kubectl get storageclass          # nfs-client
kubectl -n nfs-provisioner get pods
```

Workers need `nfs-common` (installed by `00-common.sh`). If they were built another way: `sudo apt-get install -y nfs-common`.

## 2 · Claim, and watch the PV appear

```bash
cd 04-storage/manifests
kubectl apply -f 04-storageclass.yaml          # creates StorageClass local-wait and PVC nfs-claim
kubectl get pvc nfs-claim                      # Bound within seconds
kubectl get pv                                 # a pvc-<uuid> PV nobody wrote by hand
kubectl get storageclass nfs-client -o yaml | grep -E 'provisioner|reclaimPolicy|volumeBindingMode'
```

## 3 · Use it: StatefulSet with per-pod storage

```bash
kubectl apply -f 05-statefulset-with-pvc.yaml
kubectl get pods,pvc -l app=db                 # PVCs data-db-0, data-db-1
kubectl exec db-0 -- sh -c 'echo db-0 data > /data/state'
kubectl delete pod db-0
kubectl wait --for=condition=Ready pod/db-0 --timeout=120s
kubectl exec db-0 -- cat /data/state           # data survived the pod
```

On the NFS server you can see the directories: `ls /srv/nfs/k8s`.

## 4 · Reclaim policy in action

```bash
kubectl delete -f 05-statefulset-with-pvc.yaml
kubectl delete pvc -l app=db                   # StatefulSet PVCs are NOT deleted with the set
kubectl delete pvc nfs-claim
kubectl get pv                                 # PVs gone (reclaimPolicy Delete)
ls /srv/nfs/k8s                                # dirs renamed "archived-..." or removed (chart default: archiveOnDelete)
```

## 5 · Make a class the default

```bash
kubectl patch storageclass nfs-client -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
kubectl get storageclass                       # nfs-client (default)
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: default-class-claim
spec:
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 50Mi
EOF
kubectl get pvc default-class-claim            # Bound: no storageClassName was needed
kubectl delete pvc default-class-claim
kubectl patch storageclass nfs-client -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
```

## Troubleshooting

| Symptom | Check |
|---|---|
| PVC stays `Pending` | `kubectl describe pvc` Events; `kubectl -n nfs-provisioner logs deploy/nfs-provisioner-nfs-subdir-external-provisioner` |
| Pod stuck `ContainerCreating`, event "mount failed" | `nfs-common` missing on the worker, or the export does not allow that node: `showmount -e <nfs-server>` |
| PVC `Pending`, class not found | typo in `storageClassName` |

## Clean up

```bash
kubectl delete -f 04-storageclass.yaml --ignore-not-found
```

## Done when

- [ ] A PVC against a StorageClass created its PV with no manual step.
- [ ] You can make a StorageClass the default and explain what that changes for PVCs with no class.
