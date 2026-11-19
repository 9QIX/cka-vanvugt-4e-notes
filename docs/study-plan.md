# Study plan: 10 weeks, built for skipped nights

A plan you can actually follow beats a perfect one you abandon in week two. This one **assumes you will skip some sessions** and tells you what to do when you do.

> Pick your exam date, count back 10 weeks, and write the real dates next to the week numbers. Nothing here depends on a specific calendar.

## The rhythm

| Day | What | Counts? |
|---|---|---|
| Mon, Wed | one lesson block + its lab (25 min minimum, 90 when you are in flow) | ✅ required |
| Tue, Thu | spare slots: catch-up for anything skipped | optional |
| Sat | **timed practice**: 3 hours when you can, 45 minutes of one timed task when you cannot | ✅ required |
| Fri, Sun | off | |

**Session rule:** open the VM or press play. After 25 minutes you may stop. Watch videos at 1.25×, then do the lab with the video **closed**.

### When you skip

- **One required day missed** → move it to the next spare slot, same week.
- **Two missed** → Saturday does the lab only; skip every `learning-objectives` video.
- **A whole week missed** → close it. Never carry more than one week of debt. Labs from a closed week replace rewatching.

### Never cut these, even in a bad month

The Saturday timer · etcd restore · a node upgrade · one NetworkPolicy · one broken-node fix · both practice exams · both killer.sh sessions.

## The plan

| Week | Focus | Course unit | Do (hands-on) | Lab links |
|---|---|---|---|---|
| 1 | The cluster | Unit 1, lessons 1-3 | Build 3 nodes, snapshot, static pods, `crictl`, cordon/drain | [lab-setup](../lab-setup/README.md), [01 · labs 01, 02, 06](../01-cluster-setup/README.md) |
| 2 | etcd, upgrade, RBAC | Unit 1, lessons 4-5 | etcd backup/restore, one-minor upgrade, Role/binding/ServiceAccount/user cert | [01 · labs 03, 04, 05](../01-cluster-setup/README.md) |
| 3 | Workloads | Unit 2, lessons 6-8 | controllers, init/sidecar, HPA, Helm, Kustomize, taints, quota | [02 · labs 01-06](../02-workloads-scheduling/README.md) |
| 4 | Networking | Unit 3 | Services, Ingress, Gateway API + TLS, NetworkPolicy, CoreDNS | [03 · labs 01-04](../03-networking/README.md) |
| 5 | Storage + troubleshooting | Units 4, 5 | PV/PVC/StorageClass; **break & fix drills** | [04](../04-storage/README.md), [05](../05-troubleshooting/README.md) |
| 6 | Gaps and redo | none new | docs on CRDs/operators, CNI/CSI/CRI; redo the 5 slowest tasks | [version notes](version-notes.md) |
| 7 | Practice exam 1 | Unit 6 | 2 h timed, solutions closed; redo misses | [exam 1](../06-practice-exams/exam-1.md) |
| 8 | Practice exam 2 | Unit 6 | 2 h timed; write the "tasks > 7 min" list | [exam 2](../06-practice-exams/exam-2.md) |
| 9 | Simulator 1 | - | killer.sh session 1, then only the misses | |
| 10 | Simulator 2, then the gate | - | killer.sh session 2; redo every miss | |

## The gate (decide whether you are ready)

You are ready to sit when all of these are true after simulator 2:

- [ ] You built a cluster, upgraded it, and restored etcd **without** the video.
- [ ] NetworkPolicy, Ingress or Gateway, PV/PVC and RBAC each take you **under 7 minutes**.
- [ ] You fixed a broken node from `describe`, logs and `journalctl` **without guessing**.
- [ ] The simulator felt *finished*; every missed task got one clean redo the next day.

Not ready? Move the exam by a week and spend the extra days **only** on the failed domain. Do not sit anyway.

## Where the hours go

| Unit | Weight | Share your Saturdays like this |
|---|---|---|
| 05 Troubleshooting | 30 % | the most time, from week 5 onwards |
| 01 Cluster | 25 % | etcd + upgrade every other Saturday |
| 03 Networking | 20 % | one NetworkPolicy + one Ingress/Gateway, timed |
| 02 Workloads | 15 % | taints + quota |
| 04 Storage | 10 % | PV/PVC |

Troubleshooting gets the least video and the most points. From week 5 on, every Saturday includes one broken node.

## Night before

Aliases only (see the [cheat sheet](exam-cheatsheet.md)), bookmarks open, sleep. No new topic.
