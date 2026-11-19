# Course version vs the exam

The course (Pearson *Certified Kubernetes Administrator (CKA), 4th Edition* by Sander van Vugt) was recorded against **Kubernetes 1.31**. The exam environment tracks a **newer minor version**, so some commands in the videos need updating. The exam is open-book: where a video disagrees with the current docs, **follow the docs**.

> Verify everything on this page against the Linux Foundation CKA page and the candidate handbook the week you book. Versions and domain weights change. This page was last checked **19 November 2026**.

| | Version |
|---|---|
| Course videos | Kubernetes 1.31 |
| This repo's lab default | `K8S_MINOR=v1.37` (override to build any minor) |
| CKA exam environment | the current Kubernetes minor, per the Linux Foundation |

## Differences that matter

| Area | Course (1.31 era) | What to do now |
|---|---|---|
| Package repo & upgrade target | `pkgs.k8s.io/core:/stable:/v1.31/…` | use the repo for the version you build (`v1.37`); upgrade by switching the repo to the next minor |
| kubeadm config file | `kubeadm.k8s.io/v1beta3` | **`v1beta4`**; current kubeadm rejects `v1beta3` |
| `kubectl exec` | `kubectl exec pod ls` sometimes works | always `kubectl exec pod -- ls` |
| etcd restore | `etcdctl snapshot restore` | `etcdutl snapshot restore` is the modern command (`etcdctl`'s is deprecated). Use whichever the **current docs page** shows |
| Ingress controller | course uses a community NGINX-based controller | the community **ingress-nginx** project was retired in March 2026; this repo uses Traefik for Ingress. On the exam a controller is pre-installed |
| CNI manifest | a single Calico manifest URL | this repo installs Calico with the Tigera operator (script resolves the latest release) |
| Course setup scripts | instructor's own GitHub scripts | this repo ships its own, readable scripts in [`lab-setup/`](../lab-setup/README.md) |

## Topics the current curriculum emphasises (read the docs once, try each on your cluster)

- **Gateway API** (covered in the course): `GatewayClass`, `Gateway`, `HTTPRoute`, TLS termination.
- **Helm** and **Kustomize** (covered): install/upgrade/rollback/template; base + overlay.
- **CRDs and operators**: what a `CustomResourceDefinition` is, listing custom resources, installing an operator. The course barely covers it.
- **CNI / CSI / CRI**: what each interface is for, where each plugs in.
- **Native sidecar containers** (covered): `initContainers` entry with `restartPolicy: Always`.
- **kubeadm cluster lifecycle**: install, upgrade, certificate renewal (`kubeadm certs check-expiration`).

## Course unit → exam domain

| Exam domain | Weight | Course unit | This repo |
|---|---|---|---|
| Troubleshooting | **30 %** | Unit 5 (+ troubleshooting tasks in Unit 6) | [05-troubleshooting](../05-troubleshooting/README.md) |
| Cluster Architecture, Installation & Configuration | 25 % | Unit 1 + Unit 2 lesson 7 (Helm, Kustomize) | [01-cluster-setup](../01-cluster-setup/README.md) |
| Services & Networking | 20 % | Unit 3 | [03-networking](../03-networking/README.md) |
| Workloads & Scheduling | 15 % | Unit 2 | [02-workloads-scheduling](../02-workloads-scheduling/README.md) |
| Storage | 10 % | Unit 4 | [04-storage](../04-storage/README.md) |

The exam: **2 hours**, hands-on tasks in a live terminal, **66 %** to pass, open book (kubernetes.io + helm.sh docs). Check the candidate handbook for the current format, retake policy and what the exam purchase includes (killer.sh simulator sessions have been part of it).
