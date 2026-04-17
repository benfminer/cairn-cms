# EOD Note — 2026-04-16

## Where Things Stand

Cairn CMS is feature-complete as a learning scaffold. Milestones M0–M7 are all done; the GitHub repo is live at github.com/benfminer/cairn-cms with 21 learner tickets filed. The only remaining milestone (M8) is intentionally left for the learner to solve.

## Completed Today

- M5: Soft deletes — `discarded_at` migration, `discard!`/`undiscard!` on Post, controller actions, PostPolicy gating, realistic seed data (25 posts, 5 discarded), QA verified
- M6: ActiveStorage cover images — `has_one_attached :cover_image`, mini_magick, file upload form, thumbnail on index, full image on show, eager-load, reviewer pass (fixed raw image variant + Post.unscoped scope leak)
- M7: GitHub issues backlog — created repo, pushed all commits, created 11 labels, filed all 21 tickets (#2–#22), CODEOWNERS, fixed dashboard view path bug in tickets 3/6/19, added dependency note to ticket 17
- Converted M8 from "tasks we build" to learner graduation ticket (GitHub Issue #22)

## In Progress

- M5/M6 changes are uncommitted locally — need one final commit to clean up

## Pick Up Here Tomorrow

The scaffold is done. Start learner-mode: pick up a ticket from [github.com/benfminer/cairn-cms/issues](https://github.com/benfminer/cairn-cms/issues), create a feature branch, and work the ticket as a learner would. Good first ticket: **Issue #3 (level:1)** — Add author bio field, or **Issue #9 (level:1)** — Add index on posts.status and author_id.

## Open Questions

- None — project is complete as a scaffold

## Reminders

- Start dev server: `bin/dev` (port 3000)
- Seed users: admin@cairn.test / editor@cairn.test / author@cairn.test (password: password)
- GitHub repo: github.com/benfminer/cairn-cms
