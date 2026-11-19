# Lab 05 · RBAC: roles, bindings, ServiceAccounts, a user certificate

## Part 1 · Task: "view pods in `default`; allow every authenticated user to use it"

```bash
kubectl create role pod-viewer --verb=get,list,watch --resource=pods -n default
kubectl create rolebinding pod-viewer-all --role=pod-viewer --group=system:authenticated -n default
```

Declarative versions: [`manifests/rbac-pod-viewer.yaml`](../manifests/rbac-pod-viewer.yaml).

Test with impersonation (no extra credentials needed):

```bash
kubectl auth can-i list pods -n default --as=anyone --as-group=system:authenticated   # yes
kubectl auth can-i delete pods -n default --as=anyone --as-group=system:authenticated # no
kubectl auth can-i list pods -n kube-system --as=anyone --as-group=system:authenticated # no
```

## Part 2 · ServiceAccount with its own permissions

```bash
kubectl create namespace rbac-lab
kubectl -n rbac-lab create serviceaccount app
kubectl -n rbac-lab create role cm-reader --verb=get,list --resource=configmaps
kubectl -n rbac-lab create rolebinding app-cm-reader --role=cm-reader --serviceaccount=rbac-lab:app

kubectl auth can-i list configmaps -n rbac-lab --as=system:serviceaccount:rbac-lab:app    # yes
kubectl auth can-i list secrets    -n rbac-lab --as=system:serviceaccount:rbac-lab:app    # no
```

Run a pod as that ServiceAccount:

```bash
kubectl -n rbac-lab run probe --image=nginx --overrides='{"spec":{"serviceAccountName":"app"}}'
```

## Part 3 · ClusterRole + ClusterRoleBinding

```bash
kubectl create clusterrole node-reader --verb=get,list,watch --resource=nodes
kubectl create clusterrolebinding app-node-reader --clusterrole=node-reader --serviceaccount=rbac-lab:app
kubectl auth can-i list nodes --as=system:serviceaccount:rbac-lab:app    # yes
```

## Part 4 · Give a human a certificate-based login

Work in a scratch directory outside the repo; never commit keys.

```bash
cd "$(mktemp -d)"
openssl genrsa -out jane.key 2048
openssl req -new -key jane.key -out jane.csr -subj "/CN=jane/O=dev"

cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: jane
spec:
  request: $(base64 -w0 < jane.csr)
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400
  usages: ["client auth"]
EOF

kubectl certificate approve jane
kubectl get csr jane -o jsonpath='{.status.certificate}' | base64 -d > jane.crt

kubectl config set-credentials jane --client-certificate=jane.crt --client-key=jane.key --embed-certs=true
kubectl config set-context jane --cluster=kubernetes --user=jane

kubectl --context jane get pods -n rbac-lab      # Forbidden: authenticated, but not authorised
kubectl -n rbac-lab create rolebinding jane-pods --clusterrole=view --user=jane
kubectl --context jane get pods -n rbac-lab      # works now
```

## Clean up

```bash
kubectl delete namespace rbac-lab
kubectl delete clusterrole node-reader && kubectl delete clusterrolebinding app-node-reader
kubectl delete csr jane
kubectl config delete-context jane && kubectl config delete-user jane
kubectl delete rolebinding pod-viewer-all -n default && kubectl delete role pod-viewer -n default
```

## Done when

- [ ] Each part takes you under 3 minutes with `--dry-run=client -o yaml` when you want a manifest.
- [ ] You know the difference between **authentication** (cert/token: who are you?) and **authorization** (RBAC: what may you do?).
