# Cairn CMS — PR Grading Rubric
> Last updated: 2026-04-15

Use this rubric after merging every PR. Self-grade honestly — the point is calibration,
not a score to show anyone. Over time, watch your scores improve.

---

## How to Grade

After merging your PR, read through your diff on GitHub. Score each dimension 1–3.
Add up the five scores. Record the result in your learning log with a one-sentence note
on what you'd do differently.

**Grade scale:**
- 1 — Needs work. A reviewer would ask for changes here.
- 2 — Solid. Gets the job done. Room for improvement but nothing blocking.
- 3 — Strong. A senior engineer would nod and move on.

**Total out of 15.**
- 12–15: Production-ready. This is the standard.
- 8–11: Functional. Focus on the dimensions below 2.
- Below 8: Don't move to the next ticket yet. Revisit the dimension that scored lowest.

---

## The Five Dimensions

### 1. Correctness
Does it work? Does it handle the edge cases named in the acceptance criteria?

| Score | What it looks like |
|-------|--------------------|
| 1 | Some acceptance criteria are unmet, or the fix works for the happy path but breaks on edge cases in the ticket. |
| 2 | All acceptance criteria are met. Basic edge cases handled. No obvious regression in related behavior. |
| 3 | All criteria met. You found and handled an edge case the ticket didn't mention. You verified with manual testing steps described in the PR. |

---

### 2. Code Quality
Is the code readable, idiomatic, and scoped to what the ticket asked?

| Score | What it looks like |
|-------|--------------------|
| 1 | The change works but introduces code smell: a method doing two things, a magic string instead of a constant, a raw SQL string in a controller, or a change much larger than the ticket asked for. |
| 2 | Code is clean and idiomatic. Follows existing patterns in the file. No unnecessary abstraction, no unnecessary scope creep. |
| 3 | Code is idiomatic and reads as if it was always there. You noticed an adjacent smell and either fixed it (in a separate commit with a note) or opened a follow-up ticket instead of silently leaving it. |

---

### 3. Test Coverage
Are the relevant paths tested? Are tests useful, not just present?

| Score | What it looks like |
|-------|--------------------|
| 1 | No tests added or modified, OR tests exist but only cover the happy path and would not catch a regression. |
| 2 | At least one meaningful test covers the new or fixed behavior. A regression in this code would cause a test failure. |
| 3 | Happy path and at least one failure/edge-case path are tested. Test descriptions are readable (`it "redirects an unauthorized author"` not `it "works"`). |

---

### 4. Git Discipline
Do the commits tell a coherent story?

| Score | What it looks like |
|-------|--------------------|
| 1 | Single "wip" or "fix" commit containing everything, OR commits include unrelated changes, OR commit messages describe *what* not *why* ("add index" instead of "index posts.status to avoid full scans on editor dashboard"). |
| 2 | Commits are reasonably atomic. Messages are in imperative mood and explain what changed. No debug artifacts committed. |
| 3 | Each commit is a single logical unit. If you squint at the commit list, you can reconstruct the reasoning without reading the diff. Branch name matches the ticket type and description. |

---

### 5. PR Communication
Would a teammate understand this PR without asking you questions?

| Score | What it looks like |
|-------|--------------------|
| 1 | PR description is empty, minimal, or just repeats the ticket title. No testing instructions. No screenshots for UI changes. |
| 2 | PR description explains what changed and why. Manual testing steps are included. For UI changes, before/after described (screenshots ideal). |
| 3 | PR description reads as if you're on-call in two weeks and will have forgotten the context. Links the relevant ticket. Notes any tradeoffs or follow-up work explicitly. Responds to any simulated review comments in the ticket. |

---

## Dimension Weights by Ticket Type

Not all dimensions matter equally for every ticket. The ticket will call out the
primary dimensions, but here's the general guide:

| Ticket type | Primary dimensions | Secondary |
|-------------|-------------------|-----------|
| `bug` | Correctness, Test Coverage | Git Discipline |
| `feature` | Correctness, Code Quality | PR Communication |
| `migration` | Correctness, Git Discipline | Code Quality |
| `refactor` | Code Quality, Test Coverage | Correctness |
| `chore` | Correctness, Git Discipline | — |
| `ui` | Correctness, PR Communication | Code Quality |

---

## Using the Rubric

### Trigger
Run a self-review after every merged PR. Open your PR on GitHub, read the diff top to
bottom, and score each dimension without looking at the scores first.

### Recording
Keep a `LEARNING_LOG.md` in the repo root. One entry per PR:

```
## PR: fix/soft-delete-scope-leak
Date: YYYY-MM-DD
Scores: Correctness 3 | Code Quality 2 | Tests 2 | Git 3 | PR Comm 2 = 12/15
Note: Tests were technically present but the edge case I missed (unscoped admin view)
      wasn't covered. Next time: read the steps to reproduce as the test spec outline.
```

### Claude-assisted grading
If you want an external perspective, paste your PR diff into a Claude conversation with:
> "Grade this PR against the Cairn CMS rubric. Be specific about what score each
> dimension earns and why. Don't soften it."

Claude will score each dimension with justification. Use it as a calibration check,
not as the ground truth — self-assessment is the skill.
