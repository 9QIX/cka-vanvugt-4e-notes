# 🖥️ Option C: VMware Workstation on Windows (no Vagrant)

Vagrant's VMware provider needs a paid plugin. This path builds the same three nodes (`cp1`, `w1`, `w2`) straight from Ubuntu's official cloud image, using the tools that ship with Workstation (`ovftool`, `vmrun`, `vmware-vdiskmanager`) plus a small Python helper.

You end up with **three Ubuntu 24.04 VMs with static IPs, SSH-key login, names in `/etc/hosts`, and this repo cloned: but no Kubernetes**. Building the cluster is [lab 01](../../01-cluster-setup/labs/01-build-cluster.md).

## Prerequisites

- VMware Workstation (Pro or the free Personal edition), Windows PowerShell 7, Python 3.
- ~25 GB free on an **internal** drive and ~7 GB RAM.
- An SSH key: `ssh-keygen -t ed25519 -f $HOME\.ssh\cka_lab` (press Enter for **no** passphrase; a passphrase makes non-interactive `ssh` fail).
- Your NAT subnet: Workstation → Edit → Virtual Network Editor → **VMnet8** (e.g. `192.168.178.0/24`). The nodes get `.11`, `.21`, `.22`; the NAT gateway is normally `.2`. Pick addresses **outside** the DHCP range.

## Build

```powershell
pip install --user pycdlib
python make_seeds.py --out D:\VMs\_work\_seeds --subnet 192.168.178 --pubkey $HOME\.ssh\cka_lab.pub
.\build.ps1 -Work D:\VMs\_work -VmRoot D:\VMs\cka
```

Then, after about two minutes:

```powershell
ssh -i $HOME\.ssh\cka_lab ubuntu@192.168.178.11 hostname     # cp1
```

Add shortcuts to `~/.ssh/config` so `ssh cp1` works:

```text
Host cp1
  HostName 192.168.178.11
Host w1
  HostName 192.168.178.21
Host w2
  HostName 192.168.178.22
Host cp1 w1 w2
  User ubuntu
  IdentityFile ~/.ssh/cka_lab
  IdentitiesOnly yes
```

Take the clean-OS snapshot for each node (it takes a few minutes while the VM is running):

```powershell
& 'C:\Program Files\VMware\VMware Workstation\vmrun.exe' -T ws snapshot D:\VMs\cka\cp1\cp1.vmx base-os
```

## Then: build the cluster (lab 01)

Use the scripts in [`../scripts`](../scripts), **or** follow the course and type the steps yourself. The repo is already cloned on each node:

```bash
# on all three nodes
sudo NODE_IP=<this-node-ip> bash ~/cka-vanvugt-4e-notes/lab-setup/scripts/00-common.sh
# on cp1
sudo NODE_IP=192.168.178.11 bash ~/cka-vanvugt-4e-notes/lab-setup/scripts/10-control-plane.sh
# on each worker (join.sh is written next to where you ran the control-plane script;
# or print a fresh command on cp1: kubeadm token create --print-join-command)
```

> Labs elsewhere in this repo show example IPs such as `192.168.56.x`. **Use your own node IPs** (e.g. `192.168.178.x`) wherever a command shows one.

## Pitfalls we hit (so you do not)

| Symptom | Cause / fix |
|---|---|
| `ovftool` fails with "failed to read from file" and the target folder vanishes | the drive disconnected mid-import. Use an internal drive, never USB |
| `Invalid target disk adapter type: thin` | do not pass `--diskMode` for a Workstation target (the script does not) |
| `Permission denied (publickey)` although the VM booted | your private key has a passphrase (or its public half is not the one in the seed). Regenerate without a passphrase and rebuild the seed ISOs |
| VM boots with a DHCP address, not the static one | the NIC name did not match `en*`, or the seed ISO is not attached. Check the `ide1:0` lines in the `.vmx` |
| VMs will not start after cleanup | the `.vmx` files reference the seed ISOs: do not delete `_seeds` |

## Status

The method above was run end-to-end by hand (three VMs up, SSH, static IPs, node-to-node ping, snapshots). `build.ps1` packages those exact steps but has **not** been re-run as a single script yet: if it needs a fix on your machine, please open an issue or PR.
