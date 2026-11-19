# Lab 01 · Workload controllers

Run from `02-workloads-scheduling/manifests/`. Clean up with `kubectl delete -f <file>` after each step.

## A · Deployment, rollout, rollback

```bash
kubectl apply -f 01-deployment.yaml
kubectl rollout status deploy/web
kubectl set image deploy/web nginx=nginx:1.27
kubectl rollout history deploy/web
kubectl rollout undo deploy/web
kubectl get rs                        # two ReplicaSets: the old one is scaled to 0, not deleted
```

## B · Task: DaemonSet `nginx-daemon` on every worker

```bash
kubectl apply -f 02-daemonset.yaml
kubectl get pods -l app=nginx-daemon -o wide      # exactly one per worker, none on cp1
kubectl get ds nginx-daemon
```

Generate your own: `kubectl create deployment x --image=nginx --dry-run=client -o yaml`, then change `kind: Deployment` → `DaemonSet` and delete `replicas`, `strategy`, and `status`. This is the exam trick: there is no `kubectl create daemonset`.

**Stretch:** make it also run on the control plane (add a toleration for `node-role.kubernetes.io/control-plane:NoSchedule`).

## C · StatefulSet

```bash
kubectl apply -f 03-statefulset.yaml
kubectl get pods -l app=sts-web -w                # web-sts-0 first, then web-sts-1
kubectl exec web-sts-0 -- hostname
kubectl run dns --rm -it --image=busybox:1.36 --restart=Never -- nslookup web-sts-0.sts-headless
kubectl scale sts web-sts --replicas=0
```

## D · Init container

```bash
kubectl apply -f 04-init-container.yaml
kubectl get pod init-demo -w
kubectl exec init-demo -- cat /usr/share/nginx/html/index.html
```

## E · Native sidecar

```bash
kubectl apply -f 05-sidecar-native.yaml
kubectl get pod sidecar-demo                      # READY 2/2: app + sidecar
kubectl logs sidecar-demo -c log-shipper --tail=5
```

## Done when

- [ ] You rolled back a bad image without looking up the command.
- [ ] You can turn a generated Deployment into a DaemonSet in under 60 seconds.
- [ ] You can explain why `web-sts-0` keeps its name and a Deployment pod does not.
