# Practice Exam 1: broad sweep

**Time:** 2 hours · **Pass:** 66 % · **Tasks:** 14 · **Docs:** kubernetes.io, helm.sh only · **Cluster:** `cp1`, `w1`, `w2` from [lab-setup](../lab-setup/README.md).

## Setup (before the timer)

Run on `cp1`. It creates the prerequisites the tasks refer to.

```bash
kubectl create namespace backend
kubectl create namespace db
kubectl -n db run db --image=busybox:1.36 --labels=app=db --port=5432 -- \
  sh -c 'mkdir -p /www && echo db-ok > /www/index.html && httpd -f -p 5432 -h /www'
kubectl -n backend run api --image=nginx:1.26 --labels=role=api
kubectl -n backend run other --image=nginx:1.26 --labels=role=other

kubectl create deployment shop --image=nginx:1.26 --replicas=3
kubectl set resources deployment shop --requests=cpu=50m,memory=32Mi --limits=cpu=200m,memory=128Mi
kubectl expose deployment shop --port=80
```

Install the controllers you want to use for task 9: `lab-setup/scripts/install-ingress-controller.sh` (or the Gateway one) and metrics-server for task 13.

For tasks **10** and **11**, have the problems injected *without reading which is which* (ask a friend, or run `sudo bash 05-troubleshooting/scripts/break.sh kubelet-stopped` on `w2` and `... wrong-selector` on `cp1`, then do something else for a minute).

---

### 1 · etcd backup (5 %)

Create an etcd snapshot at `/opt/exam/etcd.db` and verify it.

### 2 · RBAC (7 %)

In namespace `ci`, create ServiceAccount `deploy-bot` and give it permission to `create`, `get`, `list`, `update`, `patch` **Deployments** in that namespace only. Show with `kubectl auth can-i` that it cannot delete deployments and cannot act in `default`.

### 3 · Static pod (6 %)

On node `w1`, run a static pod named `audit` using image `busybox:1.36` with the command `sleep 3600`. Verify it is running.

### 4 · Taints and tolerations (6 %)

Taint node `w2` with `team=blue:NoSchedule`. Create pod `blue-app` (`nginx:1.26`) that **runs on `w2`**. Create pod `red-app` (`nginx:1.26`) that must **not** be able to run on `w2`. Leave the taint in place.

### 5 · Init container (8 %)

Create pod `init-check` in `default`. An init container (`busybox:1.36`) writes the text `ready` to `/work/status`. The main container (`busybox:1.36`) prints the file's contents and then sleeps for 3600 seconds. `/work` is an `emptyDir` shared by both. `kubectl logs init-check` must print `ready`.

### 6 · PersistentVolume (8 %)

Create a PV `exam-pv` (200Mi, `ReadWriteOnce`, hostPath `/exam-data` on `w1`, `storageClassName: exam`, reclaim policy `Retain`) and a PVC `exam-pvc` that binds to it. Run pod `data-pod` (`nginx:1.26`) on `w1` mounting the claim at `/usr/share/nginx/html`, with `index.html` containing `exam one`. `kubectl exec data-pod -- cat /usr/share/nginx/html/index.html` must print it.

### 7 · NetworkPolicy (8 %)

In namespace `db`, pods labelled `app=db` must accept TCP 5432 **only** from pods labelled `role=api` that are in namespace `backend`. Everything else must be denied. Prove it works from `api` and does not from `other` (the `db` pod serves HTTP on 5432; the test pods have `curl`).

### 8 · Quota and LimitRange (6 %)

Create namespace `team-a`. Limit it to a maximum of 4 pods, 1 CPU of requests, and 1Gi of memory requests. Every container without explicit values must default to requests `cpu 100m / memory 64Mi` and limits `cpu 200m / memory 128Mi`. Prove it by creating a pod with no resources and showing what it received.

### 9 · Expose with Ingress or Gateway (7 %)

Route the host `shop.local` to Service `shop` (port 80) using the controller available in your cluster. Show a successful response using the right host header.

### 10 · Troubleshooting: a node (10 %)

One node is `NotReady`. Find out why and make it `Ready` again, permanently (it must survive a reboot).

### 11 · Troubleshooting: an application (10 %)

A Service in namespace `break-svc` does not serve traffic although its pods are Running. Fix the problem **without recreating the Service or the Deployment**, and prove traffic flows.

### 12 · Helm (9 %)

Add the `podinfo` repo (`https://stefanprodan.github.io/podinfo`). Install release `web` in new namespace `helm-exam` with `replicaCount=2`. Upgrade it to 3 replicas. Roll back to revision 1. Show `helm history`.

### 13 · HPA (5 %)

For Deployment `shop`, create an HorizontalPodAutoscaler with a minimum of 2 and a maximum of 6 replicas and a CPU target of 60 %.

### 14 · Node maintenance (5 %)

Safely evict all regular workloads from `w1`, keep DaemonSet pods, then make `w1` schedulable again. Show the node's state after each step.

---

**Stop the timer.** Score yourself, then open [the solutions](exam-1-solutions.md).
