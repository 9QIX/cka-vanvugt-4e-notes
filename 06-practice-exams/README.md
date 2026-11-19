# 06 · Practice exams

> **Course:** Unit 6 (sample exams and the grading script).
> The two exams here are **original**: written for this repo, in the style of the CKA (hands-on, task-based, weighted). They are **not** the course's questions and **not** real exam questions. Never share or ask for real exam content; that is against the exam rules.

## How to run one

1. **Fresh cluster**: revert the `clean` snapshot ([lab-setup](../lab-setup/README.md)).
2. Run the exam's **Setup** block (creates the prerequisites; the timer is not running yet).
3. Start a **2-hour** timer. Solutions closed. Docs allowed: **kubernetes.io** and **helm.sh** only (the real exam's rule).
4. First thing, set up your shell (see the [cheat sheet](../docs/exam-cheatsheet.md)).
5. Work the tasks in any order. Over ~7 minutes with no progress → flag it and move on. Keep the last 15 minutes for flagged tasks.
6. Stop at 2:00. Score with the table below, **then** open the solutions.

## Scoring

| Rule | |
|---|---|
| Each task has a weight (percent). Full marks only if the **verification** passes. | |
| Partial credit: you may give yourself half the weight when the object exists but one requirement fails. | |
| Pass mark | **66 %** |

Record your result:

| Date | Exam | Score | Slowest tasks | Weak domains |
|---|---|---|---|---|
| | 1 | | | |
| | 2 | | | |

## Contents

| Exam | Focus | Tasks | Solutions |
|---|---|---|---|
| [Exam 1](exam-1.md) | broad sweep of all five domains | 14 | [solutions](exam-1-solutions.md) |
| [Exam 2](exam-2.md) | upgrade, Gateway API/TLS, dynamic storage, harder troubleshooting | 12 | [solutions](exam-2-solutions.md) |

## After the exam: the redo loop

For every task you missed or took > 7 minutes:

1. Read the solution **once**.
2. Wait a day.
3. Redo that task from a clean state, solution closed. Time it.
4. Only count it done when it is clean **and** under 7 minutes.

## Beyond this repo

- The official **killer.sh** simulator sessions come with the exam purchase. Treat them as the final gate: they are harder than the exam.
- Read the current **CKA curriculum** and **candidate handbook** from the Linux Foundation before booking. Domain weights and the Kubernetes version change.
