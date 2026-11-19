# Lab 02 · Static pod on a worker

**Task:** on node `w1`, run a static pod named `mypod` using the `nginx` image, and verify it started.

## Steps

```bash
ssh w1                                         # or: vagrant ssh w1
sudo mkdir -p /etc/kubernetes/manifests        # exists by default on kubeadm nodes
sudo tee /etc/kubernetes/manifests/mypod.yaml >/dev/null <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: mypod
spec:
  containers:
  - name: nginx
    image: nginx
EOF
```

(The same manifest is in [`manifests/static-pod-mypod.yaml`](../manifests/static-pod-mypod.yaml).)

## Verify

```bash
# on w1: the runtime sees it even if the API server is down
sudo crictl ps | grep nginx

# on cp1: a read-only "mirror pod" appears, suffixed with the node name
kubectl get pod -o wide        # mypod-w1
```

## Understand it

- The kubelet watches `staticPodPath` (find it: `grep staticPodPath /var/lib/kubelet/config.yaml`).
- You **cannot** delete a static pod with `kubectl delete`; the kubelet recreates it. Delete the file instead.

```bash
sudo rm /etc/kubernetes/manifests/mypod.yaml    # pod disappears
```

## Done when

- [ ] You can do it in under 3 minutes from a blank terminal.
- [ ] You can say where the control-plane static pod manifests are and why editing them restarts the component.
