# Practice Exam 2: upgrade, Gateway API/TLS, dynamic storage, harder troubleshooting

**Time:** 2 hours · **Pass:** 66 % · **Tasks:** 12 · **Docs:** kubernetes.io, helm.sh only.

This one is harder: it needs a cluster built **one minor version behind** (`K8S_MINOR=v1.36 vagrant up`, see [Lab 04](../01-cluster-setup/labs/04-upgrade.md)), the Gateway API controller, and the NFS provisioner.

## Setup (before the timer)

```bash
bash lab-setup/scripts/install-gateway-controller.sh
bash lab-setup/scripts/install-metrics-server.sh
sudo NFS_SERVER=<cp1-ip> bash lab-setup/scripts/install-nfs-provisioner.sh   # on cp1, as root

kubectl create namespace apps
kubectl -n apps create deployment web --image=nginx:1.26 --replicas=2
kubectl -n apps expose deployment web --port=80
kubectl label node w1 disk=ssd
```

For tasks **9**, **10** and **11**, have the faults injected without remembering which is which (`bad-scheduler`, `coredns-config`, `bad-image` + `pending-resources` from `05-troubleshooting/scripts/break.sh`). Tasks 9 and 10 break the cluster, so expect to fix them early; do task 1 (the upgrade) **before** injecting anything.

---

### 1 · Upgrade (10 %)

Upgrade the control plane `cp1` and the worker `w1` to the next minor Kubernetes version, one node at a time, with the workload staying available. Leave `w2` as it is.

### 2 · Certificate-based user (8 %)

Create a client certificate for user `ana` (group `dev`) signed by the cluster CA via the CSR API. Grant `ana` read-only access (`view` ClusterRole) in namespace `apps` only. Prove she can list pods in `apps` and cannot in `default`.

### 3 · DaemonSet (6 %)

Create DaemonSet `agent` (`busybox:1.36`, `sleep 3600`) in namespace `apps` so that it runs on **all** nodes, including the control plane.

### 4 · Affinity (7 %)

In namespace `apps`: (a) pod `fast` (`nginx:1.26`) must run **only** on nodes labelled `disk=ssd`. (b) Deployment `spread` (`nginx:1.26`, 2 replicas) must place each replica on a **different node**.

### 5 · Gateway API with TLS (10 %)

Expose Service `web` (namespace `apps`) over **HTTPS** on host `web.example.test` using Gateway API. Create the certificate yourself (self-signed is fine). Show the Gateway is `Programmed` and the route is `Accepted`, then fetch the page with `curl`.

### 6 · NetworkPolicy, egress (7 %)

In namespace `apps`, pods labelled `app=web` may send traffic **only** to DNS (UDP/TCP 53 in `kube-system`) and to pods labelled `app=cache` in the same namespace on TCP 6379. All other egress from them is denied.

### 7 · Dynamic storage (7 %)

Create a PVC `reports` in `apps` (100Mi, `ReadWriteMany`) using the NFS StorageClass. Run Deployment `reporter` (busybox, 2 replicas) that mounts it at `/reports` in both pods and writes `hello` to `/reports/<pod-name>.txt`. Prove both files are visible from **either** pod.

### 8 · ConfigMap and Secret (6 %)

In `apps`, create ConfigMap `site-config` (`color=green`, `title=Exam 2`) and Secret `site-secret` (`token=abc123`). Run pod `site` (`busybox:1.36`, `sleep 3600`) with `color` as env var `SITE_COLOR`, the whole ConfigMap mounted at `/etc/site`, and the Secret mounted read-only at `/etc/secret`.

### 9 · Troubleshooting: scheduling (10 %)

New pods are not being scheduled anywhere. Existing ones keep running. Fix the cluster.

### 10 · Troubleshooting: DNS (8 %)

Name resolution fails inside the cluster. Restore it and show a Service name resolving from a pod.

### 11 · Troubleshooting: two broken deployments (8 %)

Deployment `shop` in namespace `break-img` and Deployment `hungry` in namespace `break-res` do not become available. Fix both **without changing the node configuration**, and show them available.

### 12 · etcd restore (5 %)

Create namespace `lost-and-found` containing a ConfigMap `note`. Take an etcd snapshot to `/opt/exam/etcd2.db`. Delete the namespace. Restore the snapshot so that the namespace and its ConfigMap are back, and show them. (Do this task last: it restarts the control plane's etcd.)

---

**Stop the timer.** Score yourself, then open [the solutions](exam-2-solutions.md).
