# Practice Exam 1: solutions

> One way to do each task. Yours may differ and still be correct: judge it by the **verification**, not by matching these commands.
> Assumes `alias k=kubectl` and `export do="--dry-run=client -o yaml"`.

### 1 · etcd backup

```bash
sudo mkdir -p /opt/exam
sudo ETCDCTL_API=3 etcdctl snapshot save /opt/exam/etcd.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
sudo etcdutl snapshot status /opt/exam/etcd.db -w table        # verification: hash, revision, total keys
```

### 2 · RBAC

```bash
k create namespace ci
k -n ci create serviceaccount deploy-bot
k -n ci create role deployer --verb=create,get,list,update,patch --resource=deployments
k -n ci create rolebinding deployer-bot --role=deployer --serviceaccount=ci:deploy-bot
SA=system:serviceaccount:ci:deploy-bot
k auth can-i create deployments -n ci --as=$SA          # yes
k auth can-i delete deployments -n ci --as=$SA          # no
k auth can-i create deployments -n default --as=$SA     # no
```

### 3 · Static pod

On `w1`:

```bash
sudo tee /etc/kubernetes/manifests/audit.yaml >/dev/null <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: audit
spec:
  containers:
  - name: busybox
    image: busybox:1.36
    command: ["sleep", "3600"]
EOF
```

Verification (on `cp1`): `k get pod audit-w1`.

### 4 · Taint and tolerations

```bash
k taint nodes w2 team=blue:NoSchedule
cat <<'EOF' | k apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: blue-app
spec:
  nodeSelector:
    kubernetes.io/hostname: w2
  tolerations:
  - key: team
    operator: Equal
    value: blue
    effect: NoSchedule
  containers:
  - name: nginx
    image: nginx:1.26
EOF
k run red-app --image=nginx:1.26
k get pods -o wide         # blue-app on w2; red-app on w1 (the taint repels it from w2)
```

`red-app` has no toleration, so it can never run on `w2`.

### 5 · Init container

```bash
cat <<'EOF' | k apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: init-check
spec:
  initContainers:
  - name: writer
    image: busybox:1.36
    command: ["sh", "-c", "echo ready > /work/status"]
    volumeMounts:
    - {name: work, mountPath: /work}
  containers:
  - name: main
    image: busybox:1.36
    command: ["sh", "-c", "cat /work/status; sleep 3600"]
    volumeMounts:
    - {name: work, mountPath: /work}
  volumes:
  - name: work
    emptyDir: {}
EOF
k logs init-check            # ready
```

### 6 · PersistentVolume

```bash
ssh w1 'sudo mkdir -p /exam-data && echo "exam one" | sudo tee /exam-data/index.html'
cat <<'EOF' | k apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: exam-pv
spec:
  capacity: {storage: 200Mi}
  accessModes: [ReadWriteOnce]
  persistentVolumeReclaimPolicy: Retain
  storageClassName: exam
  hostPath: {path: /exam-data}
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: exam-pvc
spec:
  accessModes: [ReadWriteOnce]
  storageClassName: exam
  resources:
    requests: {storage: 200Mi}
---
apiVersion: v1
kind: Pod
metadata:
  name: data-pod
spec:
  nodeSelector:
    kubernetes.io/hostname: w1
  containers:
  - name: nginx
    image: nginx:1.26
    volumeMounts:
    - {name: web, mountPath: /usr/share/nginx/html}
  volumes:
  - name: web
    persistentVolumeClaim: {claimName: exam-pvc}
EOF
k get pv,pvc
k exec data-pod -- cat /usr/share/nginx/html/index.html      # exam one
```

> If `w2` is tainted from task 4, `data-pod` is pinned to `w1` anyway.

### 7 · NetworkPolicy

```bash
cat <<'EOF' | k apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: db-from-api
  namespace: db
spec:
  podSelector:
    matchLabels: {app: db}
  policyTypes: [Ingress]
  ingress:
  - from:
    - namespaceSelector:
        matchLabels: {kubernetes.io/metadata.name: backend}
      podSelector:
        matchLabels: {role: api}
    ports:
    - {protocol: TCP, port: 5432}
EOF
k -n db describe netpol db-from-api
```

Prove it:

```bash
DBIP=$(k -n db get pod db -o jsonpath='{.status.podIP}')
k -n backend exec api   -- curl -s --max-time 3 $DBIP:5432   # db-ok
k -n backend exec other -- curl -s --max-time 3 $DBIP:5432   # times out (no output, exit 28)
```

### 8 · Quota and LimitRange

```bash
k create namespace team-a
k -n team-a create quota team-quota --hard=pods=4,requests.cpu=1,requests.memory=1Gi
cat <<'EOF' | k apply -f -
apiVersion: v1
kind: LimitRange
metadata:
  name: defaults
  namespace: team-a
spec:
  limits:
  - type: Container
    defaultRequest: {cpu: 100m, memory: 64Mi}
    default:        {cpu: 200m, memory: 128Mi}
EOF
k -n team-a run probe --image=nginx:1.26
k -n team-a get pod probe -o jsonpath='{.spec.containers[0].resources}{"\n"}'
```

### 9 · Ingress (or Gateway)

```bash
k create ingress shop --class=traefik --rule="shop.local/*=shop:80"      # use YOUR class: k get ingressclass
curl -H 'Host: shop.local' http://<node-ip>:30080/
```

Gateway API variant: a `Gateway` with listener hostname `shop.local` and an `HTTPRoute` to `shop:80` (see `03-networking/manifests/03-gateway-http.yaml`).

### 10 · Node NotReady

```bash
k get nodes                                  # w2 NotReady
k describe node w2 | grep -A6 Conditions
ssh w2
systemctl status kubelet                     # inactive (dead), disabled
sudo systemctl enable --now kubelet          # "enable" = survives reboot
k get nodes
```

### 11 · Service not serving

```bash
k -n break-svc get svc,endpoints web-svc                     # endpoints <none>
k -n break-svc get pods --show-labels
k -n break-svc patch svc web-svc -p '{"spec":{"selector":{"app":"web"}}}'
k -n break-svc run t --rm -it --image=busybox:1.36 --restart=Never -- wget -qO- --timeout=3 http://web-svc
```

### 12 · Helm

```bash
helm repo add podinfo https://stefanprodan.github.io/podinfo && helm repo update
helm install web podinfo/podinfo -n helm-exam --create-namespace --set replicaCount=2
helm upgrade web podinfo/podinfo -n helm-exam --set replicaCount=3
helm rollback web 1 -n helm-exam
helm history web -n helm-exam
```

### 13 · HPA

```bash
k autoscale deployment shop --min=2 --max=6 --cpu-percent=60
k get hpa shop
```

### 14 · Node maintenance

```bash
k drain w1 --ignore-daemonsets --delete-emptydir-data
k get nodes; k get pods -A -o wide | grep w1         # only DaemonSet pods remain
k uncordon w1
k get nodes
```

> If a bare pod (like `data-pod` or `red-app`, created without a controller) blocks the drain, that is real behaviour: nothing would recreate it elsewhere. Use `--force` only when the task allows it, and say so. (Static-pod mirror pods such as `audit-w1` are ignored by drain.)
