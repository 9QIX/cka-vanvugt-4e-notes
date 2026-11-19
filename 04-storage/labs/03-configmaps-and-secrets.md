# Lab 03 · ConfigMaps and Secrets as volumes and env vars

## Create and consume

```bash
cd 04-storage/manifests
kubectl apply -f 03-configmap-secret-volumes.yaml
kubectl wait --for=condition=Ready pod/cfg-demo --timeout=90s

kubectl exec cfg-demo -- ls /etc/app /etc/creds
kubectl exec cfg-demo -- cat /etc/app/greeting.txt          # hello from a ConfigMap
kubectl exec cfg-demo -- cat /etc/creds/password            # plain text inside the pod
kubectl exec cfg-demo -- env | grep -E 'GREETING|DB_USER'
```

Secrets are **base64-encoded, not encrypted**. Anyone with API read access sees them:

```bash
kubectl get secret app-secret -o jsonpath='{.data.password}' | base64 -d; echo
```

## Updates: files change, env vars do not

```bash
kubectl patch configmap app-config --type merge -p '{"data":{"greeting.txt":"updated!"}}'
sleep 60                                                     # kubelet sync period
kubectl exec cfg-demo -- cat /etc/app/greeting.txt          # now "updated!"
kubectl exec cfg-demo -- env | grep GREETING                # still the OLD value
```

## Create them imperatively

```bash
echo 'key=value' > /tmp/app.conf
kubectl create configmap from-file --from-file=/tmp/app.conf
kubectl create configmap from-lit --from-literal=a=1 --from-literal=b=2
kubectl create secret generic db --from-literal=user=admin --from-literal=password='S3cret!'
kubectl create secret docker-registry regcred --docker-server=example.invalid --docker-username=u --docker-password=p
kubectl get cm,secret
```

## Mount only one key, with a specific path and mode

```yaml
volumes:
- name: config
  configMap:
    name: app-config
    items:
    - key: greeting.txt
      path: hello.txt        # appears as /etc/app/hello.txt
    defaultMode: 0444
```

## Clean up

```bash
kubectl delete -f 03-configmap-secret-volumes.yaml
kubectl delete cm from-file from-lit; kubectl delete secret db regcred
rm -f /tmp/app.conf
```

## Done when

- [ ] You can mount both a ConfigMap and a Secret in a pod in under 4 minutes.
- [ ] You can explain why the env var did not update but the file did.
