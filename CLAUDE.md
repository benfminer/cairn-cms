# CLAUDE.md — Cairn CMS

Cairn CMS is a Ruby on Rails learning environment. It is a multi-user Content Management System
with roles, publishing workflows, soft deletes, and a ticket backlog. The codebase is intentionally
realistic — it has bugs, edge cases, and layered complexity. The "user" of this repo is a solo
developer learning Rails by working through GitHub Issues tickets.

---

## What This Is

- **Not a production app.** It is a structured learning environment.
- The learner picks up tickets from ISSUES.md (or GitHub Issues), works them on feature branches,
  and opens PRs as if working with a real team.
- The app has real roles, real state machines, real authorization, and real bugs — all intentional.

---

## Tech Stack

| Layer | Choice |
|---|---|
| Language | Ruby 3.3 |
| Framework | Rails 7.2 |
| Database | PostgreSQL 15 |
| Frontend | Tailwind CSS 3.x (cssbundling-rails) + Hotwire (Turbo + Stimulus) |
| Auth | Devise |
| Authorization | Pundit |
| Storage | ActiveStorage (local disk in dev) |
| Pagination | Pagy |
| Search | PgSearch (v2) |
| Background Jobs | Sidekiq + Redis (v2 — not in v1) |
| Testing | RSpec + FactoryBot + Capybara |
| Schema Comments | Annotate |

---

## Common Commands

```bash
# Setup
bundle install
rails db:create db:migrate db:seed

# Development server
bin/dev                          # starts Rails + CSS watcher via Foreman/Procfile.dev

# Database
rails db:migrate
rails db:rollback
rails db:seed
rails db:schema:dump

# Tests (once RSpec is wired)
bundle exec rspec
bundle exec rspec spec/models/post_spec.rb
bundle exec rspec spec/policies/

# Annotate models
bundle exec annotate --models

# Console
rails console
rails console --sandbox           # no writes persisted

# Routes
rails routes | grep posts
```

---

## Seed Users

After `rails db:seed`, three users exist for local development:

| Email | Password | Role |
|---|---|---|
| admin@cairn.test | password | admin |
| editor@cairn.test | password | editor |
| author@cairn.test | password | author |

Sign in as different roles to test policy behavior.

---

## Architecture Notes

**Roles** are stored as an integer enum on the `users` table. Never compare roles as strings —
use the enum helpers (`user.admin?`, `user.editor?`).

**Pundit** gates every controller action. `ApplicationController` calls
`after_action :verify_authorized` — if you add a controller action without calling `authorize`,
tests will fail. Use `skip_after_action :verify_authorized` deliberately, never by accident.

**Post status** is an integer enum with four states: `draft`, `in_review`, `published`, `archived`.
State transitions are explicit methods on the model (`submit_for_review!`, `publish!`, etc.) —
do not set `post.status = :published` directly. The transition methods enforce valid paths.

**Soft deletes** use a `discarded_at` datetime column. The default scope on `Post` excludes
discarded records. Any `Post.unscoped` call in application code is a red flag — it almost
certainly leaks deleted content. Admin-only trash views use explicit `Post.only_discarded` scope.

**ActionText** stores the rich text body in a separate table. Eager-load it with
`Post.with_rich_text_body` when displaying post content to avoid N+1 queries.

**ActiveStorage** attachments need explicit eager loading:
`Post.with_attached_cover_image` — do this on any index query that renders thumbnails.

---

## Learning Workflow

### Picking up a ticket

1. Read the full issue in ISSUES.md or GitHub Issues. Understand the context before touching code.
2. Identify the files listed under "Files likely involved" — read them before changing anything.
3. Create a feature branch: `git checkout -b fix/soft-delete-scope-leak`
4. Make the change. Run the app manually to verify. Write or update tests.
5. Open a PR with: what changed, why, how to test it manually, and test coverage note.

### Branch naming

```
fix/short-description          # bugs
feature/short-description      # new features
migration/short-description    # schema changes
refactor/short-description     # internal rewrites
chore/short-description        # dependencies, seeds, tooling
```

### Commit discipline

- One logical change per commit
- Imperative mood: "Add bio field to users" not "Added bio field"
- Explain the why in the body when it isn't obvious:
  ```
  Add composite index on (author_id, status)

  Every posts index query filters by both columns. Without the composite
  index, Postgres falls back to a sequential scan as row count grows.
  ```

### PR discipline

Every PR description must include:
1. **What changed** — 2–3 sentences on the change
2. **Why** — the ticket context (link the issue)
3. **How to test manually** — step-by-step, assume the reviewer is starting from `rails db:seed`
4. **Test coverage** — what specs exist or were added

---

## Key Files

```
app/models/post.rb                  # Post model, status enum, transition methods, soft delete
app/models/user.rb                  # User model, role enum, Devise config
app/policies/post_policy.rb         # Pundit policy for posts
app/policies/application_policy.rb  # Base policy — read before writing any new policy
app/controllers/posts_controller.rb # Main CRUD + transition actions
app/controllers/admin/            # Admin-only controllers
db/seeds.rb                         # Seed data — run with rails db:seed
db/schema.rb                        # Source of truth for current schema (auto-generated)
ISSUES.md                           # Ticket backlog
PROJECT_PLAN.md                     # Build milestones and task list
PROJECT_VISION.md                   # Product requirements and decisions
```

---

## What Not To Do

- Do not call `Post.unscoped` outside of admin trash views
- Do not set `post.status =` directly — use the transition methods
- Do not add a controller action without a corresponding Pundit `authorize` call
- Do not hard-delete any Post record — use `post.discard!`
- Do not introduce Sidekiq, Redis, or background jobs in v1 work
- Do not add gems without checking if the functionality already exists in Rails core
