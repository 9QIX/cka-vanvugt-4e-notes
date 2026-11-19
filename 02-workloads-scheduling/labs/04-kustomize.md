# Lab 04 · Kustomize

Files: [`manifests/kustomize/`](../manifests/kustomize). A plain `base` plus a `prod` overlay that changes the name prefix, namespace, replica count, image tag and labels, without editing the base.

```bash
cd 02-workloads-scheduling/manifests/kustomize

# 1. See what the base produces
kubectl kustomize base

# 2. See what the overlay produces (diff against the base in your head)
kubectl kustomize overlays/prod

# 3. Apply it
kubectl create namespace kustomize-prod
kubectl apply -k overlays/prod
kubectl -n kustomize-prod get deploy,svc,pods --show-labels
#   -> prod-web, 3 replicas, image nginx:1.27, label env=prod

# 4. Remove it
kubectl delete -k overlays/prod
kubectl delete namespace kustomize-prod
```

## Practise

1. Add a second overlay `overlays/dev` with `namePrefix: dev-`, 1 replica, namespace `kustomize-dev`.
2. In the prod overlay add `patches:` that sets a memory limit of `128Mi` on the container (strategic-merge patch or JSON 6902).

## Done when

- [ ] You can write a `kustomization.yaml` with `resources`, `namespace`, `images`, `replicas` from memory.
- [ ] You know `kubectl apply -k` vs `kubectl kustomize` (apply vs render).
