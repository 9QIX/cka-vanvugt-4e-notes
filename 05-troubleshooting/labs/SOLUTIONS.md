# ⚠️ Spoilers: solutions to the `break.sh` scenarios

Try first. Then read **one** solution, close this file, and redo the scenario without it.

---

<details>
<summary><b>kubelet-stopped</b> [worker]</summary>

```bash
systemctl status kubelet                   # inactive (dead), disabled
sudo systemctl enable --now kubelet
```

Cause: the kubelet is the node's agent; when it stops posting status the node goes `NotReady` after ~40 s. Always check `enable` too, otherwise it does not survive a reboot.
</details>

<details>
<summary><b>containerd-stopped</b> [worker]</summary>

```bash
systemctl status kubelet                   # running, but complains it cannot reach the runtime
sudo journalctl -u kubelet -n 30 --no-pager   # ... container runtime is not running / connection refused
systemctl status containerd                # inactive
sudo systemctl enable --now containerd
```

Cause: kubelet is fine; the container runtime it depends on is down.
</details>

<details>
<summary><b>bad-scheduler</b></summary>

```bash
kubectl -n kube-system get pods            # kube-scheduler-cp1 CrashLoopBackOff
kubectl -n kube-system logs kube-scheduler-cp1      # unable to load kubeconfig ... scheduler.conff
sudo grep kubeconfig /etc/kubernetes/manifests/kube-scheduler.yaml
sudo vi /etc/kubernetes/manifests/kube-scheduler.yaml    # --kubeconfig=/etc/kubernetes/scheduler.conf  (one 'f')
kubectl get pods -A | grep scheduler       # recreated by the kubelet
```

Why "Pending with no events": no scheduler means nothing ever emits `FailedScheduling`.
</details>

<details>
<summary><b>bad-apiserver</b></summary>

```bash
kubectl get nodes                          # connection refused: kubectl is useless now
sudo crictl ps -a | grep apiserver         # Exited / restarting
sudo crictl logs $(sudo crictl ps -a --name kube-apiserver -q | head -1) 2>&1 | tail
#   ... dial tcp 127.0.0.1:2378: connect: connection refused   (etcd listens on 2379)
sudo vi /etc/kubernetes/manifests/kube-apiserver.yaml        # --etcd-servers=https://127.0.0.1:2379
# wait ~1 minute
kubectl get nodes
```

Skill demonstrated: when the API is down you work below Kubernetes: `crictl`, manifests, kubelet journal.
</details>

<details>
<summary><b>wrong-selector</b></summary>

```bash
kubectl -n break-svc get svc,endpoints web-svc       # endpoints: <none>
kubectl -n break-svc get pods --show-labels          # app=web
kubectl -n break-svc describe svc web-svc | grep Selector     # app=webb
kubectl -n break-svc patch svc web-svc -p '{"spec":{"selector":{"app":"web"}}}'
kubectl -n break-svc get endpoints web-svc           # two IPs
kubectl -n break-svc run t --rm -it --image=busybox:1.36 --restart=Never -- wget -qO- --timeout=3 http://web-svc | head -3
```
</details>

<details>
<summary><b>bad-image</b></summary>

```bash
kubectl -n break-img get pods                        # ImagePullBackOff
kubectl -n break-img describe pod -l app=shop | tail -8     # manifest for nginx:1.99.99 not found
kubectl -n break-img set image deployment/shop nginx=nginx:1.26
kubectl -n break-img rollout status deployment/shop
```

(The container is named `nginx` because `kubectl create deployment` names it after the image.)
</details>

<details>
<summary><b>pending-resources</b></summary>

```bash
kubectl -n break-res describe pod -l app=hungry | tail -6     # 0/3 nodes available: Insufficient cpu, Insufficient memory
kubectl -n break-res set resources deployment/hungry --requests=cpu=50m,memory=64Mi
kubectl -n break-res rollout status deployment/hungry
```

The pods are Pending because *no node can ever satisfy the request*; adding capacity is impossible here, so lower the request.
</details>

<details>
<summary><b>tainted-workers</b></summary>

```bash
kubectl -n break-taint describe pod -l app=web | tail -4       # untolerated taint maintenance=true
kubectl describe node w1 | grep -i taint
kubectl taint nodes -l '!node-role.kubernetes.io/control-plane' maintenance=true:NoSchedule-
kubectl -n break-taint get pods -o wide
```

The task said not to edit the deployment, so adding a toleration is the wrong fix. Remove the taint (trailing `-`).
</details>

<details>
<summary><b>coredns-config</b></summary>

```bash
kubectl -n kube-system get pods -l k8s-app=kube-dns          # CrashLoopBackOff
kubectl -n kube-system logs -l k8s-app=kube-dns --tail=5     # Unknown directive 'forwrd'
kubectl -n kube-system edit configmap coredns                # forwrd -> forward
kubectl -n kube-system rollout restart deployment coredns
kubectl run t --rm -it --image=busybox:1.36 --restart=Never -- nslookup kubernetes.default
```
</details>
