# Practice Exam 2: solutions

> One way to do each task. Judge yours by the **verification**. Assumes `alias k=kubectl`.

### 1 · Upgrade

Follow [Lab 04](../01-cluster-setup/labs/04-upgrade.md) exactly. Verification:

```bash
k get nodes          # cp1 and w1 on the new minor, w2 on the old one
k -n apps get pods   # the web pods are still Running (drain moved them; w2 stayed available)
```

### 2 · Certificate user

```bash
cd "$(mktemp -d)"
openssl genrsa -out ana.key 2048
openssl req -new -key ana.key -out ana.csr -subj "/CN=ana/O=dev"
cat <<EOF | k apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: ana
spec:
  request: $(base64 -w0 < ana.csr)
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400
  usages: ["client auth"]
EOF
k certificate approve ana
k get csr ana -o jsonpath='{.status.certificate}' | base64 -d > ana.crt
k -n apps create rolebinding ana-view --clusterrole=view --user=ana
k auth can-i list pods -n apps    --as=ana     # yes
k auth can-i list pods -n default --as=ana     # no
```

Optional full proof with a kubeconfig context: see [Lab 05](../01-cluster-setup/labs/05-rbac.md), part 4. Delete the key files when done.

### 3 · DaemonSet on all nodes (including control plane)

```bash
cat <<'EOF' | k apply -f -
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: agent
  namespace: apps
spec:
  selector:
    matchLabels: {app: agent}
  template:
    metadata:
      labels: {app: agent}
    spec:
      tolerations:
      - key: node-role.kubernetes.io/control-plane
        operator: Exists
        effect: NoSchedule
      containers:
      - name: busybox
        image: busybox:1.36
        command: ["sleep", "3600"]
EOF
k -n apps get pods -l app=agent -o wide      # 3 pods, one per node
```

### 4 · Affinity

```bash
cat <<'EOF' | k apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: fast
  namespace: apps
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - {key: disk, operator: In, values: ["ssd"]}
  containers:
  - name: nginx
    image: nginx:1.26
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: spread
  namespace: apps
spec:
  replicas: 2
  selector:
    matchLabels: {app: spread}
  template:
    metadata:
      labels: {app: spread}
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchLabels: {app: spread}
            topologyKey: kubernetes.io/hostname
      containers:
      - name: nginx
        image: nginx:1.26
EOF
k -n apps get pods -o wide      # fast on w1; spread replicas on different nodes
```

(`nodeSelector: {disk: ssd}` is an equally valid answer for 4a.)

### 5 · Gateway API with TLS

```bash
openssl req -x509 -nodes -newkey rsa:2048 -days 30 -keyout /tmp/tls.key -out /tmp/tls.crt \
  -subj "/CN=web.example.test" -addext "subjectAltName=DNS:web.example.test"
k -n apps create secret tls web-tls --cert=/tmp/tls.crt --key=/tmp/tls.key
cat <<'EOF' | k apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: web-gw
  namespace: apps
spec:
  gatewayClassName: nginx
  listeners:
  - name: https
    port: 443
    protocol: HTTPS
    hostname: web.example.test
    tls:
      mode: Terminate
      certificateRefs:
      - {kind: Secret, name: web-tls}
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: web
  namespace: apps
spec:
  parentRefs:
  - name: web-gw
  hostnames: ["web.example.test"]
  rules:
  - backendRefs:
    - {name: web, port: 80}
EOF
k -n apps describe gateway web-gw | grep -E 'Programmed|Accepted'
k -n apps describe httproute web | grep -E 'Accepted|ResolvedRefs'
k -n apps get svc                                   # find the data-plane Service for web-gw
k -n apps port-forward svc/web-gw-nginx 8443:443 &  # use the name you found
curl -k --resolve web.example.test:8443:127.0.0.1 https://web.example.test:8443/
kill %1; rm -f /tmp/tls.key /tmp/tls.crt
```

### 6 · NetworkPolicy egress

```bash
cat <<'EOF' | k apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: web-egress
  namespace: apps
spec:
  podSelector:
    matchLabels: {app: web}
  policyTypes: [Egress]
  egress:
  - to:
    - namespaceSelector:
        matchLabels: {kubernetes.io/metadata.name: kube-system}
    ports:
    - {protocol: UDP, port: 53}
    - {protocol: TCP, port: 53}
  - to:
    - podSelector:
        matchLabels: {app: cache}
    ports:
    - {protocol: TCP, port: 6379}
EOF
k -n apps describe netpol web-egress
```

(Selecting kube-dns pods with a `podSelector` for `k8s-app=kube-dns` in the same `to` item is stricter and also valid. Namespace-only is accepted for "DNS in kube-system".)

### 7 · Dynamic storage

```bash
cat <<'EOF' | k apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: reports
  namespace: apps
spec:
  storageClassName: nfs-client
  accessModes: [ReadWriteMany]
  resources:
    requests: {storage: 100Mi}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: reporter
  namespace: apps
spec:
  replicas: 2
  selector:
    matchLabels: {app: reporter}
  template:
    metadata:
      labels: {app: reporter}
    spec:
      containers:
      - name: busybox
        image: busybox:1.36
        command: ["sh", "-c", "echo hello > /reports/$HOSTNAME.txt; sleep 3600"]
        volumeMounts:
        - {name: reports, mountPath: /reports}
      volumes:
      - name: reports
        persistentVolumeClaim: {claimName: reports}
EOF
k -n apps get pvc reports
for p in $(k -n apps get pods -l app=reporter -o name); do k -n apps exec ${p#pod/} -- ls /reports; done   # both files, from either pod
```

### 8 · ConfigMap and Secret

```bash
k -n apps create configmap site-config --from-literal=color=green --from-literal=title='Exam 2'
k -n apps create secret generic site-secret --from-literal=token=abc123
cat <<'EOF' | k apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: site
  namespace: apps
spec:
  containers:
  - name: busybox
    image: busybox:1.36
    command: ["sleep", "3600"]
    env:
    - name: SITE_COLOR
      valueFrom:
        configMapKeyRef: {name: site-config, key: color}
    volumeMounts:
    - {name: config, mountPath: /etc/site}
    - {name: secret, mountPath: /etc/secret, readOnly: true}
  volumes:
  - name: config
    configMap: {name: site-config}
  - name: secret
    secret: {secretName: site-secret}
EOF
k -n apps exec site -- sh -c 'echo $SITE_COLOR; ls /etc/site /etc/secret'
```

### 9 · Scheduling is broken

```bash
k -n kube-system get pods | grep scheduler          # CrashLoopBackOff
k -n kube-system logs kube-scheduler-cp1 | tail -3  # unable to load kubeconfig ... scheduler.conff
sudo vi /etc/kubernetes/manifests/kube-scheduler.yaml     # fix the --kubeconfig path
k create deployment t --image=nginx && k get pods         # scheduled again
```

### 10 · DNS is broken

```bash
k -n kube-system get pods -l k8s-app=kube-dns       # CrashLoopBackOff
k -n kube-system logs -l k8s-app=kube-dns --tail=3  # Unknown directive 'forwrd'
k -n kube-system edit configmap coredns             # forwrd -> forward
k -n kube-system rollout restart deployment coredns
k run t --rm -it --image=busybox:1.36 --restart=Never -- nslookup web.apps
```

### 11 · Two broken deployments

```bash
k -n break-img set image deployment/shop nginx=nginx:1.26
k -n break-res set resources deployment/hungry --requests=cpu=50m,memory=64Mi
k -n break-img rollout status deployment/shop
k -n break-res rollout status deployment/hungry
```

### 12 · etcd restore

```bash
k create namespace lost-and-found
k -n lost-and-found create configmap note --from-literal=msg=hello
sudo ETCDCTL_API=3 etcdctl snapshot save /opt/exam/etcd2.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
k delete namespace lost-and-found
sudo etcdutl snapshot restore /opt/exam/etcd2.db --data-dir /var/lib/etcd-restore2
sudo cp /etc/kubernetes/manifests/etcd.yaml /root/etcd.yaml.bak          # backup OUTSIDE the manifests dir
sudo sed -i 's#path: /var/lib/etcd$#path: /var/lib/etcd-restore2#' /etc/kubernetes/manifests/etcd.yaml
# wait 1-2 minutes
k -n lost-and-found get configmap note
```

Check the edit before relying on it: `sudo grep -n 'etcd-data' -B2 -A3 /etc/kubernetes/manifests/etcd.yaml`. The `sed` touches only the `hostPath` line that ends exactly in `/var/lib/etcd`, leaving `--data-dir=/var/lib/etcd` (the in-container path) alone.
