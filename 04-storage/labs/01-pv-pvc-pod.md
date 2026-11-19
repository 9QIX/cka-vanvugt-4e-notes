# Lab 01 · PV, PVC and a Pod (hostPath)

**Task (from the course):** create a PersistentVolume that uses `hostPath` on `/storage`; put `index.html` containing `hello lab 11` in it; run an `nginx` pod that mounts it at `/usr/share/nginx/html`; verify with `kubectl exec`.

## 1 · Prepare the data on the node

hostPath is node-local, so pick a node (`w1`) and keep the pod on it.

```bash
ssh w1       # or: vagrant ssh w1
sudo mkdir -p /storage
echo 'hello lab 11' | sudo tee /storage/index.html
exit
```

## 2 · Apply

```bash
cd 04-storage/manifests
kubectl apply -f 01-hostpath-pv-pvc-pod.yaml
kubectl get pv,pvc
#  lab-pv   1Gi  RWO  Retain  Bound  default/lab-pvc  manual
```

## 3 · Verify

```bash
kubectl wait --for=condition=Ready pod/pv-pod --timeout=90s
kubectl exec pv-pod -- cat /usr/share/nginx/html/index.html      # hello lab 11
```

nginx serves that same file, so you can also check over HTTP: `kubectl port-forward pod/pv-pod 8080:80 &` then `curl localhost:8080` (stop it with `kill %1`).

## 4 · Write the YAML yourself

Hide the manifest and rebuild all three objects from the docs page (*Configure a Pod to Use a PersistentVolume for Storage*). Check yourself against `01-hostpath-pv-pvc-pod.yaml`.

## 5 · Break it on purpose

| Change | Expected result |
|---|---|
| PVC `storageClassName: other` | PVC `Pending`, `describe pvc` says no PV/class matches |
| PVC `storage: 5Gi` | `Pending`: PV only offers 1Gi |
| Remove `nodeSelector` from the pod | pod may land on `w2` → empty directory |

## Clean up

```bash
kubectl delete -f 01-hostpath-pv-pvc-pod.yaml
ssh w1 'sudo rm -rf /storage'
```

## Done when

- [ ] PV → PVC → Pod from a blank file in under 7 minutes.
- [ ] You can say why the pod is pinned to a node.
