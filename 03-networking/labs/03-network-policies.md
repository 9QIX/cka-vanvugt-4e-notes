# Lab 03 · NetworkPolicy

**Task (from the course):** run a web server `lab-server` in namespace `restricted`, expose it with a Service; from `default` start two pods `sleepybox1` and `sleepybox2` (busybox, `sleep 3600`). Write a NetworkPolicy so that **only `sleepybox1` from `default`** can reach it.

> Needs a CNI that enforces policy. Calico (used by this repo's lab-setup) does.

## 1 · Build the scenario

```bash
cd 03-networking/manifests
kubectl apply -f 05-networkpolicy-lab.yaml
kubectl -n restricted wait --for=condition=Ready pod/lab-server --timeout=90s
kubectl wait --for=condition=Ready pod/sleepybox1 pod/sleepybox2 --timeout=90s
```

The file contains the policy too. For the exercise, **delete the policy and write it yourself first**:

```bash
kubectl -n restricted delete networkpolicy allow-sleepybox1-only
```

## 2 · Before the policy: both can reach it

```bash
kubectl exec sleepybox1 -- wget -qO- --timeout=3 http://lab-server.restricted | head -3
kubectl exec sleepybox2 -- wget -qO- --timeout=3 http://lab-server.restricted | head -3
```

## 3 · Write the policy (try without peeking at the manifest)

Requirements: applies to all pods in `restricted`; Ingress only; allow from pods labelled `app=sleepybox1` **in namespace `default`**.

Then apply, and test:

```bash
kubectl apply -f 05-networkpolicy-lab.yaml     # or your own file
kubectl exec sleepybox1 -- wget -qO- --timeout=3 http://lab-server.restricted | head -3   # works
kubectl exec sleepybox2 -- wget -qO- --timeout=3 http://lab-server.restricted             # "download timed out"
kubectl -n restricted describe networkpolicy allow-sleepybox1-only
```

## 4 · Experiments (this is where you actually learn it)

1. **AND → OR.** Remove the `podSelector` from the `from` item (or split it into two list items). Re-test: what changed?
2. **Default deny.** Apply `default-deny-ingress` from [`06-networkpolicy-patterns.yaml`](../manifests/06-networkpolicy-patterns.yaml) in a scratch namespace with a web pod; confirm everything is blocked.
3. **Egress + DNS.** Apply `default-deny-egress-allow-dns`; confirm `nslookup kubernetes.default` still works, and a `wget` to the web pod does not.

```bash
kubectl create ns netpol-demo
kubectl apply -f 06-networkpolicy-patterns.yaml
```

## Troubleshooting checklist

- `kubectl get netpol -A` and `kubectl describe netpol <name> -n <ns>`: which pods does `podSelector` actually match? `kubectl get pods --show-labels`.
- Is the policy in the namespace of the **destination** pod (for ingress)?
- Does your CNI enforce policy? If a deny policy changes nothing, it does not.

## Clean up

```bash
kubectl delete -f 05-networkpolicy-lab.yaml
kubectl delete -f 06-networkpolicy-patterns.yaml; kubectl delete ns netpol-demo
```

## Done when

- [ ] You wrote the namespace+pod policy from scratch in under 5 minutes.
- [ ] You can say, from reading a policy, whether a `from` is an AND or an OR.
