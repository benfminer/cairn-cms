# Project Plan: Cairn CMS

## Stack
Language/Framework: Ruby 3.3 / Rails 7.2
Database: PostgreSQL 15
Frontend: Tailwind CSS 3.x (cssbundling-rails) + Hotwire (Turbo + Stimulus — baseline only, extended via tickets)
Auth: Devise
Authorization: Pundit
Storage: ActiveStorage (local disk in dev)
Testing: RSpec + FactoryBot + Capybara (added via tickets, not pre-wired)
Hosting: Not targeted in v1
Rationale: Rails 7.2 with Hotwire gives a realistic full-stack Rails codebase at the complexity level where Pundit policies, state machines, and soft deletes all naturally arise. Learner has prior Ruby familiarity; this stack minimizes tool-learning overhead and maximizes Rails-concept density.

---

## Milestone 0: App Boots
Goal: A running Rails app with Postgres connected, Tailwind rendering, and Devise installed. Learner sees a login screen at `/`.

- [ ] Generate Rails 7.2 app with PostgreSQL, no default test framework | agent: implementer | size: M
- [ ] Install and configure Tailwind CSS via cssbundling-rails; verify a styled layout renders | agent: implementer | size: S
- [ ] Install Devise; generate User model; configure routes to redirect `/` to sign-in | agent: implementer | size: M
- [ ] Create `db/seeds.rb` stub; verify `rails db:create db:migrate db:seed` completes cleanly | agent: implementer | size: S
- [ ] QA M0: app boots, Postgres connected, sign-in page renders with Tailwind styles | agent: qa | size: S

## Milestone 1: Users and Roles
Goal: User model has a `role` enum (admin/editor/author). Pundit is installed with a permissive ApplicationPolicy. One working policy exists.

- [ ] Add `role` enum column to users (migration: add_role_to_users) | agent: db-architect | size: S
- [ ] Seed three users: one per role (admin@cairn.test, editor@cairn.test, author@cairn.test) | agent: implementer | size: S
- [ ] Install Pundit; add `authorize` call to ApplicationController; generate ApplicationPolicy | agent: implementer | size: S
- [ ] Add user profile page (show/edit own profile); write UserPolicy with `update?` scoped to owner or admin | agent: implementer | size: M
- [ ] Install Annotate gem; run against all models | agent: implementer | size: S
- [ ] Reviewer M1: role enum correct, Pundit wired, policy tested manually | agent: reviewer | size: S

## Milestone 2: Posts CRUD
Goal: Authors can create posts with a rich text body. Posts have a status field. Pundit gates all post actions — author sees only their own posts.

- [ ] Generate Post model: title (string), status (integer enum, default draft), author (references User), body (ActionText) | agent: db-architect | size: M
- [ ] Scaffold PostsController with full CRUD; apply Pundit authorize/policy_scope in every action | agent: implementer | size: L
- [ ] Write PostPolicy: index/show scoped to own posts for author, all posts for editor/admin; create/update/destroy owner-only | agent: implementer | size: M
- [ ] Post index view: list posts with title, status badge, author name, created date — Tailwind table | agent: implementer | size: M
- [ ] Post form: title field + ActionText body (trix editor) + status select hidden from author | agent: implementer | size: M
- [ ] QA M2: author cannot see other authors' posts; editor sees all; CRUD round-trip works | agent: qa | size: S

## Milestone 3: Publishing Workflow and Admin Dashboard
Goal: Posts move through draft → in_review → published via explicit transition actions. Only valid transitions are permitted. Admin dashboard shows content counts and user list.

- [ ] Add state transition methods to Post model (submit_for_review!, publish!, reject!, archive!) with guard clauses | agent: implementer | size: M
- [ ] Add transition routes and controller actions (POST /posts/:id/submit, /publish, /reject, /archive) | agent: implementer | size: M
- [ ] Extend PostPolicy: only author can submit own draft; only editor/admin can publish/reject/archive | agent: implementer | size: M
- [ ] Add status-aware UI buttons on post show page (submit/publish/reject/archive appear only when valid and authorized) | agent: implementer | size: M
- [ ] Generate AdminController with dashboard action: user count by role, post count by status, 10 most recent posts | agent: implementer | size: M
- [ ] Write AdminPolicy: all actions admin-only; after_action verify_authorized in AdminController | agent: implementer | size: S
- [ ] Reviewer M3: all transitions gated correctly, admin dashboard accessible only to admin | agent: reviewer | size: S

## Milestone 4: Categories and Tags
Goal: Posts can have one Category and many Tags. Editor/Admin manage categories and tags. Post index is filterable by category.

- [ ] Create Category model (name, slug); Tag model (name, slug); Tagging join table (post_id, tag_id) | agent: db-architect | size: M
- [ ] Add category_id FK to posts (migration); add has_many :tags through :taggings to Post | agent: db-architect | size: S
- [ ] Scaffold CategoriesController and TagsController; write CategoryPolicy and TagPolicy (editor+ to manage) | agent: implementer | size: L
- [ ] Add category and tag selects to post form; display on post show and index | agent: implementer | size: M
- [ ] Add category filter to posts index (query param, no JS required) | agent: implementer | size: S
- [ ] QA M4: author cannot create categories; editor can; posts filter by category correctly | agent: qa | size: S

## Milestone 5: Soft Deletes and Seed Data
Goal: Posts are never hard-deleted. A `discarded_at` column gates all queries. Seeds produce edge-case data. Learner encounters the scope leak bug via seed data.

- [ ] Migration: add `discarded_at` datetime to posts; add index | agent: db-architect | size: S
- [ ] Add `discard!`, `undiscard!`, `discarded?` methods to Post; add default scope excluding discarded records | agent: implementer | size: S
- [ ] Update PostsController destroy action to soft-delete; add admin-only undiscard action | agent: implementer | size: S
- [ ] Extend PostPolicy: only admin can undiscard; destroy permitted per existing rules | agent: implementer | size: S
- [ ] Write realistic seed data: 3 users, 25 posts in mixed states (5 discarded, 3 in_review, 10 published, 7 draft), 4 categories, 8 tags | agent: implementer | size: M
- [ ] QA M5: discarded posts invisible on index, admin undiscard restores post, seeds load cleanly | agent: qa | size: S

## Milestone 6: ActiveStorage Image Attachments
Goal: Posts can have a cover image. Image is displayed on post show and index thumbnail. Missing image renders a placeholder.

- [ ] Configure ActiveStorage for local disk; run `rails active_storage:install` | agent: implementer | size: S
- [ ] Add `has_one_attached :cover_image` to Post; add file upload field to post form | agent: implementer | size: S
- [ ] Display cover image on post show page; show thumbnail (or placeholder) on post index | agent: implementer | size: M
- [ ] Eager-load cover_image attachments on posts index to prevent N+1 | agent: implementer | size: S
- [ ] Reviewer M6: attachment persists, placeholder shown when absent, no N+1 on index | agent: reviewer | size: S

## Milestone 7: GitHub Issues Backlog
Goal: ISSUES.md is complete with 20 tickets (15 core + 5 UI). Tickets filed as GitHub Issues.

- [ ] Confirm ISSUES.md has all 20 tickets with tiered help blocks | agent: implementer | size: S
- [ ] File all 20 issues on GitHub with correct labels (type + level) | agent: implementer | size: S
- [ ] Create CODEOWNERS file assigning fictional reviewers by area | agent: implementer | size: S
- [ ] Verify each ticket references real files from the built codebase | agent: reviewer | size: S

## Milestone 8: Production Deployment
Goal: The app is live on Fly.io. The learner can share a URL. CI runs tests on every PR.

- [ ] Write Dockerfile for Rails 7.2 with asset precompilation in production build | agent: implementer | size: M
- [ ] Run `fly launch` to generate fly.toml; set app name and region | agent: implementer | size: S
- [ ] Set production secrets via `fly secrets set`: SECRET_KEY_BASE, DATABASE_URL, RAILS_MASTER_KEY | agent: implementer | size: S
- [ ] Provision Fly Postgres cluster and attach to app (`fly postgres create` + `fly postgres attach`) | agent: db-architect | size: S
- [ ] Run migrations remotely (`fly ssh console -C "bin/rails db:migrate"`) and verify no 500s | agent: implementer | size: S
- [ ] Create `.github/workflows/ci.yml`: run RSpec on every PR with Postgres service container | agent: implementer | size: M
- [ ] Smoke test: sign-in page loads, admin can sign in, posts index renders, no errors in `fly logs` | agent: qa | size: S
- [ ] Record deployed URL in README and LEARNING_LOG.md as graduation entry | agent: implementer | size: S
