# Cairn CMS — Rails Learning Environment
> Last updated: 2026-04-15

## Problem
Tutorials and books teach syntax. They don't teach how to work inside a real codebase —
navigating unfamiliar code, reading a ticket, making a scoped change, opening a PR, and
getting review feedback. This project exists to close that gap.

## What It Is
A multi-user Content Management System with roles, publishing workflows, media uploads,
and a ticket backlog. The CMS has real end users within the app (admins, editors,
authors, viewers), but the LEARNER is the only developer. Every feature and bug exists
to teach a specific skill.

## Target Users (within the app)
- **Admin** — full control: manage users, roles, site settings, all content
- **Editor** — can publish/unpublish any content, manage categories and tags
- **Author** — can create and submit their own content for review; cannot publish
- **Viewer** — read-only access to published content (future: public-facing)

## Tech Stack
- Ruby on Rails 7.2 (Hotwire: Turbo + Stimulus; no separate JS framework)
- PostgreSQL
- Tailwind CSS 3.x (via cssbundling-rails)
- Devise (authentication)
- Pundit (role-based authorization — explicit policy files are good for learning)
- ActiveStorage + local disk in dev, S3-compatible in prod
- Sidekiq + Redis (background jobs — scheduled publishing, notification emails)
- Pagy (pagination)
- PgSearch (full-text search)
- RSpec + FactoryBot + Capybara (test suite the learner writes into)
- Annotate gem (schema comments in models)

## Core Features — v1 (The Foundation)
1. Auth: sign up, sign in, sign out, password reset (Devise)
2. Role system: Admin/Editor/Author assigned at registration or by Admin
3. Posts CRUD: title, body (rich text via ActionText), status (draft/review/published)
4. Categories and Tags: many-to-many, managed by Editor+
5. Publishing workflow: Author submits → Editor approves/rejects → published
6. Media uploads: attach images to posts via ActiveStorage
7. Admin dashboard: user list, content counts, recent activity
8. Pundit policies: every controller action gated and tested
9. Soft deletes on Posts (discarded_at column — manual implementation)
10. Seed data: 3 users (one per non-admin role), 20+ posts in mixed states

## v2 Features (Adds Learning Complexity)
- Comments on posts (threaded, moderated by Editor)
- Scheduled publishing (Sidekiq job + publish_at datetime column)
- Audit log / activity feed (PaperTrail gem or manual — migration + model callbacks)
- Tagging autocomplete (Stimulus controller)
- Full-text search across posts and authors (PgSearch)
- Public-facing read view (no auth required, published posts only)
- API endpoints (JSON): posts index and show, token auth
- Email notifications (Sidekiq mailer jobs): on publish, on rejection

## Out of Scope (v1)
- Multi-tenancy (organizations/workspaces) — intentionally deferred to v2+
- Frontend JS framework (React, Vue) — Hotwire only
- OAuth / social login
- Paid tiers or billing
- Mobile app

## Intentional Complexity (What Makes This Real)
- **Role + policy layering**: same controller, different behavior per role. Pundit
  policies will conflict and require careful scoping — realistic bugs to fix.
- **State machine on posts**: draft → in_review → published → archived. Invalid
  transitions are bugs worth writing.
- **Soft deletes**: records are never hard-deleted. Queries must scope correctly or
  deleted content leaks — a classic real-world bug category.
- **Background jobs**: scheduled publishing can fail silently. Sidekiq retries, dead
  queues, and job idempotency are all learnable failure modes.
- **ActiveStorage variants**: image resizing, missing attachments, N+1 on attachment
  eager-loading — each a distinct ticket.
- **Seed complexity**: factories produce edge-case data (posts with no author, tags with
  no posts, users with no content) to surface assumption bugs.

## Learning System — GitHub Issues as Tickets

### Ticket Categories
- `bug` — broken behavior with repro steps, expected vs actual output
- `feature` — new capability with acceptance criteria
- `migration` — schema change (add column, index, rename) with rollback notes
- `refactor` — improve existing code without changing behavior; includes tests
- `chore` — dependency update, seed improvement, CI config
- `ui` — Tailwind/frontend work: layout, responsive behavior, component extraction,
  accessibility, Stimulus controllers

### Difficulty Labels
- `level:1` — single file, clear location, no policy or job impact
- `level:2` — 2–3 files, requires understanding a flow (controller → policy → view)
- `level:3` — cross-cutting (migration + model + policy + test + seed)
- `level:4` — architectural (new job, new concern, refactor a workflow)

### Simulated Team Workflow
Every ticket should be worked on a feature branch. CODEOWNERS file assigns fictional
reviewers to different areas (models, policies, views, migrations). PR descriptions must
include:
- What changed and why
- How to test it manually (step-by-step)
- Screenshots for UI changes
- Test coverage note

Simulated PR review comments are embedded in level:3 and level:4 tickets. The learner
must respond to these comments (in their actual PR description or inline) before
considering the ticket complete.

Skills the learner will practice:
- **Branching**: `git checkout -b fix/soft-delete-scope-leak`
- **Commit discipline**: atomic commits, imperative mood, explain the "why"
- **PR descriptions**: written as if a teammate needs to review without context
- **Code review**: tickets include pre-written review comments to respond to
- **Merge conflicts**: some tickets intentionally touch the same file
- **Rebasing vs merging**: both patterns present in the backlog
- **Reverting**: at least one ticket is "this commit broke staging, revert and fix"

### Tiered Help System
Every ticket includes three help tiers at the bottom, below the main ticket body.
The tiers are structured to reward effort before revealing more:

- **Tier 1 (Nudge):** Always visible. One sentence. Confirms the learner is looking in
  the right place. No spoilers.
- **Tier 2 (Guidance):** In a collapsed `<details>` block. 3–5 sentences. Names the
  concept, points to the right file or method, explains the why without giving the
  solution. Expand after ~20 minutes of genuine effort.
- **Tier 3 (Walkthrough):** In a second collapsed `<details>` block. Step-by-step
  solution path. For when the learner has been stuck 45+ minutes. No shame — the goal
  is learning, not suffering.

The collapsed block labels use first-person commitment language ("I've been stuck for
20+ minutes") so the learner must affirmatively claim the state before expanding.

### Grading System
After merging every PR, the learner self-grades against the rubric in `RUBRIC.md`.
Five dimensions: Correctness, Code Quality, Test Coverage, Git Discipline, PR
Communication. Each scored 1–3. Total out of 15.

Results are recorded in `LEARNING_LOG.md`. Claude-assisted grading is available: paste
the PR diff and ask Claude to score it against the rubric and be specific.

## Starter Ticket Backlog (v1)
The backlog is intentionally unordered. Figuring out where to start is part of the
skill. Pick a ticket that matches your current confidence — or one that scares you.

| # | Type | Title | Level |
|---|------|-------|-------|
| 1 | feature | Add author bio field to user profile | 1 |
| 2 | bug | Soft-deleted posts appear in Editor dashboard | 2 |
| 3 | migration | Add published_at timestamp to posts | 2 |
| 4 | feature | Add pagination to posts index | 2 |
| 5 | bug | Author can edit another author's draft via URL | 3 |
| 6 | refactor | Extract post status badge into a partial | 2 |
| 7 | feature | Add category filter to posts index | 3 |
| 8 | migration | Add index on posts.status and posts.author_id | 1 |
| 9 | bug | N+1 query on posts index (tags not eager-loaded) | 3 |
| 10 | feature | Admin can impersonate any user | 4 |
| 11 | migration | Add discarded_at index to posts table | 1 |
| 12 | refactor | Post status transitions to use a state machine concern | 4 |
| 13 | chore | Improve seed data with edge-case users and posts | 2 |
| 14 | chore | Run Annotate on all models and commit schema comments | 1 |
| 15 | bug | Posts index 500 error when current user is hard-deleted | 3 |
| 16 | ui | Mobile nav breaks at 375px viewport | 2 |
| 17 | ui | Status badge colors fail WCAG AA contrast | 1 |
| 18 | ui | Extract post card into a reusable Tailwind component | 2 |
| 19 | ui | Add dark mode support to the admin dashboard | 3 |
| 20 | ui | Implement tag input with Stimulus autocomplete | 3 |

## Success Criteria
- Learner can pick up any level:1 or level:2 ticket cold, complete it on a branch, and
  open a PR that a real engineer would not reject on process grounds.
- Learner understands what Pundit is doing and can write a new policy from scratch.
- Learner can write a migration, run it, and roll it back without breaking seed data.
- Learner is comfortable reading a stack trace and locating the relevant file/line.
- Learner has deployed the app to Fly.io (M8) and it is accessible at a public URL.
- Learner's average PR score across the final five tickets is 11/15 or higher.

## Milestones
- **M1–M7**: Feature/bug/refactor work drawn from the unordered backlog
- **M8 (Graduation)**: Deploy to production on Fly.io. Includes env var management,
  production database setup, GitHub Actions CI, and a live smoke test. The learner hits
  real production problems (asset compilation, missing env vars, unmigrated database)
  and solves them. Completion = a public URL that works end-to-end.

## Decisions

1. **Auth scope**: Everything behind auth in v1 — no public-facing view. Simpler Pundit scoping.
2. **Sidekiq**: Deferred to v2. Introduced via a "scheduled publishing" feature ticket so the learner understands *why* background jobs exist before adding them.
3. **Tickets**: Live in this same repo. Issues in the same repo as the code is the most realistic team setup.
4. **ViewComponent**: Not included in v1. Introduced as a level:2 refactor ticket — learner migrates one partial to a component and learns why the abstraction exists.
5. **RSpec**: Not pre-written for the learner. Tickets ask the learner to write tests for existing code — read first, write second.
6. **Backlog ordering**: Unordered by design. Choosing where to start is the skill.
7. **Tiered help**: All three tiers live in the ticket body. Tiers 2 and 3 use collapsed HTML `<details>` blocks with commitment-language labels. No separate walkthrough file — that adds friction that penalizes legitimate use.
8. **Grading**: Self-applied rubric, 5 dimensions, 1–3 scale. Claude-assisted grading available on demand. Results tracked in LEARNING_LOG.md.
9. **Deployment**: Fly.io. M8 is a mandatory graduation milestone, not optional.
