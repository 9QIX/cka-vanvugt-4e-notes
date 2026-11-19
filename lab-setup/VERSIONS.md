# Versions used (fill in after your first successful build)

Keeping this current is what makes a lab result reproducible. Run the commands, paste the output.

| Component | How to read it | Your value |
|-----------|----------------|------------|
| Kubernetes | `kubectl version` / `kubeadm version -o short` | |
| containerd | `containerd --version` | |
| Calico | `kubectl get pods -n calico-system -o jsonpath='{.items[0].spec.containers[0].image}'` | |
| etcd | `kubectl -n kube-system get pod -l component=etcd -o jsonpath='{.items[0].spec.containers[0].image}'` | |
| metrics-server | `kubectl -n kube-system get deploy metrics-server -o jsonpath='{.spec.template.spec.containers[0].image}'` | |
| Helm | `helm version --short` | |
| Gateway API CRDs | `kubectl get crd gateways.gateway.networking.k8s.io -o jsonpath='{.metadata.annotations.gateway\.networking\.k8s\.io/bundle-version}'` | |
| Host OS / hypervisor | | |

## Live-run checklist

- [ ] `00-common.sh` finished on all nodes
- [ ] `10-control-plane.sh` finished, `join.sh` written
- [ ] Both workers joined, `kubectl get nodes` shows 3 × `Ready`
- [ ] `kubectl get pods -A` shows no `CrashLoopBackOff`
- [ ] Snapshot taken
