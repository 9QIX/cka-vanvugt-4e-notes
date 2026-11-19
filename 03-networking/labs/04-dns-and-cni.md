# Lab 04 · DNS (CoreDNS) and the CNI

## Resolve things from inside the cluster

```bash
kubectl create deployment dnsweb --image=nginx
kubectl expose deployment dnsweb --port=80

kubectl run dnsutils --rm -it --image=busybox:1.36 --restart=Never -- sh -c '
  cat /etc/resolv.conf
  nslookup kubernetes.default
  nslookup dnsweb
  nslookup dnsweb.default.svc.cluster.local
'
```

Questions: what is the `nameserver` IP? (It is the `kube-dns` Service in `kube-system`: `kubectl -n kube-system get svc kube-dns`.) What does `search default.svc.cluster.local svc.cluster.local cluster.local` let you do?

## Look at CoreDNS

```bash
kubectl -n kube-system get deploy,pods -l k8s-app=kube-dns
kubectl -n kube-system get configmap coredns -o yaml        # the Corefile
kubectl -n kube-system logs -l k8s-app=kube-dns --tail=20
```

The Corefile's `kubernetes cluster.local ...` line answers cluster names; `forward . /etc/resolv.conf` sends everything else to the node's resolvers.

### Add a custom record (hosts plugin)

```bash
kubectl -n kube-system edit configmap coredns
#   inside the ".:53 { ... }" block, add:
#       hosts {
#         10.1.2.3 legacy.internal
#         fallthrough
#       }
kubectl -n kube-system rollout restart deployment coredns
kubectl run dnsutils --rm -it --image=busybox:1.36 --restart=Never -- nslookup legacy.internal
```

> Keep a copy of the original first: `kubectl -n kube-system get cm coredns -o yaml > /tmp/coredns-backup.yaml`. A typo in the Corefile crash-loops CoreDNS, and every DNS lookup in the cluster fails.

## The CNI on a node

```bash
ls /etc/cni/net.d/                 # CNI config written by Calico
ls /opt/cni/bin/                   # CNI plugin binaries
kubectl get pods -n calico-system -o wide
kubectl get nodes                  # a node is NotReady until a CNI is installed
```

Check pod IP ranges match the cluster's pod CIDR:

```bash
kubectl cluster-info dump | grep -m1 -E 'cluster-cidr|podSubnet'
kubectl get pods -A -o wide | head
```

## Clean up

```bash
kubectl delete deployment dnsweb && kubectl delete svc dnsweb
```

## Done when

- [ ] You can resolve a Service by short name, namespace-qualified name, and FQDN.
- [ ] You can find the CoreDNS config and the CNI config directory from memory.
- [ ] You know what breaks (all DNS) when the Corefile is wrong, and where to look (`kubectl -n kube-system logs`).
