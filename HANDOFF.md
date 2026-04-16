# HANDOFF BRIEF — CAIRN CMS
Generated: 2026-04-15

## What This Project Is
A Ruby on Rails 7.2 learning environment structured as a real multi-user CMS
(roles, publishing workflows, soft deletes, Pundit auth). The learner works GitHub
Issues tickets on feature branches to simulate professional engineering work.

---

## Where We Are
- **Current phase:** Planning — complete
- **Current sprint:** Not started (no code written, no git repo initialized)
- **Sprint deliverable:** App boots with login screen (M0)

---

## What's Been Built
- Nothing — no git history, no Rails app yet
- Planning artifacts only (see Key Files below)

---

## What's Next
1. `git init` — before anything else
2. Generate Rails 7.2 app with PostgreSQL, no default test framework — `implementer`, M0 task 1
3. Install + configure Tailwind CSS via cssbundling-rails — `implementer`, M0 task 2
4. Install Devise, generate User model, redirect `/` to sign-in — `implementer`, M0 task 3

---

## Open Items & Blockers
- Not a git repo yet — `git init` must happen before any conductor run
- M7 tasks (file GitHub Issues, create CODEOWNERS) require a GitHub repo — defer until M6 complete
- ISSUES.md references real file paths that don't exist yet — M7 reviewer task should run after M6

---

## Key Files
| File | Purpose |
|---|---|
| `CLAUDE.md` | Stack, commands, seed users, architecture rules, learning workflow |
| `PROJECT_PLAN.md` | 9 milestones (M0–M8), all tasks pending |
| `ISSUES.md` | 20 tickets with 3-tier help system (learner's backlog post-build) |
| `RUBRIC.md` | 5-dimension PR grading rubric (self-grade after every merge) |
| `PROJECT_VISION.md` | Full product rationale, learning system design, decisions log |

---

## Agent Map
| Agent | Role |
|---|---|
| `conductor` | Reads PROJECT_PLAN.md, delegates one task at a time, never codes |
| `implementer` | All coding — frontend, backend, migrations, seeds |
| `db-architect` | Schema design, migrations, seed data |
| `qa` | Test writing and validation |
| `reviewer` | Isolated code review after implementation (fresh context) |

---

## Starting a New Session

```
Read CLAUDE.md and PROJECT_PLAN.md. Use the conductor agent to execute the next
incomplete milestone in PROJECT_PLAN.md.
```

Conductor will delegate to the right agent, verify output, mark the task done, and stop.
Re-invoke for the next task.

---

## Recommended Next Agent
**`conductor`** — all planning is done and captured in files. A fresh session with a
clean context is the right place to start M0.
