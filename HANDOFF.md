# HANDOFF BRIEF — CAIRN CMS
Generated: 2026-04-16

---

## What This Project Is
A Rails 7.2 learning environment — a realistic multi-user CMS with roles, publishing
workflows, and a structured ticket backlog. The learner works through GitHub Issues
as if on a real team.

---

## Where We Are
- **Current phase:** Active build — M0–M4 complete, M5 starting
- **Next milestone:** M5 — Soft Deletes + Seed Data

---

## What's Been Built
- M0: Rails 7.2 app, Postgres, Tailwind, Devise, seeds
- M1: Role enum (admin/editor/author), Pundit, UserPolicy, user profiles
- M2: Posts CRUD, ActionText body, PostPolicy with Pundit scoping
- M3: Publishing state machine (draft→in_review→published→archived), transition
  actions + policy gates, Admin::DashboardController with stats, admin nav link
- M4: Category + Tag models, Tagging join table, CategoriesController + TagsController,
  CategoryPolicy + TagPolicy (editor+ write, all read), category filter on posts
  index, category/tag pills on post show, 10 seeded posts with 4 categories + 8 tags
- UI redesign: Airtable-inspired design system (DESIGN.md), full Tailwind @theme tokens,
  nav shell, Devise sign-in styled

---

## What's In Progress
→ Nothing — M4 just completed, all changes uncommitted

---

## What's Next
1. **M5 — Soft Deletes** (db-architect → implementer → reviewer)
   - Add `discarded_at` datetime + index to posts (migration)
   - Wire Discard gem: `discard!`, `undiscard!`, default scope hides discarded
   - Switch `PostsController#destroy` to `post.discard!`
   - Add admin-only undiscard action + trash view (`Post.only_discarded`)
   - Extend PostPolicy: only admin can undiscard
   - Expand seeds to 25 posts (5 discarded, 3 in_review, 10 published, 7 draft)

2. **M6 — ActiveStorage Image Attachments**
   - `has_one_attached :cover_image` on Post
   - File upload on post form, thumbnail on index, image on show
   - Eager-load to prevent N+1

3. **M7 — GitHub Issues Backlog**
   - Verify ISSUES.md has 20 tickets, file on GitHub with labels + CODEOWNERS

---

## Open Items & Blockers
⚠ Everything since M2 is uncommitted — large diff, commit at start of next session
⚠ No .claude/agents/ in this project — all agents invoked from global config

---

## Key Files to Read First
1. `CLAUDE.md` — project conventions, what not to do, workflow rules
2. `PROJECT_PLAN.md` — full milestone breakdown and task list
3. `DESIGN.md` — design system tokens (required before any UI work)
4. `db/schema.rb` — current schema (categories, tags, taggings, category_id on posts)
5. `app/models/post.rb` — state machine + associations added in M3/M4
6. `app/policies/post_policy.rb` — all transition + CRUD gates

---

## Agent Map
| Agent | Role |
|---|---|
| `implementer` | All coding — models, controllers, views, policies |
| `db-architect` | Schema design and migrations |
| `reviewer` | Isolated code review after each milestone (fresh context) |
| `conductor` | Multi-step orchestration — reads plan, delegates one task at a time |

---

## Recommended Next Agent
**`db-architect`** — M5 starts with the `discarded_at` migration before any model/controller work.
