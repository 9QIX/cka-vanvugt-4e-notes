# Lab 05 · Scheduling: selectors, affinity, taints and tolerations

## Part 1 · Task: taint `w2` so only pods with the right toleration can run there, verify, then remove the taint

```bash
kubectl taint nodes w2 storage=hdd:NoSchedule
kubectl describe node w2 | grep -i taints

kubectl apply -f manifests/08-taints-tolerations.yaml
kubectl get pods -o wide
#  plain    -> w1   (it can never land on w2)
#  tolerant -> w2   (toleration permits it, nodeSelector pins it)

# Prove the taint repels: scale a deployment and see w2 stay empty
kubectl create deployment filler --image=nginx --replicas=6
kubectl get pods -l app=filler -o wide            # all on w1

# REMOVE THE TAINT (trailing minus). Leaving it behind poisons later labs.
kubectl taint nodes w2 storage=hdd:NoSchedule-
kubectl delete -f manifests/08-taints-tolerations.yaml
kubectl delete deployment filler
```

### The three taint effects

| Effect | New pods without toleration | Pods already running |
|---|---|---|
| `NoSchedule` | not scheduled | stay |
| `PreferNoSchedule` | avoided if possible | stay |
| `NoExecute` | not scheduled | **evicted** |

## Part 2 · nodeSelector and node affinity

```bash
kubectl label node w1 disk=ssd
kubectl apply -f manifests/07-node-selector-affinity.yaml
kubectl get pods -o wide
#  on-ssd, affinity-demo -> w1
#  spread (2 replicas)   -> one on w1, one on w2 (anti-affinity)

kubectl scale deployment spread --replicas=3
kubectl get pods -l app=spread -o wide            # third replica Pending: only 2 nodes can satisfy "required"
kubectl describe pod -l app=spread | grep -A3 Events

kubectl delete -f manifests/07-node-selector-affinity.yaml
kubectl label node w1 disk-
```

## Part 3 · Why is my pod Pending?

```bash
kubectl describe pod <name>        # read "Events": 0/3 nodes are available: ...
```

Typical reasons: untolerated taint, `nodeSelector` with no matching label, insufficient CPU/memory, unbound PVC.

## Done when

- [ ] Taint added, tested, **removed**, in under 5 minutes.
- [ ] You can read a `FailedScheduling` event and name the cause.
