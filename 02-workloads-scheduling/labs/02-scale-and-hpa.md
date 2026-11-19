# Lab 02 · Scaling and the Horizontal Pod Autoscaler

**Prerequisite:** metrics-server (`bash lab-setup/scripts/install-metrics-server.sh`). Confirm: `kubectl top nodes` prints numbers.

## Manual scaling

```bash
kubectl create deployment scaleme --image=nginx --replicas=2
kubectl scale deployment scaleme --replicas=5
kubectl get deploy scaleme
kubectl delete deployment scaleme
```

## Autoscaling

```bash
kubectl apply -f manifests/06-hpa.yaml
kubectl get hpa php-apache -w                       # TARGETS shows 0%/50% once metrics arrive
```

In a second terminal, add load:

```bash
kubectl run load --image=busybox:1.36 --restart=Never -- /bin/sh -c "while true; do wget -q -O- http://php-apache; done"
```

Watch REPLICAS climb toward 5 (about 1-3 minutes). Then:

```bash
kubectl delete pod load
kubectl get hpa php-apache -w                       # scale-down is slow: ~5 min stabilisation window
```

The same HPA, imperatively:

```bash
kubectl autoscale deployment php-apache --min=1 --max=5 --cpu-percent=50
```

## Troubleshooting the HPA

| Symptom | Check |
|---|---|
| `TARGETS` is `<unknown>/50%` | metrics-server running? `kubectl top pods` works? Deployment has `resources.requests.cpu`? |
| Never scales up | `kubectl describe hpa php-apache` → Events and Conditions |

Clean up: `kubectl delete -f manifests/06-hpa.yaml; kubectl delete pod load --ignore-not-found`.

## Done when

- [ ] You watched replicas go up **and** down.
- [ ] You know the HPA needs `requests` on the target pods to compute a percentage.
