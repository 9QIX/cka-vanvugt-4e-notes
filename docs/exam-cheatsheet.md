# CKA cheat sheet: speed is a skill

Everything here is allowed on the real exam: it is shell setup and `kubectl` you type yourself. The exam is open-book for **kubernetes.io** and **helm.sh** docs only.

## 1 · Shell setup (first 60 seconds)

```bash
alias k=kubectl
export do="--dry-run=client -o yaml"
export now="--force --grace-period 0"
source <(kubectl completion bash)
complete -o default -F __start_kubectl k

# vim: spaces, not tabs (YAML!)
cat >> ~/.vimrc <<'EOF'
set expandtab tabstop=2 shiftwidth=2 autoindent
EOF
```

Usage: `k run web --image=nginx $do > pod.yaml` · `k delete pod web $now`.

## 2 · First line of every task

```bash
kubectl config use-context <the-context-the-task-gives-you>
```

Skipping this is the classic way to lose a whole task by working in the wrong cluster.

## 3 · Imperative commands that write the YAML for you

| Need | Command |
|---|---|
| Pod | `k run NAME --image=nginx --port=80 [--labels=a=b] [-- cmd args]` |
| Deployment | `k create deployment NAME --image=nginx --replicas=3` |
| Service for a deploy | `k expose deployment NAME --port=80 --target-port=8080 --type=NodePort` |
| Job / CronJob | `k create job NAME --image=busybox -- echo hi` · `k create cronjob NAME --image=busybox --schedule="*/5 * * * *" -- date` |
| ConfigMap / Secret | `k create configmap NAME --from-literal=k=v --from-file=f` · `k create secret generic NAME --from-literal=k=v` |
| ServiceAccount | `k create sa NAME` |
| Role / binding | `k create role R --verb=get,list --resource=pods` · `k create rolebinding B --role=R --user=U` (or `--serviceaccount=ns:sa`, `--group=G`) |
| ClusterRole / binding | `k create clusterrole ...` · `k create clusterrolebinding ... --clusterrole=...` |
| Ingress | `k create ingress NAME --class=CLASS --rule="host/path=svc:port"` |
| Quota | `k create quota NAME --hard=pods=4,requests.cpu=1` |
| Namespace | `k create ns NAME` |
| HPA | `k autoscale deployment NAME --min=2 --max=6 --cpu-percent=60` |
| Scale / image | `k scale deploy NAME --replicas=5` · `k set image deploy/NAME c=img:tag` |
| Rollout | `k rollout status\|history\|undo deploy/NAME` |
| Resources | `k set resources deploy/NAME --requests=cpu=50m --limits=cpu=200m` |
| Taint | `k taint nodes N key=val:NoSchedule` (remove: trailing `-`) |
| Label | `k label node N disk=ssd` (remove: `disk-`) |

No generator? DaemonSet: generate a Deployment, change `kind`, delete `replicas`/`strategy`. PV/PVC/NetworkPolicy/StorageClass/Gateway: copy from the docs and edit.

## 4 · Finding things fast

```bash
k explain pod.spec.containers.resources            # field docs, offline
k explain pod.spec --recursive | less
k api-resources                                     # kinds, short names, namespaced?
k get pods -A -o wide --show-labels
k get pods -o jsonpath='{.items[*].metadata.name}'
k get pods -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName
k get pods --sort-by=.metadata.creationTimestamp
k get events --sort-by=.lastTimestamp -A
k config get-contexts
```

## 5 · Debugging reflexes

```bash
k describe <thing>               # Events are at the BOTTOM
k logs <pod> [-c ctr] [--previous] [-f]
k exec -it <pod> -- sh           # note the --
k run t --rm -it --image=busybox:1.36 --restart=Never -- sh
k get endpoints <svc>            # empty = selector mismatch
k auth can-i <verb> <resource> --as=<user> -n <ns>
systemctl status kubelet ; journalctl -u kubelet -n 100 --no-pager
sudo crictl ps -a ; sudo crictl logs <id>
```

## 6 · Bookmarks to have open (kubernetes.io)

| Topic | Search for |
|---|---|
| etcd backup/restore | "Operating etcd clusters for Kubernetes" |
| Upgrades | "Upgrading kubeadm clusters" |
| NetworkPolicy | "Network Policies" |
| PV/PVC | "Configure a Pod to Use a PersistentVolume for Storage" |
| Ingress / Gateway API | "Ingress" · "Gateway API" |
| Taints | "Taints and Tolerations" |
| RBAC | "Using RBAC Authorization" |
| Certificates for users | "Certificates and Certificate Signing Requests" |
| Cheat sheet | "kubectl Quick Reference" |

## 7 · Time management

- ~15-20 tasks in 2 hours = **about 6 minutes each**.
- No progress after ~7 minutes → **flag it and move on**.
- Do the cheap, high-weight tasks first; troubleshooting tasks are 30 % in total, so do not sacrifice them.
- Last 15 minutes: flagged tasks only. Re-verify the ones you finished quickly.
- **Verify every task** with a real check (`get`, `exec`, `curl`), not "the YAML applied".

## 8 · Gotchas worth a sticky note

| | |
|---|---|
| `kubectl exec pod -- cmd` | the `--` is required on current versions |
| kubeadm config API | `kubeadm.k8s.io/v1beta4` (v1beta3 is rejected by current kubeadm) |
| etcd restore | restores into a **new** `--data-dir`; then change the `hostPath` in `etcd.yaml` |
| Static pod manifests | `/etc/kubernetes/manifests/`; never keep backups of a manifest in that directory |
| Pod spec edits | most fields are immutable: delete and recreate (`k replace --force -f x.yaml`) |
| Taint removal | trailing `-` |
| NetworkPolicy AND vs OR | one list item with two selectors = AND; two items = OR |
| `drain` | needs `--ignore-daemonsets` (and `--delete-emptydir-data` if pods use emptyDir) |
