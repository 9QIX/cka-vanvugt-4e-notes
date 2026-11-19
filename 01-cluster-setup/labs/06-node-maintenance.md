# Lab 06 · Node maintenance and `crictl`

## Cordon, drain, uncordon

```bash
kubectl create deployment spread --image=nginx --replicas=6
kubectl get pods -o wide                      # pods on both workers

kubectl cordon w1                              # node shows SchedulingDisabled
kubectl scale deployment spread --replicas=8   # new pods avoid w1
kubectl get pods -o wide

kubectl drain w1 --ignore-daemonsets --delete-emptydir-data   # pods leave w1
kubectl get pods -o wide                       # everything on w2

kubectl uncordon w1                            # schedulable again (pods do NOT move back by themselves)
kubectl delete deployment spread
```

Questions to answer for yourself:

1. Why did `drain` complain until you added `--ignore-daemonsets`?
2. Why did the evicted pods come back on another node, but a bare `kubectl run` pod would not?

## `crictl` (talk to the runtime when the API server is down)

On any node:

```bash
sudo crictl ps                  # running containers
sudo crictl ps -a               # including exited
sudo crictl pods                # pod sandboxes
sudo crictl images
sudo crictl logs <container-id>
sudo crictl inspect <container-id> | less
```

## Node services

```bash
systemctl status kubelet
systemctl status containerd
sudo journalctl -u kubelet -n 50 --no-pager
sudo journalctl -u kubelet -f                 # follow while you break and fix things
```

## Analyse node state

```bash
kubectl get nodes -o wide
kubectl describe node w1 | less               # Conditions, Capacity, Allocated resources, Events
kubectl top nodes                              # needs metrics-server (lab-setup/scripts/install-metrics-server.sh)
```

## Done when

- [ ] You can drain and uncordon a node without looking up flags.
- [ ] You can list the containers on a node while `kubectl` is unavailable.
