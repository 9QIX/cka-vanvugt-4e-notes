# Lab 06 · Requests, limits, quota, LimitRange, priority

## Quota and LimitRange

```bash
kubectl apply -f manifests/09-quota-limitrange.yaml
kubectl -n quota-lab describe quota compute-quota
kubectl -n quota-lab describe limitrange container-defaults

# A pod with no resources gets the LimitRange defaults, so quota accepts it
kubectl -n quota-lab run ok --image=nginx
kubectl -n quota-lab get pod ok -o jsonpath='{.spec.containers[0].resources}{"\n"}'

# A pod over the per-container max is rejected by the LimitRange
cat <<'EOF' | kubectl -n quota-lab apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: toobig
spec:
  containers:
  - name: nginx
    image: nginx
    resources:
      requests:
        cpu: "1"
      limits:
        cpu: "1"
EOF
#   Error ... maximum cpu usage per Container is 500m, but limit is 1

# Fill the pod quota: it allows 5 and "ok" already counts as one
for i in 1 2 3 4 5; do kubectl -n quota-lab run p$i --image=nginx; done
#   p1-p4 are created; p5 fails:
#   forbidden: exceeded quota: compute-quota, requested: pods=1, used: pods=5, limited: pods=5
kubectl -n quota-lab describe quota compute-quota
```

**Question to answer:** why did `ok` succeed with no resources in its spec? (Answer: the LimitRange injected defaults; without it the compute quota would reject the pod.)

## Memory limits are enforced: OOMKill

Free the pod quota first, otherwise the next pod is rejected:

```bash
kubectl -n quota-lab delete pod --all
```

```bash
cat <<'EOF' | kubectl -n quota-lab apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: oom
spec:
  restartPolicy: Never
  containers:
  - name: stress
    image: polinux/stress
    command: ["stress", "--vm", "1", "--vm-bytes", "200M", "--vm-hang", "1"]
    resources:
      limits:
        memory: 100Mi
      requests:
        memory: 50Mi
EOF
kubectl -n quota-lab get pod oom -w
kubectl -n quota-lab describe pod oom | grep -A3 'Last State\|State:'   # Reason: OOMKilled
```

## PriorityClass

```bash
kubectl apply -f manifests/10-priorityclass.yaml
kubectl get priorityclass
kubectl get pod important -o jsonpath='{.spec.priority}{"\n"}'      # 100000
kubectl delete -f manifests/10-priorityclass.yaml
```

## Clean up

```bash
kubectl delete namespace quota-lab
```

## Done when

- [ ] You can write a ResourceQuota and LimitRange without the docs.
- [ ] You can explain requests vs limits and name the symptom of each being wrong (Pending vs OOMKilled/throttling).
