# Lab 03 · Helm

**Prerequisite:** `helm` on the control plane ([install guide](https://helm.sh/docs/intro/install/)). On the exam it is already installed.

## Install, inspect, upgrade, roll back, uninstall

```bash
helm repo add podinfo https://stefanprodan.github.io/podinfo
helm repo update
helm search repo podinfo
helm show values podinfo/podinfo | head -40

# Render without installing: what would Helm create?
helm template demo podinfo/podinfo --set replicaCount=2 | less

helm install demo podinfo/podinfo -n helm-lab --create-namespace --set replicaCount=2
helm list -n helm-lab
kubectl -n helm-lab get deploy,pods

helm upgrade demo podinfo/podinfo -n helm-lab --set replicaCount=3
helm history demo -n helm-lab
helm rollback demo 1 -n helm-lab
kubectl -n helm-lab get pods                    # back to 2 replicas

helm get values demo -n helm-lab
helm uninstall demo -n helm-lab
kubectl delete namespace helm-lab
```

## Values from a file

```bash
cat > /tmp/podinfo-values.yaml <<'EOF'
replicaCount: 2
ui:
  message: "hello from values.yaml"
EOF
helm install demo2 podinfo/podinfo -n helm-lab --create-namespace -f /tmp/podinfo-values.yaml
helm uninstall demo2 -n helm-lab; kubectl delete namespace helm-lab
```

## Stretch: the course's lab application

The course installs HashiCorp Vault with Helm. Try it the same way:

```bash
helm repo add hashicorp https://helm.releases.hashicorp.com
helm install vault hashicorp/vault -n vault --create-namespace --set server.dev.enabled=true
kubectl -n vault get pods
helm uninstall vault -n vault; kubectl delete namespace vault
```

## Done when

- [ ] You can find a chart, install it with an override, upgrade it, and roll back, with no notes.
- [ ] You know `helm template` and `helm show values` exist for when the task says "what would this chart deploy".
