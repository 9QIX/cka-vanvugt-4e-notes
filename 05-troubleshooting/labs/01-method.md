# Lab 01 · The method, on broken applications

Four deliberately broken apps. For each: **observe → hypothesise → check → fix → verify.** Say your hypothesis out loud (or write it down) *before* you run the next command.

```bash
kubectl create namespace tshoot
```

## App A · ImagePullBackOff

```bash
kubectl -n tshoot create deployment a --image=nginx:doesnotexist
kubectl -n tshoot get pods
```

Find the cause from `describe`, then fix it **with a command, not by recreating**: `kubectl -n tshoot set image deployment/a nginx=nginx:1.26`.

## App B · CrashLoopBackOff

```bash
kubectl -n tshoot apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: b
spec:
  containers:
  - name: app
    image: busybox:1.36
    command: ["sh", "-c", "echo starting; cat /config/app.conf; sleep 3600"]
EOF
kubectl -n tshoot get pod b -w
kubectl -n tshoot logs b --previous
```

The file is missing. Fix by mounting a ConfigMap at `/config` (a pod's volumes cannot be edited in place: delete and recreate).

## App C · Service with no endpoints

```bash
kubectl -n tshoot create deployment c --image=nginx:1.26 --replicas=2
kubectl -n tshoot expose deployment c --port=80 --target-port=8080     # wrong target port
kubectl -n tshoot run t --rm -it --image=busybox:1.36 --restart=Never -- wget -qO- --timeout=3 http://c
```

Check `get endpoints c` (it has IPs, but the port is wrong). Compare with `describe svc c`. Fix the Service.

## App D · Pending forever

```bash
kubectl -n tshoot run d --image=nginx:1.26 --overrides='{"spec":{"nodeSelector":{"disk":"nvme"}}}'
kubectl -n tshoot describe pod d | tail -5
```

Read the `FailedScheduling` message. Two valid fixes: label a node, or remove the selector. Which is right depends on intent. Say why.

## Summary table (fill in from memory afterwards)

| Symptom | First command | Usual cause |
|---|---|---|
| ImagePullBackOff | `describe pod` | |
| CrashLoopBackOff | `logs --previous` | |
| Service unreachable | `get endpoints` | |
| Pending | `describe pod` Events | |

## Clean up

```bash
kubectl delete namespace tshoot
```
