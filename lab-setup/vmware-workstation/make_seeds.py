#!/usr/bin/env python3
"""Build one cloud-init NoCloud seed ISO per lab VM (pure Python, no admin rights).

    python make_seeds.py --out D:\\VMs\\_work\\_seeds --subnet 192.168.178 --pubkey ~/.ssh/cka_lab.pub

Needs:  pip install --user pycdlib pyyaml
Writes: <out>/cp1-seed.iso, w1-seed.iso, w2-seed.iso and <out>/../CREDENTIALS.txt (random console password).
The ISOs set hostname, static IP, the SSH key, a console password, /etc/hosts and clone this repo.
"""
import argparse, io, os, secrets, string
import pycdlib

NODES = {"cp1": 11, "w1": 21, "w2": 22}  # last octet of each node's static IP


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True, help="folder for the seed ISOs (keep them: the VMs reference them)")
    ap.add_argument("--subnet", required=True, help="first three octets of the VM network, e.g. 192.168.178")
    ap.add_argument("--gateway-octet", type=int, default=2, help="VMware NAT gateway is normally .2")
    ap.add_argument("--pubkey", default="~/.ssh/cka_lab.pub")
    ap.add_argument("--repo", default="https://github.com/9QIX/cka-vanvugt-4e-notes.git")
    a = ap.parse_args()

    pubkey = open(os.path.expanduser(a.pubkey), encoding="utf-8").read().strip()
    gateway = f"{a.subnet}.{a.gateway_octet}"
    hosts = "".join(f"{a.subnet}.{o} {n}\\n" for n, o in NODES.items())
    password = "".join(secrets.choice(string.ascii_letters + string.digits) for _ in range(16))
    os.makedirs(a.out, exist_ok=True)

    for name, octet in NODES.items():
        ip = f"{a.subnet}.{octet}"
        user_data = f"""#cloud-config
hostname: {name}
ssh_pwauth: false
ssh_authorized_keys:
  - {pubkey}
chpasswd:
  expire: false
  users:
  - {{name: ubuntu, password: {password}, type: text}}
package_update: true
packages: [git, curl, jq, vim, bash-completion, nfs-common, net-tools]
runcmd:
  - [sh, -c, "printf '{hosts}' >> /etc/hosts"]
  - [su, ubuntu, -c, "cd /home/ubuntu && git clone {a.repo} || true"]
"""
        meta_data = f"instance-id: cka-{name}\nlocal-hostname: {name}\n"
        network_config = f"""version: 2
ethernets:
  nic0:
    match:
      name: "en*"
    dhcp4: false
    addresses: [{ip}/24]
    routes:
      - to: default
        via: {gateway}
    nameservers:
      addresses: [{gateway}, 1.1.1.1]
"""
        iso = pycdlib.PyCdlib()
        iso.new(interchange_level=3, joliet=3, rock_ridge="1.09", vol_ident="cidata")
        for fname, body in (("user-data", user_data), ("meta-data", meta_data), ("network-config", network_config)):
            data = body.encode()
            iso.add_fp(io.BytesIO(data), len(data), "/" + fname.replace("-", "_").upper() + ".;1",
                       rr_name=fname, joliet_path="/" + fname)
        path = os.path.join(a.out, f"{name}-seed.iso")
        iso.write(path)
        iso.close()
        print("wrote", path)

    cred = os.path.join(os.path.dirname(os.path.abspath(a.out)), "CREDENTIALS.txt")
    with open(cred, "w", encoding="utf-8") as f:
        f.write("Local lab credentials (keep out of any repo)\nlogin user: ubuntu\n")
        f.write(f"console password: {password}\n")
        f.write("ssh: key only -> ssh -i <your-private-key> ubuntu@<ip>\n")
        for n, o in NODES.items():
            f.write(f"{n}: {a.subnet}.{o}\n")
    print("wrote", cred)


if __name__ == "__main__":
    main()
