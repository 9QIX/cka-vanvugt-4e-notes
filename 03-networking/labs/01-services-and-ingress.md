# Lab 01 · Services and Ingress

**Task (from the course):** run a Deployment `apples` with 3 `nginx` replicas, expose it on the host name `my.fruit`, and test it with port forwarding.

## 1 · Deployment + Services

```bash
cd 03-networking/manifests
kubectl apply -f 01-apples-and-services.yaml
kubectl get pods -l app=apples -o wide
kubectl get svc apples apples-nodeport
kubectl get endpoints apples                 # 3 pod IPs. Empty means a selector mismatch

# ClusterIP, from inside the cluster
kubectl run curl --rm -it --image=busybox:1.36 --restart=Never -- wget -qO- http://apples

# NodePort, from outside: any node IP, port 30085
curl http://192.168.56.21:30085              # adjust to one of YOUR node IPs
```

Make each pod identifiable, so you can *see* load balancing:

```bash
for p in $(kubectl get pods -l app=apples -o name); do
  kubectl exec ${p#pod/} -- sh -c 'echo "hello from $(hostname)" > /usr/share/nginx/html/index.html'
done
for i in 1 2 3 4 5 6; do curl -s http://192.168.56.21:30085; done      # a mix of 3 hostnames
```

## 2 · Port forwarding (test without exposing anything)

```bash
kubectl port-forward svc/apples 8080:80 &
curl http://127.0.0.1:8080
kill %1
```

## 3 · Ingress

```bash
bash ../../lab-setup/scripts/install-ingress-controller.sh      # Traefik, NodePort 30080/30443
kubectl get ingressclass
kubectl apply -f 02-ingress.yaml
kubectl get ingress apples
kubectl describe ingress apples

curl -H 'Host: my.fruit' http://192.168.56.21:30080/            # adjust node IP
```

Prefer names over headers? Add the host to `/etc/hosts` on your machine: `<node-ip> my.fruit`, then `curl http://my.fruit:30080`.

Generate the Ingress imperatively (a good exam habit):

```bash
kubectl create ingress apples2 --class=traefik --rule="my.fruit/*=apples:80" --dry-run=client -o yaml
```

## Troubleshoot

| Symptom | Look at |
|---|---|
| 404 from the controller | host header wrong, or no matching rule: `kubectl describe ingress` |
| 502/503 | Service has no endpoints, or wrong port |
| Ingress has no ADDRESS / nothing answers | wrong or missing `ingressClassName`, controller pods not running |

## Clean up

```bash
kubectl delete -f 02-ingress.yaml -f 01-apples-and-services.yaml
```

## Done when

- [ ] You can explain `port` vs `targetPort` vs `nodePort` without notes.
- [ ] You created an Ingress for a host in under 3 minutes using `kubectl create ingress`.
