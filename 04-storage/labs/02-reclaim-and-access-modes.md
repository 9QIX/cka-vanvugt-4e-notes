# Lab 02 · Reclaim policy and the PV lifecycle

Re-use the objects from lab 01 (PV `lab-pv` with `Retain`, PVC `lab-pvc`, pod `pv-pod`). Prepare `/storage` on `w1` again if you cleaned it.

## The lifecycle: Available → Bound → Released

```bash
cd 04-storage/manifests
kubectl apply -f 01-hostpath-pv-pvc-pod.yaml
kubectl get pv lab-pv                 # Bound

kubectl delete pod pv-pod
kubectl delete pvc lab-pvc
kubectl get pv lab-pv                 # Released  (Retain: data stays, PV is NOT free for reuse)
kubectl get pv lab-pv -o jsonpath='{.spec.claimRef.name}{"\n"}'    # still points to the old claim
```

A new PVC will **not** bind to a `Released` PV. Make it available again:

```bash
kubectl patch pv lab-pv -p '{"spec":{"claimRef":null}}'
kubectl get pv lab-pv                 # Available
kubectl apply -f 01-hostpath-pv-pvc-pod.yaml
kubectl get pv,pvc                    # Bound again
```

## Change the reclaim policy of an existing PV

```bash
kubectl patch pv lab-pv -p '{"spec":{"persistentVolumeReclaimPolicy":"Delete"}}'
kubectl get pv lab-pv -o custom-columns=NAME:.metadata.name,RECLAIM:.spec.persistentVolumeReclaimPolicy
kubectl patch pv lab-pv -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'
```

> hostPath PVs cannot be *deleted by Kubernetes* (there is no deleter for it): with `Delete` the PV ends up `Failed` after its PVC goes. To see `Delete` work for real, use the dynamic NFS class in [Lab 04](04-storageclass-nfs.md).

## Access modes: read this table, then prove one

| Mode | Prove it |
|---|---|
| RWO | two pods on **different** nodes claiming the same RWO PVC → second one cannot attach (cloud disks) |
| RWX | two pods on different nodes writing to the same NFS-backed PVC works |

## Clean up

```bash
kubectl delete -f 01-hostpath-pv-pvc-pod.yaml --ignore-not-found
ssh w1 'sudo rm -rf /storage'
```

## Done when

- [ ] You can explain `Released`, and bring a PV back to `Available` without recreating it.
- [ ] You know which reclaim policy deletes data and which keeps it.
