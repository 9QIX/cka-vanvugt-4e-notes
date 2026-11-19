# Lab 02 · Node health

**Task (from the course):** use the appropriate tools to find out whether the cluster's nodes are in good health.

## Checklist: do all of these and write down what each tells you

```bash
kubectl get nodes -o wide                                    # STATUS, VERSION, INTERNAL-IP
kubectl describe node w1 | sed -n '/Conditions:/,/Addresses:/p'
kubectl describe node w1 | sed -n '/Allocated resources:/,/Events:/p'
kubectl top nodes                                            # needs metrics-server
kubectl get --raw='/readyz?verbose' | tail -20
kubectl -n kube-system get pods -o wide                      # control-plane pods + CoreDNS + CNI + kube-proxy
kubectl get pods -A --field-selector=status.phase!=Running   # anything unhappy anywhere?
```

On a node:

```bash
systemctl is-active kubelet containerd
sudo journalctl -u kubelet --since "10 min ago" --no-pager | tail -30
sudo crictl ps | head
df -h / /var/lib ; free -m ; uptime
```

### Reading Conditions

| Condition | Healthy | If bad |
|---|---|---|
| `Ready` | True | kubelet/runtime/CNI problem |
| `MemoryPressure` | False | node low on memory, pods may be evicted |
| `DiskPressure` | False | disk almost full |
| `PIDPressure` | False | too many processes |
| `NetworkUnavailable` | False | CNI not set up |

## Node failure drills (use `break.sh`)

On a **worker**, as root:

```bash
sudo bash 05-troubleshooting/scripts/break.sh kubelet-stopped
```

On `cp1`, watch it happen:

```bash
kubectl get nodes -w            # w1 turns NotReady after ~40 seconds
kubectl describe node w1 | grep -A8 Conditions     # "Kubelet stopped posting node status"
```

Diagnose from the worker (**do not** look at the solutions yet):

```bash
systemctl status kubelet
sudo journalctl -u kubelet -n 50 --no-pager
```

Repeat with `containerd-stopped`. Compare the two outputs: the node is NotReady in both, but the `systemctl` and `journalctl` evidence differs. That is the habit to build: **node NotReady → check kubelet first, then containerd, then the network.**

Finish with `sudo bash 05-troubleshooting/scripts/break.sh reset` on that worker.

## Done when

- [ ] You can produce a node-health summary (Ready, pressure conditions, allocated resources, system pods) in under 3 minutes.
- [ ] You can tell "kubelet down" from "runtime down" from evidence, not guessing.
