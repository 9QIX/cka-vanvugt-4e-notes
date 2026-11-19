# Lab 03 · Break and fix drills

The point: **practise under a timer, with someone else's bug.** Since you wrote the script you know the list of bugs, so do it in a random order (`ls | shuf`) or have a friend pick.

## Rules

1. Snapshot the VMs first (`vagrant snapshot save clean`).
2. Run a scenario. Read **only the ticket**.
3. Start a **7-minute** timer. Fix it with the docs allowed, no solutions.
4. Verify with a real test (not just "the pod is Running").
5. Log it in the table below. Over time: failures first, speed second.

```bash
sudo bash 05-troubleshooting/scripts/break.sh list
sudo bash 05-troubleshooting/scripts/break.sh <scenario>
```

| Scenario | Where | Verified by | Time | Notes |
|---|---|---|---|---|
| `kubelet-stopped` | worker | node `Ready` | | |
| `containerd-stopped` | worker | node `Ready`, pods running | | |
| `bad-scheduler` | control plane | a new pod gets scheduled | | |
| `bad-apiserver` | control plane | `kubectl get nodes` works | | |
| `wrong-selector` | control plane | `endpoints` populated, request returns nginx | | |
| `bad-image` | control plane | 2/2 pods Ready | | |
| `pending-resources` | control plane | 2/2 pods Running | | |
| `tainted-workers` | control plane | pods Running, deployment unchanged | | |
| `coredns-config` | control plane | `nslookup kubernetes.default` works | | |

## Build your own scenarios

The fastest way to learn what breaks a cluster is to think of ways to break it. Ideas not covered by the script:

- Delete the CNI config in `/etc/cni/net.d/` on a worker, then create a pod there.
- Fill a node's disk (`fallocate -l 20G /tmp/fill`) and watch `DiskPressure` and evictions.
- Break a PVC (non-existent StorageClass) and diagnose the `Pending` pod.
- Break the kubelet config: wrong `clusterDNS` in `/var/lib/kubelet/config.yaml`.
- Expire a certificate: `kubeadm certs check-expiration`, then `kubeadm certs renew <cert>`.
- Misconfigure a NetworkPolicy so a working app is cut off.

Add your scenario to `break.sh` as a PR, with a one-line ticket and a solution in `SOLUTIONS.md`.

## Reset

```bash
sudo bash 05-troubleshooting/scripts/break.sh reset     # on every node you used
# or: vagrant snapshot restore clean
```
