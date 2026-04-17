# Cairn CMS — GitHub Issues Backlog

These tickets are written to be filed as GitHub Issues. Work each one on a feature branch.
Branch naming: `fix/`, `feature/`, `migration/`, `refactor/`, `chore/` prefix + kebab-case description.

---

## Issue 1: Add author bio field to user profile

**Labels:** `feature`, `level:1`

**Context:**
The User model currently stores only email, encrypted password, and role. Authors need a bio field to display on their profile page and (eventually) on published post pages. This is a pure additive change — no behavior breaks if bio is nil.

**Acceptance criteria:**
- [ ] `bio` text column exists on the `users` table
- [ ] Bio renders on the user profile show page
- [ ] Author and Admin can edit their own bio via the profile edit form
- [ ] Empty bio renders gracefully (no nil errors, no blank `<p>` tag)
- [ ] Migration is reversible (`rails db:rollback` restores prior state)

**Files likely involved:**
- `db/migrate/YYYYMMDDHHMMSS_add_bio_to_users.rb` (new)
- `app/models/user.rb`
- `app/views/users/show.html.erb`
- `app/views/users/edit.html.erb`

**Hint:** `rails generate migration AddBioToUsers bio:text` writes the migration skeleton for you.

---

**Tier 1 — Nudge:** The migration generator and the `users/edit` form are exactly where you need to be — start with the database change before touching any views.

<details>
<summary>I've been stuck for 20+ minutes — show me Tier 2</summary>

This ticket involves the standard Rails "add a column" pattern: generate a migration, permit the new attribute in the controller's strong params, then render it in the view. The key concept is that `text` columns in Rails can be nil, so any view that renders `@user.bio` must guard against nil — a simple `if @user.bio.present?` wrapper is all you need. Check `app/controllers/users_controller.rb` for where `params.require(:user).permit(...)` is called — the bio field will not save unless it is listed there. Then look at the existing form in `app/views/users/edit.html.erb` to see how other fields are structured and mirror that pattern.

</details>

<details>
<summary>I've been stuck for 45+ minutes — show me Tier 3 (full walkthrough)</summary>

1. Run `rails generate migration AddBioToUsers bio:text` — this creates the migration file with `add_column :users, :bio, :text`.
2. Run `rails db:migrate` and verify `db/schema.rb` now lists the `bio` column under `create_table "users"`.
3. Open `app/controllers/users_controller.rb` and find the `user_params` private method. Add `:bio` to the permitted params list.
4. Open `app/views/users/edit.html.erb` and add a `textarea` field for `bio` — use `f.text_area :bio` if it's a form builder form, following the style of existing fields.
5. Open `app/views/users/show.html.erb` and add a conditional: `<% if @user.bio.present? %>` render the bio in a paragraph, `<% end %>`. This prevents a blank `<p>` when bio is nil.
6. Test rollback: run `rails db:rollback` and confirm the `bio` column disappears from `schema.rb`, then `rails db:migrate` again to restore it.

</details>

---

## Issue 2: Soft-deleted posts appear in Editor dashboard

**Labels:** `bug`, `level:2`

**Context:**
Posts are soft-deleted by setting `discarded_at`. The default scope on `Post` excludes records where `discarded_at IS NOT NULL`. The editor dashboard queries posts directly, but the admin undiscard view loads posts without the default scope using `Post.unscoped`. A recent change accidentally used `Post.unscoped` in the wrong place, and now soft-deleted posts are visible to editors on the main posts index.

**Steps to reproduce:**
1. Sign in as editor@cairn.test
2. Navigate to `/posts`
3. Observe posts with a "Deleted" badge in the list

**Expected behavior:** Editors see no discarded posts on `/posts`. Discarded posts are only visible to admins via a separate `/admin/trash` view.

**Actual behavior:** Discarded posts appear in the editor's posts index.

**Files likely involved:**
- `app/controllers/posts_controller.rb`
- `app/models/post.rb`

---

**Tier 1 — Nudge:** The problem is in the controller's index query — something is bypassing the model's default scope that would normally filter discarded records out.

<details>
<summary>I've been stuck for 20+ minutes — show me Tier 2</summary>

The concept here is Rails default scopes and how `Post.unscoped` blows them all away. Open `app/models/post.rb` and find the `default_scope` (or scope that filters `discarded_at IS NULL`). Then open `app/controllers/posts_controller.rb` and look at the `index` action — somewhere in the query chain you'll find `unscoped` or a call that bypasses the default scope. The fix is to remove that bypass so the default scope applies again. Be careful: if `unscoped` is chained with a `where` clause, removing it bare will drop that `where` too — you may need to replace `Post.unscoped.where(...)` with just `Post.where(...)`.

</details>

<details>
<summary>I've been stuck for 45+ minutes — show me Tier 3 (full walkthrough)</summary>

1. Open `app/models/post.rb` and read the default scope — it should contain something like `where(discarded_at: nil)` or use a gem's `kept` scope.
2. Open `app/controllers/posts_controller.rb` and read the `index` action in full. Look for `Post.unscoped` or any chain that starts differently than a plain `Post.` call.
3. Identify the `unscoped` call. Replace `Post.unscoped` with `Post` (plain) so the default scope is active. If there are additional `where` conditions chained after `unscoped`, keep those — just drop the `unscoped` part.
4. Reload `/posts` as editor@cairn.test and confirm the deleted posts are gone.
5. Navigate to `/admin/trash` as admin and confirm discarded posts still appear there (that view intentionally uses `unscoped` or `with_discarded` — do not change it).
6. Check `app/models/post.rb` again to confirm the default scope is still intact and you have not accidentally removed it.

</details>

---

## Issue 3: Add `published_at` timestamp to posts

**Labels:** `migration`, `level:2`

**Context:**
The publishing workflow transitions a post to `published` status, but there is no timestamp recording when this happened. The admin dashboard needs to display "published X days ago" and future scheduled publishing (v2) will depend on this column.

**Schema change:**
Add `published_at datetime` to the `posts` table. The column should be null by default. When a post transitions to `published` status, `published_at` should be set to the current time. When a post is unpublished (archived or rejected), `published_at` should be cleared.

**Rollback note:** `rails db:rollback` must leave the table in its prior state. Verify no published post data is corrupted on rollback.

**Model/index changes:**
- No index required on this column in v1 (added later via Issue 8)
- The `publish!` method in `Post` must set `published_at = Time.current`
- The `reject!` and `archive!` methods must set `published_at = nil`

**Files likely involved:**
- `db/migrate/YYYYMMDDHHMMSS_add_published_at_to_posts.rb` (new)
- `app/models/post.rb` (transition methods)
- `app/views/admin/dashboard/show.html.erb` (display)

---

**Tier 1 — Nudge:** Start with the migration, then find the `publish!` method in the Post model — that is where the timestamp assignment belongs.

<details>
<summary>I've been stuck for 20+ minutes — show me Tier 2</summary>

This ticket has two distinct parts: the schema change and the model behavior. The migration is straightforward — `add_column :posts, :published_at, :datetime`. The more interesting part is the model: open `app/models/post.rb` and locate the `publish!`, `reject!`, and `archive!` methods. These methods change the post's status — you need to add timestamp assignment inside each one. The key concept is that `published_at` should be set as part of the same operation that changes status, ideally before or alongside `save!`. Use `Time.current` rather than `Time.now` so it respects the app's configured time zone. For the view, look at how Rails renders relative time — the `time_ago_in_words` helper is what you want.

</details>

<details>
<summary>I've been stuck for 45+ minutes — show me Tier 3 (full walkthrough)</summary>

1. Generate the migration: `rails generate migration AddPublishedAtToPosts published_at:datetime`. Open the generated file and confirm it uses `add_column :posts, :published_at, :datetime` — no default value needed.
2. Run `rails db:migrate` and check `schema.rb` for the new column.
3. Open `app/models/post.rb` and find the `publish!` method. Inside it, add `self.published_at = Time.current` before (or alongside) the status update, then `save!`.
4. Find the `reject!` method. Add `self.published_at = nil` before saving.
5. Find the `archive!` method. Add `self.published_at = nil` before saving.
6. Open `app/views/admin/dashboard.html.erb` and find where posts are listed. Add a column or line that renders `time_ago_in_words(post.published_at)` with a nil guard: `post.published_at ? time_ago_in_words(post.published_at) + " ago" : "Not published"`.
7. Test rollback: `rails db:rollback` and confirm the column is removed from `schema.rb`.

</details>

---

## Issue 4: Add pagination to posts index

**Labels:** `feature`, `level:2`

**Context:**
The posts index loads all records in a single query. With 25+ seed posts this is already slow to scan visually, and it will degrade as content grows. Pagy is already in the Gemfile but not wired up.

**Acceptance criteria:**
- [ ] Posts index paginates at 10 posts per page
- [ ] Page controls render below the table (Pagy nav helper)
- [ ] Navigating to `?page=2` shows the correct records
- [ ] Current page is preserved when a category filter is also active
- [ ] Total count ("Showing 11–20 of 25 posts") is displayed above the table
- [ ] No N+1 introduced — verify with `bullet` or query logs

**Files likely involved:**
- `Gemfile` (add `gem "pagy"`)
- `app/controllers/posts_controller.rb`
- `app/controllers/application_controller.rb` (include Pagy::Backend)
- `app/helpers/application_helper.rb` (include Pagy::Frontend)
- `app/views/posts/index.html.erb`

---

**Tier 1 — Nudge:** Pagy needs to be included in two places (backend and frontend) before the controller call will work — check the Pagy docs for the include pattern.

<details>
<summary>I've been stuck for 20+ minutes — show me Tier 2</summary>

Pagy works in three steps: include the backend module in `ApplicationController`, include the frontend module in `ApplicationHelper`, then call `pagy(collection)` in the controller action instead of returning the raw collection. The concept is that `pagy` returns two objects: a `@pagy` metadata object and the paginated `@posts` array. In the view you call `pagy_nav(@pagy)` to render the page links, and `pagy_info(@pagy)` to render the "Showing X–Y of Z" string. The most common mistake is forgetting the `include Pagy::Frontend` in the helper — if you see an undefined method error in the view, that is why.

</details>

<details>
<summary>I've been stuck for 45+ minutes — show me Tier 3 (full walkthrough)</summary>

1. Open `app/controllers/application_controller.rb` and add `include Pagy::Backend` inside the class body.
2. Open `app/helpers/application_helper.rb` and add `include Pagy::Frontend` inside the module body.
3. Open `app/controllers/posts_controller.rb` and find the `index` action. Change the line that assigns `@posts` from `@posts = Post.all` (or the policy-scoped version) to `@pagy, @posts = pagy(policy_scope(Post), items: 10)`.
4. Open `app/views/posts/index.html.erb`. Above the table, add `<%== pagy_info(@pagy) %>` to show the count string. Below the table (or below the closing `</table>` tag), add `<%== pagy_nav(@pagy) %>` for the page controls. Note the double-equals `<%==` — Pagy returns raw HTML and it must not be escaped.
5. Reload the posts index and verify page 1 shows 10 records. Add `?page=2` to the URL and confirm the next 10 appear.
6. If a category filter is present (from Issue 7), confirm the `?page=` and `?category_id=` params coexist in the nav links — Pagy handles this automatically via the request's existing params.

</details>

---

## Issue 5: Author can edit another author's draft via direct URL

**Labels:** `bug`, `level:3`, `security`

**Context:**
PostPolicy#update? checks that the current user is the post's author. However, the check uses `record.author` compared to `user`, and there is a gap: the `edit` action calls `@post = Post.find(params[:id])` before `authorize @post`, which means the object is loaded from the database with no scope. An author who knows another author's post ID can navigate to `/posts/:id/edit` and successfully load the edit form.

**Steps to reproduce:**
1. Sign in as the first author (author1@cairn.test)
2. Note the ID of a draft post belonging to author2@cairn.test (visible in seeds)
3. Navigate to `/posts/:id/edit` using that ID
4. Observe the edit form loads without error

**Expected behavior:** A 403 (Pundit::NotAuthorizedError) is raised and the user is redirected with an error flash.

**Actual behavior:** The edit form loads and the author can submit changes to another user's post.

**Files likely involved:**
- `app/policies/post_policy.rb`
- `app/controllers/posts_controller.rb`
- `spec/policies/post_policy_spec.rb` (write this if it doesn't exist)

**Note:** Fix the policy first. Then add a request spec that proves the fix holds. The bug is subtle — read the Pundit docs on `policy_scope` vs `authorize` before changing code.

---

**Tier 1 — Nudge:** The policy file is where the ownership check lives — read `PostPolicy#update?` carefully before looking at the controller.

<details>
<summary>I've been stuck for 20+ minutes — show me Tier 2</summary>

Pundit's `authorize @post` calls `PostPolicy#update?` with the current user and the post record. Open `app/policies/post_policy.rb` and read the `update?` method — it likely compares `record.user` or `record.author_id` to `user.id`. The bug is not necessarily in this comparison itself; it may be that the method has a condition that unintentionally allows any authenticated user through (for example, `user.present?` being evaluated before the ownership check). Read the method logic as a boolean expression carefully. Another place to look: is `authorize @post` actually being called in the `edit` action, or has it been accidentally removed? Policy specs are the best way to prove the fix — write a spec that calls `PostPolicy.new(other_author, post).update?` and asserts it returns false.

</details>

<details>
<summary>I've been stuck for 45+ minutes — show me Tier 3 (full walkthrough)</summary>

1. Open `app/policies/post_policy.rb` and read `update?`. Write down what the method returns for an author who does not own the post — trace through every condition.
2. Identify the logical gap. Common causes: `user.author? || record.author_id == user.id` where the first condition is always true for authors; or a missing `authorize` call in the controller.
3. Open `app/controllers/posts_controller.rb` and verify the `edit` action calls `authorize @post` after `@post = Post.find(params[:id])`. If it is missing, add it.
4. Fix the policy so `update?` returns true only when `record.author_id == user.id` (for authors) or `user.admin?` or `user.editor?` per your app's intended rules.
5. Open or create `spec/policies/post_policy_spec.rb`. Write at least two specs: one asserting `update?` returns true for the post's own author, and one asserting it returns false for a different author. Run them with `bundle exec rspec spec/policies/post_policy_spec.rb`.
6. Manually reproduce the original steps to confirm the 403 now fires.

</details>

---

## Issue 6: Refactor post status badge into a partial

**Labels:** `refactor`, `level:2`

**Context:**
The post status badge (a colored span showing draft/in_review/published/archived) is copy-pasted in three views: `posts/index.html.erb`, `posts/show.html.erb`, and `admin/dashboard.html.erb`. Any style change requires editing three files. Extract this into a shared partial with a consistent interface.

**What to change:**
- Create `app/views/shared/_status_badge.html.erb`
- The partial should accept a `status` local variable and render the appropriate CSS classes
- Replace all three inline badge implementations with `render "shared/status_badge", status: post.status`

**What must NOT change:**
- Visual appearance of the badge in any view
- The status strings displayed to the user
- No behavior changes — this is style/structure only

**Verification:** Run a visual diff by loading all three pages before and after. Badge appearance must be identical.

**Files likely involved:**
- `app/views/shared/_status_badge.html.erb` (new)
- `app/views/posts/index.html.erb`
- `app/views/posts/show.html.erb`
- `app/views/admin/dashboard/show.html.erb`

---

**Tier 1 — Nudge:** Find all three badge implementations first and read them side by side — the partial's job is to replace all three with a single source of truth.

<details>
<summary>I've been stuck for 20+ minutes — show me Tier 2</summary>

This ticket is about Rails partials and local variables. When you call `render "shared/status_badge", status: post.status`, Rails renders `app/views/shared/_status_badge.html.erb` with a local variable called `status` set to whatever `post.status` returns (a string like "draft"). Inside the partial, you will use a `case status` statement (or a hash lookup) to map each status string to a set of CSS classes. The tricky part is making the CSS class selection work — a `case` statement that returns a class string is clean and readable. The `shared/` directory may not exist yet — you will need to create it.

</details>

<details>
<summary>I've been stuck for 45+ minutes — show me Tier 3 (full walkthrough)</summary>

1. Open all three badge source locations and copy the HTML from one of them — you will use it as the template for the partial.
2. Create the directory `app/views/shared/` if it does not exist.
3. Create `app/views/shared/_status_badge.html.erb`. Write a `case status` block that assigns a local `css_classes` variable based on the status string: `"draft"` → one set of classes, `"in_review"` → another, etc. Then render a single `<span class="<%= css_classes %>"><%= status.humanize %></span>`.
4. Open `app/views/posts/index.html.erb`. Find the inline badge HTML. Replace it with `<%= render "shared/status_badge", status: post.status %>`.
5. Repeat for `app/views/posts/show.html.erb` and `app/views/admin/dashboard.html.erb`.
6. Load all three pages in the browser and compare the badge rendering visually to a screenshot or notes from before. The text and color must be identical.
7. As a final check, do a project-wide search for the old badge HTML (a unique CSS class from it) — confirm there are no remaining copies.

</details>

---

## Issue 7: Add category filter to posts index

**Labels:** `feature`, `level:3`

**Context:**
The posts index shows all posts (scoped to the current user's role). Editors need to filter by category to manage content efficiently. The filter must compose with pagination (Issue 4) — navigating to page 2 of a filtered result must preserve the category param.

**Acceptance criteria:**
- [ ] A category dropdown or link list renders above the posts table
- [ ] Selecting a category filters posts to only that category (`?category_id=3`)
- [ ] "All categories" option clears the filter
- [ ] Filter composes correctly with `?page=` param
- [ ] Posts with no category are still visible when no filter is active
- [ ] Policy scope still applies — author only sees their own posts even when filtering
- [ ] No raw SQL in the controller — use a named scope or ActiveRecord chaining

**Files likely involved:**
- `app/controllers/posts_controller.rb`
- `app/models/post.rb` (add scope)
- `app/views/posts/index.html.erb`

---

**Tier 1 — Nudge:** The filter logic belongs in a named scope on the Post model, not raw SQL in the controller — look at how other scopes are defined in `post.rb` first.

<details>
<summary>I've been stuck for 20+ minutes — show me Tier 2</summary>

This ticket has three moving parts: a scope on the model, conditional chaining in the controller, and URL generation in the view. In `post.rb`, define a scope like `scope :by_category, ->(id) { where(category_id: id) }`. In the controller's `index` action, apply this scope conditionally: `posts = posts.by_category(params[:category_id]) if params[:category_id].present?`. The view needs to generate links that set `?category_id=X` while preserving any existing `?page=` param — use `url_for(params.permit(:page).merge(category_id: category.id))` to build each link safely. The "All categories" link should point to `url_for(params.permit(:page).except(:category_id))` to clear the filter without losing the current page.

</details>

<details>
<summary>I've been stuck for 45+ minutes — show me Tier 3 (full walkthrough)</summary>

1. Open `app/models/post.rb` and add a scope: `scope :by_category, ->(category_id) { where(category_id: category_id) }`.
2. Open `app/controllers/posts_controller.rb`, find the `index` action, and locate where `@posts` is assigned. After the policy scope, add: `@posts = @posts.by_category(params[:category_id]) if params[:category_id].present?`.
3. Also assign `@categories = Category.order(:name)` in the index action so the view has something to render.
4. Open `app/views/posts/index.html.erb`. Above the table, add a filter section. Render a link for "All categories" using `link_to "All", posts_path`. Then loop `@categories` and render a link per category: `link_to category.name, posts_path(category_id: category.id)`.
5. Highlight the currently active filter — compare `params[:category_id].to_i` to `category.id` and add an "active" CSS class to the matching link.
6. Verify: select a category, then navigate to page 2 if there are enough posts — the category param should persist. Select "All categories" and confirm all posts return.
7. Sign in as an author and confirm filtering still only shows their own posts.

</details>

---

## Issue 8: Add index on `posts.status` and `posts.author_id`

**Labels:** `migration`, `level:1`

**Context:**
The posts index queries are filtered by both `status` and `author_id` on every page load. Neither column is indexed. With 25 seed posts this is imperceptible, but it is a correctness issue — these columns will be indexed in any real production schema.

**Schema change:**
Add a composite index on `(author_id, status)` and a standalone index on `status`. The composite handles the most common query pattern (author's own posts by status). The standalone index supports admin/editor queries filtered by status only.

**Rollback note:** Both indexes must be included in the `down` block. Test rollback before opening a PR.

**Migration should include:**
```ruby
add_index :posts, :status
add_index :posts, [:author_id, :status]
```

**Files likely involved:**
- `db/migrate/YYYYMMDDHHMMSS_add_indexes_to_posts.rb` (new)

**Hint:** Run `rails db:migrate` then `rails db:rollback` and confirm the schema returns to its prior state before pushing.

---

**Tier 1 — Nudge:** This is a pure migration — the only file you need to create is the migration itself, and the `down` block is just as important as the `up` block.

<details>
<summary>I've been stuck for 20+ minutes — show me Tier 2</summary>

Rails migrations use `add_index` in the `up` (or `change`) block and `remove_index` in the `down` block. A composite index is created by passing an array: `add_index :posts, [:author_id, :status]`. For the `down` block, `remove_index :posts, column: [:author_id, :status]` mirrors the composite, and `remove_index :posts, :status` mirrors the standalone. The reason to use a `change` method here instead of separate `up`/`down` is that `add_index` is reversible — Rails knows how to invert it automatically. So you can use `def change` and just call `add_index` twice, and `rails db:rollback` will invoke the inverse automatically.

</details>

<details>
<summary>I've been stuck for 45+ minutes — show me Tier 3 (full walkthrough)</summary>

1. Run `rails generate migration AddIndexesToPosts`. Open the generated file — it will have an empty `def change` method.
2. Inside `change`, add two lines:
   ```
   add_index :posts, :status
   add_index :posts, [:author_id, :status]
   ```
3. Save the file and run `rails db:migrate`. Check `db/schema.rb` — you should see both new index lines under the posts table.
4. Test rollback: run `rails db:rollback`. Open `schema.rb` again and confirm the two index lines are gone. The table columns should be unchanged.
5. Run `rails db:migrate` again to restore the indexes before pushing.
6. Open a `rails dbconsole` (psql) and run `\d posts` to confirm both indexes appear in the index list.

</details>

---

## Issue 9: N+1 query on posts index (tags not eager-loaded)

**Labels:** `bug`, `level:3`

**Context:**
The posts index view renders each post's tags. The current controller fetches posts with `Post.all` (or the Pundit-scoped equivalent), then the view calls `post.tags` for each record in the loop — one query per post. With 25 posts this fires 26 queries where 2 would suffice.

**Steps to reproduce:**
1. Enable query logging (`config.log_level = :debug` in development.rb or use Bullet gem)
2. Sign in as editor@cairn.test
3. Navigate to `/posts`
4. Count the SELECT queries in the Rails log — there will be one per post for the tags association

**Expected behavior:** Tags are loaded in a single query using eager loading. Total query count for the posts index is ≤ 3 (posts, tags via join, categories).

**Actual behavior:** Rails fires N+1 queries — one `SELECT tags.*` per post record.

**Files likely involved:**
- `app/controllers/posts_controller.rb`
- `app/views/posts/index.html.erb` (verify no other lazy associations called here)

**Note:** Fix the eager loading first. Then consider whether the same problem exists for `cover_image` attachments — it likely does.

---

**Tier 1 — Nudge:** The fix is a single word added to the controller query — look up `includes` in the ActiveRecord querying guide and apply it to the associations rendered in the view.

<details>
<summary>I've been stuck for 20+ minutes — show me Tier 2</summary>

An N+1 occurs when a loop in the view calls an association that was not loaded with the parent records. Rails' solution is `includes(:association_name)`, which loads all associated records in a second query and maps them in memory — eliminating the per-record queries. Open `app/controllers/posts_controller.rb` and find where `@posts` is assigned. Change `Post.all` (or the policy scope) to `Post.includes(:tags)`. If the view also calls `post.category`, add that too: `Post.includes(:tags, :category)`. For ActiveStorage attachments (`cover_image`), eager loading works differently — use `with_attached_cover_image` scope (a method ActiveStorage generates) or `includes(cover_image_attachment: :blob)`.

</details>

<details>
<summary>I've been stuck for 45+ minutes — show me Tier 3 (full walkthrough)</summary>

1. Enable query logging by temporarily setting `config.log_level = :debug` in `config/environments/development.rb`, or run `tail -f log/development.log` in a terminal while you navigate.
2. Visit `/posts` and count the repeated `SELECT "tags".*` queries in the log — note the count.
3. Open `app/controllers/posts_controller.rb`. Find the index action's `@posts` assignment.
4. Add `.includes(:tags)` to the query chain. If the view renders categories, add `:category` as well: `.includes(:tags, :category)`.
5. Reload `/posts` and recount the queries in the log. You should see one SELECT for posts and one for tags (a `WHERE taggings.post_id IN (...)` style query) instead of N individual tag queries.
6. Open `app/views/posts/index.html.erb` and scan every association call inside the loop. Add any missing associations to the `includes` call.
7. If `cover_image` is rendered, add `with_attached_cover_image` to the scope chain (call it as a scope method on the relation) to eager-load the attachment and blob in one join.

</details>

---

## Issue 10: Admin can impersonate any user

**Labels:** `feature`, `level:4`

**Context:**
Admins need to reproduce issues reported by authors and editors without sharing passwords. Impersonation lets an admin "become" another user for a session, then return to their admin account. This is a significant security surface — the implementation must be carefully scoped to admin-only and must log the impersonation event.

**Acceptance criteria:**
- [ ] Admin can click "Impersonate" on a user's profile and be signed in as that user
- [ ] A persistent banner is shown during impersonation: "Impersonating [name]. [Stop impersonating]"
- [ ] Clicking "Stop impersonating" restores the admin session
- [ ] Impersonation is only available to admins (Pundit-gated)
- [ ] Impersonation is not nestable — an impersonated user cannot impersonate another
- [ ] The impersonation event is logged to `Rails.logger` (at minimum) with admin ID and target user ID
- [ ] All Pundit policies evaluate against the impersonated user's role during the session

**Files likely involved:**
- `app/controllers/impersonations_controller.rb` (new)
- `app/policies/impersonation_policy.rb` (new)
- `app/views/layouts/application.html.erb` (impersonation banner)
- `config/routes.rb`
- `app/controllers/application_controller.rb` (current_user override)

**Note:** Research how `Devise#sign_in` interacts with session storage before writing any code. Storing the original admin ID in the session is the conventional approach.

---

**Tier 1 — Nudge:** The session is the right place to store the impersonated user's ID — think about what `current_user` needs to return during impersonation versus after stopping it.

<details>
<summary>I've been stuck for 20+ minutes — show me Tier 2</summary>

The core pattern for impersonation without a gem is: (1) store the original admin's ID in `session[:impersonator_id]`, (2) override `current_user` in `ApplicationController` to return `User.find(session[:impersonated_user_id])` when that key is present, and (3) clear both session keys when stopping. The Pundit policies will naturally evaluate against whatever `current_user` returns — so if `current_user` returns the impersonated user, all policies just work. The banner in the layout needs to check for `session[:impersonator_id].present?` and render the "Stop impersonating" link only then. The nesting guard is simple: if `session[:impersonator_id]` is already set when an admin tries to impersonate again, reject the request.

</details>

<details>
<summary>I've been stuck for 45+ minutes — show me Tier 3 (full walkthrough)</summary>

1. Add routes: `resources :impersonations, only: [:create, :destroy]` in `config/routes.rb`.
2. Create `app/policies/impersonation_policy.rb`. Define `create?` to return `user.admin?` and `destroy?` to return `session[:impersonator_id].present?` (you will need to pass session into the policy or handle this in the controller).
3. Create `app/controllers/impersonations_controller.rb`. The `create` action should: authorize the action, set `session[:impersonated_user_id] = params[:user_id]` and `session[:impersonator_id] = current_user.id`, log the event with `Rails.logger.info`, then redirect.
4. The `destroy` action should: clear `session[:impersonated_user_id]`, restore the admin by loading `User.find(session[:impersonator_id])`, clear `session[:impersonator_id]`, then redirect.
5. Override `current_user` in `ApplicationController`: define a private method that returns `User.find(session[:impersonated_user_id])` when `session[:impersonated_user_id]` is present, falling back to the default Devise `current_user`.
6. In `app/views/layouts/application.html.erb`, add a banner block: `<% if session[:impersonator_id].present? %>` ... render the warning message and a `button_to` pointing to `impersonation_path(method: :delete)` ... `<% end %>`.
7. Add an "Impersonate" link on the user show/profile page, visible only when `current_user.admin?` and not already impersonating.

</details>

---

## Issue 11: Add `discarded_at` index to posts table

**Labels:** `migration`, `level:1`

**Context:**
The `discarded_at` column was added in the soft-delete migration but no index was created on it. Every query that filters `WHERE discarded_at IS NULL` (which is every query via the default scope) performs a full table scan. Add the index.

**Schema change:**
```ruby
add_index :posts, :discarded_at
```

**Rollback note:** Include `remove_index :posts, :discarded_at` in the `down` block.

**Files likely involved:**
- `db/migrate/YYYYMMDDHHMMSS_add_index_on_posts_discarded_at.rb` (new)

**Hint:** Run `\d posts` in psql after migrating to confirm the index appears.

---

**Tier 1 — Nudge:** This is a single-migration ticket — the entire change is one `add_index` line inside a new migration file.

<details>
<summary>I've been stuck for 20+ minutes — show me Tier 2</summary>

Because `add_index` is a reversible operation in Rails, you can use `def change` instead of separate `up` and `down` blocks — Rails will automatically generate the inverse `remove_index` when you run `db:rollback`. Generate the migration with `rails generate migration AddIndexOnPostsDiscardedAt` and add a single `add_index :posts, :discarded_at` call inside the `change` method. After migrating, the key thing to verify is that the index actually appears in `schema.rb` — look for a line like `add_index "posts", ["discarded_at"]` in the posts table section.

</details>

<details>
<summary>I've been stuck for 45+ minutes — show me Tier 3 (full walkthrough)</summary>

1. Run `rails generate migration AddIndexOnPostsDiscardedAt`. Open the generated file.
2. Inside the `def change` method, add: `add_index :posts, :discarded_at`.
3. Save and run `rails db:migrate`.
4. Open `db/schema.rb` and search for `discarded_at` — you should see `add_index "posts", ["discarded_at"], name: "index_posts_on_discarded_at"` in the file.
5. Test rollback: `rails db:rollback`. Reopen `schema.rb` and confirm the index line is gone.
6. Run `rails db:migrate` to restore it.
7. Optional verification: open `rails dbconsole` and run `\d posts` — the index should appear in the "Indexes" section at the bottom of the table description.

</details>

---

## Issue 12: Refactor Post status transitions to use a state machine concern

**Labels:** `refactor`, `level:4`

**Context:**
The Post model currently has four transition methods (`submit_for_review!`, `publish!`, `reject!`, `archive!`) written as standalone instance methods with guard clauses. The logic is correct but brittle: each method manually checks the current status before transitioning, and there is no central map of valid transitions. Adding a fifth state (e.g., `scheduled`) requires touching four places.

**What to change:**
- Extract transition logic into a `Transitionable` concern in `app/models/concerns/`
- Define a `TRANSITIONS` constant mapping `{ from_state => [valid_to_states] }`
- Replace individual guard clauses with a single `valid_transition?(from, to)` check
- Keep all four public method names identical — callers must not change
- The concern should raise `Post::InvalidTransition` (custom error class) on invalid transitions, not `ActiveRecord::RecordInvalid`

**What must NOT change:**
- Public API of Post: `submit_for_review!`, `publish!`, `reject!`, `archive!`
- Error type raised (must still be catchable by the controller rescue block)
- Any existing passing tests

**Verification:** All transition-related request specs must pass without modification after the refactor.

**Files likely involved:**
- `app/models/concerns/transitionable.rb` (new)
- `app/models/post.rb`
- `spec/models/post_spec.rb`

---

**Tier 1 — Nudge:** Map out the valid transitions on paper first — a hash like `{ "draft" => ["in_review"], "in_review" => ["published", "draft"] }` is exactly the data structure the concern will use.

<details>
<summary>I've been stuck for 20+ minutes — show me Tier 2</summary>

Rails concerns are modules that are `include`d into models. Create `app/models/concerns/transitionable.rb` as a standard `ActiveSupport::Concern`. Define the `TRANSITIONS` hash as a constant inside the concern, mapping each from-state to an array of valid to-states. The `valid_transition?` method simply checks `TRANSITIONS[from]&.include?(to)`. Each of the four public methods in `post.rb` then calls `valid_transition?(status, "target_state") || raise(InvalidTransition, "...")` before updating the status. Define `Post::InvalidTransition` as a custom error class (a simple `class InvalidTransition < StandardError; end` inside the Post class body) so the controller's existing `rescue` clause can catch it by name.

</details>

<details>
<summary>I've been stuck for 45+ minutes — show me Tier 3 (full walkthrough)</summary>

1. Open `app/models/post.rb` and read all four transition methods. Note every valid from→to pair — write them down.
2. Create `app/models/concerns/transitionable.rb` with `module Transitionable` / `extend ActiveSupport::Concern`. Inside the module, define `TRANSITIONS` as the hash you wrote down, and define a `valid_transition?(from, to)` instance method.
3. Inside the `Post` class body (in `post.rb`), define `class InvalidTransition < StandardError; end` and add `include Transitionable` near the top.
4. Rewrite each transition method to use the shared pattern: call `raise InvalidTransition, "Cannot transition from #{status} to target_state"` unless `valid_transition?(status, "target_state")`, then update `self.status` and save.
5. Delete the old individual guard clause logic from each method — it is now replaced by `valid_transition?`.
6. Run `bundle exec rspec spec/models/post_spec.rb` — all existing tests must pass without modification.
7. If any test fails, the most likely cause is a mismatch between the old error type and the new `InvalidTransition` error. Check the controller's rescue clause to confirm it rescues `Post::InvalidTransition`.

</details>

---

## Issue 13: Improve seed data with edge-case users and posts

**Labels:** `chore`, `level:2`

**Context:**
Current seeds produce a clean, happy-path dataset. Real bugs surface on edge cases: authors with no posts, posts with no tags, posts stuck in `in_review` for a long time, discarded posts that were previously published. The seed data should be expanded to surface these conditions.

**Acceptance criteria:**
- [ ] At least one author user exists with zero posts (to test empty-state views)
- [ ] At least three posts exist with no tags (to test tag display gracefully handles nil/empty)
- [ ] At least two posts exist in `in_review` state, created more than 7 days ago (stale reviews)
- [ ] At least one post exists that was published, then discarded (published_at set, discarded_at set)
- [ ] At least one category exists with no posts assigned (to test empty category filter)
- [ ] Seeds are idempotent — running `rails db:seed` twice does not duplicate records
- [ ] `rails db:seed` completes in under 10 seconds

**Files likely involved:**
- `db/seeds.rb`

---

**Tier 1 — Nudge:** Idempotency is the tricky part here — use `find_or_create_by` (or a unique identifier lookup before creating) so running seeds twice does not double the records.

<details>
<summary>I've been stuck for 20+ minutes — show me Tier 2</summary>

Rails seed files are plain Ruby — they run top to bottom and have full access to ActiveRecord. The idempotency requirement means each record should be looked up by a unique attribute before creating: `User.find_or_create_by(email: "no-posts@cairn.test") { |u| u.role = "author"; u.password = "password" }`. For the stale `in_review` posts, you will need to set `created_at` explicitly — ActiveRecord allows this in seeds: `post.created_at = 10.days.ago; post.save!`. For the discarded-but-previously-published post, set both `published_at: 2.weeks.ago` and `discarded_at: 1.day.ago` on the same record.

</details>

<details>
<summary>I've been stuck for 45+ minutes — show me Tier 3 (full walkthrough)</summary>

1. Open `db/seeds.rb` and read the existing structure. Note how users and posts are currently created.
2. Add a user with no posts: `User.find_or_create_by(email: "empty-author@cairn.test") { |u| u.assign_attributes(role: "author", password: "password123", name: "Empty Author") }`.
3. Find or create three posts without any tags. After creating each post, ensure no tags are associated — either skip the tag assignment step or explicitly clear `post.tags = []`.
4. Find or create two `in_review` posts with old timestamps. After `post.save`, run `post.update_columns(created_at: 10.days.ago)` — `update_columns` bypasses validations and callbacks, which is useful in seeds.
5. Find or create one post and set `post.update_columns(status: "discarded", published_at: 2.weeks.ago, discarded_at: 1.day.ago)`.
6. Find or create one category with no posts: `Category.find_or_create_by(name: "Uncategorized")` and do not assign any posts to it.
7. Run `rails db:seed` twice and confirm the user/post counts remain the same on the second run.

</details>

---

## Issue 14: Run Annotate on all models and commit schema comments

**Labels:** `chore`, `level:1`

**Context:**
The Annotate gem is installed but has not been run since the final migrations were added. Model files are missing schema comment headers, making it harder to understand column types without opening `schema.rb`. Run Annotate and commit the result.

**Acceptance criteria:**
- [ ] All model files in `app/models/` have an up-to-date schema comment block at the top
- [ ] `schema.rb` is current (run `rails db:schema:dump` first if needed)
- [ ] No model file shows columns that no longer exist
- [ ] Commit message explains what was run and why (not just "run annotate")

**Files likely involved:**
- All files in `app/models/`
- `db/schema.rb`

**Hint:** `bundle exec annotate --models` writes the schema comments. Check `annotate --help` for options if the default placement (top vs bottom) conflicts with existing comments.

---

**Tier 1 — Nudge:** Make sure `schema.rb` is fully up to date before running Annotate — stale schema comments are worse than none.

<details>
<summary>I've been stuck for 20+ minutes — show me Tier 2</summary>

Annotate reads `db/schema.rb` and prepends (or appends) a comment block to each model file listing the table's columns and their types. The key setup step is ensuring `schema.rb` reflects the current database state — run `rails db:schema:dump` if you are unsure. Then `bundle exec annotate --models` processes every model. If some models already have comment blocks in the wrong position (top vs bottom), use the `--position` flag. After running it, check `git diff` to see which models changed — this is the content of your commit. Make sure no model shows a column that no longer exists (that would mean `schema.rb` is out of date).

</details>

<details>
<summary>I've been stuck for 45+ minutes — show me Tier 3 (full walkthrough)</summary>

1. Run `rails db:schema:dump` to regenerate `db/schema.rb` from the live database. Open it and verify all expected tables and columns are present.
2. Run `bundle exec annotate --models`. Watch the output — it will print each model file it modified.
3. Open one or two model files and read the generated comment block at the top. Confirm column names, types, and nullability match what you see in `schema.rb`.
4. Run `git diff --stat` to see which files changed. Every model file should show up. If a file did not change, annotate may have already had an up-to-date comment — check manually.
5. If any model shows a column that does not exist in `schema.rb`, you have a stale annotation — re-run `rails db:schema:dump` and then `bundle exec annotate --models --force` to overwrite.
6. Stage all the model files and `db/schema.rb` and commit with a message explaining that schema annotations were regenerated to reflect the latest migrations.

</details>

---

## Issue 15: Posts index renders error when current user has been soft-deleted

**Labels:** `bug`, `level:3`

**Context:**
Admins can soft-delete posts, but the User model has no soft-delete protection. If an admin were to delete a user account (via `User.destroy`) while that user is still signed in via a valid Devise session, the next request will call `current_user` which returns the destroyed record — causing `PostPolicy` to call `user.role` on a record that may have been loaded from a stale session. More concretely: if a User record is hard-deleted after sign-in, Devise raises `ActiveRecord::RecordNotFound` on the next authenticated request, which renders as a 500 error instead of redirecting to sign-in.

**Steps to reproduce:**
1. Sign in as author@cairn.test in one browser tab
2. In a rails console, run `User.find_by(email: 'author@cairn.test').destroy`
3. Return to the browser tab and navigate to `/posts`
4. Observe a 500 error instead of a redirect to sign-in

**Expected behavior:** Devise detects the session is invalid (user no longer exists) and redirects to `/users/sign_in` with a "Your session has expired" flash.

**Actual behavior:** Rails raises `ActiveRecord::RecordNotFound` or `NoMethodError` and renders a 500.

**Files likely involved:**
- `app/controllers/application_controller.rb`
- `config/initializers/devise.rb` (potentially)
- `app/models/user.rb`

**Note:** Look into `Devise::Models::Authenticatable` and how Devise handles a nil `current_user` vs a destroyed record. A `before_action` in ApplicationController may be the right place to handle this gracefully.

---

**Tier 1 — Nudge:** A `before_action` in `ApplicationController` that rescues `ActiveRecord::RecordNotFound` and signs the user out is the right starting point — look at how Devise's `authenticate_user!` is structured.

<details>
<summary>I've been stuck for 20+ minutes — show me Tier 2</summary>

When Devise's `current_user` is called and the session contains a user ID for a record that no longer exists, Devise does not automatically rescue the `RecordNotFound` — it bubbles up as a 500. The fix is to override `current_user` in `ApplicationController` to rescue this case, sign the user out, and redirect. Another approach is to use a `before_action` that validates the session: call `current_user` inside a rescue block, and if it raises `ActiveRecord::RecordNotFound`, call `sign_out` and redirect to `new_user_session_path` with a flash message. The flash key for Devise session errors is typically `:alert`. Make sure this before_action runs before `authenticate_user!` or wraps it.

</details>

<details>
<summary>I've been stuck for 45+ minutes — show me Tier 3 (full walkthrough)</summary>

1. Open `app/controllers/application_controller.rb` and find where `before_action :authenticate_user!` is called.
2. Add a new `before_action :handle_destroyed_session` above it (so it runs first).
3. Define the private method `handle_destroyed_session`. Inside it, attempt to call `current_user` in a begin/rescue block. Rescue `ActiveRecord::RecordNotFound`. In the rescue block: call `sign_out`, set `flash[:alert] = "Your session has expired. Please sign in again."`, and redirect to `new_user_session_path` with a `return` to halt the filter chain.
4. Reproduce the bug: sign in, destroy the user in console, navigate to `/posts`. You should now see a redirect to sign-in with the flash message instead of a 500.
5. As an alternative approach, look at `config/initializers/devise.rb` for `config.sign_out_via`. Also consider overriding `current_user` directly in `ApplicationController`: `def current_user; super rescue ActiveRecord::RecordNotFound; nil; end` — then `authenticate_user!` will see `nil` and redirect naturally. Both approaches work; choose the one that feels cleaner.
6. Write a test: sign in, destroy the record, make a GET to `/posts`, assert the response redirects to the sign-in path.

</details>

---

## Issue 16: Mobile navigation breaks at narrow viewports

**Labels:** `ui`, `level:2`

**Context:**
The main nav renders as a horizontal flex row. At 375px (iPhone SE) the nav items overflow and cause horizontal scroll. Implement a hamburger menu using a Stimulus controller that toggles a mobile nav drawer. No JS libraries — vanilla Stimulus only.

**Acceptance criteria:**
- [ ] Nav collapses below `sm:` breakpoint (640px)
- [ ] Hamburger icon (3-line or X icon) toggles the drawer open/closed
- [ ] Drawer closes when clicking outside of it
- [ ] No horizontal scroll at 375px
- [ ] Keyboard accessible: pressing Escape closes the open drawer
- [ ] Full nav renders normally at `sm:` and above (hamburger hidden)

**Files likely involved:**
- `app/views/layouts/application.html.erb`
- `app/javascript/controllers/nav_controller.js` (new)

---

**Tier 1 — Nudge:** The Tailwind classes `hidden` and `sm:flex` on the nav element are how you control what is visible at each breakpoint — the Stimulus controller's only job is to toggle a class on the drawer.

<details>
<summary>I've been stuck for 20+ minutes — show me Tier 2</summary>

This ticket combines two concepts: responsive Tailwind visibility and a Stimulus controller for toggle behavior. The layout has two nav states: a hamburger button (visible only below `sm:`, so `sm:hidden`) and a mobile drawer (hidden by default, shown when open). The Stimulus controller manages an `open` state and toggles a CSS class — something like `hidden` — on the drawer element. Wire the controller with `data-controller="nav"`, the toggle button with `data-action="click->nav#toggle"`, and the drawer with `data-nav-target="drawer"`. For "click outside to close," add a `data-action="click@window->nav#closeIfOutside"` handler that checks whether the click target is inside the nav element. For Escape, `data-action="keydown.esc@window->nav#close"` in Stimulus handles this natively.

</details>

<details>
<summary>I've been stuck for 45+ minutes — show me Tier 3 (full walkthrough)</summary>

1. Open `app/views/layouts/application.html.erb` and find the `<nav>` element. Add `data-controller="nav"` to it.
2. Inside the nav, add a hamburger button that is only visible below the `sm:` breakpoint: `<button class="sm:hidden" data-action="click->nav#toggle" aria-label="Toggle menu">` with a simple SVG hamburger icon (three horizontal lines).
3. Wrap the existing nav links in a drawer div: `<div class="hidden sm:flex sm:items-center sm:gap-4" data-nav-target="drawer">`. The `hidden` class hides it on mobile by default; `sm:flex` restores it at `sm:` and above.
4. Create `app/javascript/controllers/nav_controller.js`. Register it in `app/javascript/controllers/index.js`. Define `static targets = ["drawer"]` and two actions: `toggle()` — calls `this.drawerTarget.classList.toggle("hidden")` — and `close()` — adds `hidden` back.
5. Add a window-level click handler `closeIfOutside(event)` that checks `!this.element.contains(event.target)` and calls `this.close()` if true. Wire it with `data-action="click@window->nav#closeIfOutside"` on the nav element.
6. Add `data-action="keydown.esc@window->nav#close"` to the nav element for Escape key support.
7. Test at 375px in browser DevTools. Open the drawer, click outside it, press Escape — each should close it.

</details>

---

## Issue 17: Status badge colors fail WCAG AA contrast

**Labels:** `ui`, `level:1`

**Context:**
The current status badges use light background + light text (e.g. `bg-yellow-200 text-yellow-400` for draft). This fails WCAG AA contrast ratio (4.5:1 required for normal text). Update all four status badge color combinations to pass AA. Do not change the badge shape or size — only the color classes.

**Acceptance criteria:**
- [ ] All four statuses (draft, in_review, published, archived) pass 4.5:1 contrast ratio
- [ ] Contrast verified using webaim.org/resources/contrastchecker or browser DevTools accessibility panel
- [ ] Visual appearance still clearly distinguishes the four states (do not use the same color for two statuses)
- [ ] Badge shape, padding, and font size are unchanged

**Files likely involved:**
- `app/views/shared/_status_badge.html.erb` (created in Issue 6 — complete that first)

---

**Tier 1 — Nudge:** Swap to a dark text color on each badge — `text-yellow-800` on `bg-yellow-100` is a starting point, but verify the ratio with a contrast checker before committing.

<details>
<summary>I've been stuck for 20+ minutes — show me Tier 2</summary>

WCAG AA requires a 4.5:1 contrast ratio between text and background for normal text. The Tailwind color scale runs from 50 (lightest) to 900 (darkest). The failing pattern is using a 200-level background with a 400-level text — both are light, so contrast is low. The fix is to pair a light background (100 or 200) with a dark text (700, 800, or 900) — or a dark background (700, 800) with white or light text. For each of the four badges, pick a combination that: (a) passes 4.5:1, (b) looks distinct from the other three, and (c) communicates the right sentiment (green for published, red or gray for archived, etc.). Use the WebAIM Contrast Checker — paste the hex values from Tailwind's color palette docs.

</details>

<details>
<summary>I've been stuck for 45+ minutes — show me Tier 3 (full walkthrough)</summary>

1. Open `app/views/shared/_status_badge.html.erb` and read the current CSS classes for each status.
2. Look up the Tailwind CSS color palette (tailwindcss.com/docs/customizing-colors) and note the hex values for the colors currently in use. Paste them into webaim.org/resources/contrastchecker to confirm they fail.
3. For each status, choose a new pairing. Suggested starting point (verify each with the checker):
   - `draft`: `bg-yellow-100 text-yellow-800`
   - `in_review`: `bg-blue-100 text-blue-800`
   - `published`: `bg-green-100 text-green-800`
   - `archived`: `bg-gray-100 text-gray-700`
4. For each pairing, go to the WebAIM checker, enter the Tailwind hex for the background and text, and confirm the "Normal Text" row shows a pass (ratio ≥ 4.5:1). Adjust one shade darker/lighter until all four pass.
5. Update the CSS classes in `_status_badge.html.erb` for each status.
6. Load the posts index and visually verify all four badges are clearly distinguishable from each other.

</details>

---

## Issue 18: Post form lacks loading feedback on submit

**Labels:** `ui`, `level:2`

**Context:**
When a user submits a post with a large ActionText body or image attachment, the form goes quiet for several seconds — no feedback that anything is happening. Add a Stimulus controller that disables the submit button and shows a "Saving..." label on form submit to prevent double-submits and reduce user anxiety.

**Acceptance criteria:**
- [ ] Submit button text changes to "Saving..." immediately on click
- [ ] Button is disabled during submission (prevents double-submit)
- [ ] Behavior activates only on form submit event, not on other button clicks in the form
- [ ] Works correctly with Turbo form submissions (does not lock the button permanently on success)
- [ ] Button returns to original state if the form submission fails validation (Turbo re-renders the form)

**Files likely involved:**
- `app/views/posts/_form.html.erb`
- `app/javascript/controllers/form_submit_controller.js` (new)

---

**Tier 1 — Nudge:** The Stimulus controller should listen for the `submit` event on the form element, not a `click` event on the button — this keeps it decoupled from the button's exact position in the form.

<details>
<summary>I've been stuck for 20+ minutes — show me Tier 2</summary>

The core pattern is a Stimulus controller attached to the `<form>` element that: (1) listens for the `submit` event, (2) finds the submit button, (3) disables it and changes its text. Wire the controller with `data-controller="form-submit"` on the form tag and `data-action="submit->form-submit#loading"` on the same element. Inside the `loading()` action, query for `this.element.querySelector('[type="submit"]')` to find the button, then set `button.disabled = true` and `button.value = "Saving..."` (or `button.textContent` for `<button>` elements). The Turbo integration challenge: when Turbo re-renders the form after a validation failure, the Stimulus controller is reconnected and the button is reset — so no extra cleanup is needed if you do it correctly.

</details>

<details>
<summary>I've been stuck for 45+ minutes — show me Tier 3 (full walkthrough)</summary>

1. Create `app/javascript/controllers/form_submit_controller.js`. Define `static targets = ["submit"]` and an action `loading(event)`.
2. Inside `loading()`, find the submit button via `this.submitTarget`. Set `this.submitTarget.disabled = true`. Store the original text: `this.submitTarget.dataset.originalText = this.submitTarget.textContent`. Then set `this.submitTarget.textContent = "Saving..."` (adjust for `value` vs `textContent` depending on whether it is an `<input type="submit">` or a `<button>`).
3. Register the controller in `app/javascript/controllers/index.js`.
4. Open `app/views/posts/_form.html.erb`. Add `data-controller="form-submit"` to the opening `<form>` tag (or the `form_with` options: `data: { controller: "form-submit" }`).
5. Add `data-action="submit->form-submit#loading"` to the form tag as well.
6. Add `data-form-submit-target="submit"` to the submit button element.
7. Test: submit a valid form and observe the button changes. Submit an invalid form — after Turbo re-renders, the button should be back to its original state because the DOM was replaced.

</details>

---

## Issue 19: Admin dashboard has no empty state for new installs

**Labels:** `ui`, `level:1`

**Context:**
The admin dashboard renders a table of recent posts. On a fresh install (before seeds are run, or in a test environment), the table is empty but renders no empty state — just an empty `<tbody>`. Add a friendly empty state message inside the table when there are no posts.

**Acceptance criteria:**
- [ ] Empty state message renders when post count is 0
- [ ] Empty state disappears once posts exist (no flash of empty state when posts are present)
- [ ] No Turbo or JS required — pure ERB conditional
- [ ] Message is helpful: "No posts yet. Authors can create posts from the Posts section."
- [ ] Empty state spans all table columns so it does not break table layout

**Files likely involved:**
- `app/views/admin/dashboard/show.html.erb`

---

**Tier 1 — Nudge:** An ERB `if`/`else` inside the `<tbody>` is all this requires — check what variable the view uses for the posts collection before writing the conditional.

<details>
<summary>I've been stuck for 20+ minutes — show me Tier 2</summary>

This is a pure view change. Open `app/views/admin/dashboard.html.erb` and find the `<tbody>` element. The view has a collection variable (likely `@posts` or `@recent_posts`) — check the top of the file or the controller to confirm its name. The pattern is: `<% if @posts.empty? %>` render one `<tr>` with a `<td colspan="N">` (where N matches the number of `<th>` columns in the table header), containing the empty state message. `<% else %>` render the existing post rows. `<% end %>`. Using `colspan` on the single `<td>` ensures it spans all columns and does not create a misaligned layout.

</details>

<details>
<summary>I've been stuck for 45+ minutes — show me Tier 3 (full walkthrough)</summary>

1. Open `app/views/admin/dashboard.html.erb`. Count the `<th>` elements in the table header row — note that number (call it N).
2. Find the `<tbody>` block. Identify the collection variable used in the loop (e.g. `@posts`).
3. Replace the contents of `<tbody>` with:
   ```
   <% if @posts.empty? %>
     <tr>
       <td colspan="N" class="px-4 py-8 text-center text-gray-500">
         No posts yet. Authors can create posts from the Posts section.
       </td>
     </tr>
   <% else %>
     <% @posts.each do |post| %>
       ... existing row code ...
     <% end %>
   <% end %>
   ```
4. Set `colspan` to the exact number of columns in the header.
5. Test with posts present: the table should render normally. Test without posts (either in a test environment or by temporarily commenting out the seed call) and confirm the empty state message appears.

</details>

---

## Issue 20: Post index table is unreadable on tablet (md breakpoint)

**Labels:** `ui`, `level:3`

**Context:**
The posts index table shows 6 columns: Title, Author, Category, Tags, Status, Actions. On `md:` screens (768px–1023px) all 6 columns are visible but cramped — text truncates in unintended ways and the Actions column buttons stack vertically. Redesign the table to hide the Tags and Category columns below `lg:` breakpoint, and show them in an expandable row detail instead (using a Stimulus controller for the expand toggle).

**Acceptance criteria:**
- [ ] Tags and Category columns hidden below `lg:` breakpoint (1024px)
- [ ] A "Details" toggle button appears on each row at `md:` and below
- [ ] Clicking the toggle reveals a sub-row with category and tags for that post
- [ ] Toggle button is keyboard accessible (focusable, activates on Enter/Space)
- [ ] Clicking the toggle again hides the sub-row
- [ ] Full 6-column table renders correctly at `lg:` and above (no toggle visible)

**Files likely involved:**
- `app/views/posts/index.html.erb`
- `app/javascript/controllers/row_expand_controller.js` (new)

---

**Tier 1 — Nudge:** Tailwind's `lg:hidden` and `hidden lg:table-cell` classes are the right tools for showing and hiding columns at the breakpoint — get the column visibility working with just CSS before adding the Stimulus controller.

<details>
<summary>I've been stuck for 20+ minutes — show me Tier 2</summary>

This ticket has two distinct parts: responsive column visibility (CSS only) and the expandable row (Stimulus). For the CSS part: add `class="hidden lg:table-cell"` to both the `<th>` and each row's `<td>` for Category and Tags — this hides them below `lg:` while showing them at `lg:` and above. For the toggle button column: add a new `<th class="lg:hidden">` header and a `<td class="lg:hidden">` on each row containing a button. For the Stimulus part, the controller needs to be on each `<tr>` (or a wrapper), with the sub-row as a target. The sub-row is an additional `<tr>` that is `hidden` by default and contains a `<td colspan="4">` with the category and tag details. The controller's `toggle()` action switches `hidden` on the sub-row target.

</details>

<details>
<summary>I've been stuck for 45+ minutes — show me Tier 3 (full walkthrough)</summary>

1. Create `app/javascript/controllers/row_expand_controller.js`. Define `static targets = ["detail"]` and a `toggle()` method that calls `this.detailTarget.classList.toggle("hidden")`.
2. Register it in `app/javascript/controllers/index.js`.
3. Open `app/views/posts/index.html.erb`. In the `<thead>` row, add `class="hidden lg:table-cell"` to the Category and Tags `<th>` elements. Add a new `<th class="lg:hidden"></th>` as the last header (or second-to-last, before Actions).
4. In the `<tbody>` loop, for each post row: add `data-controller="row-expand"` to the `<tr>`. Add `class="hidden lg:table-cell"` to the Category `<td>` and Tags `<td>`. Add a new `<td class="lg:hidden">` containing `<button data-action="click->row-expand#toggle">Details</button>`.
5. After the main post `<tr>`, add a sibling `<tr class="hidden lg:hidden" data-row-expand-target="detail">`. Inside it, add `<td colspan="4" class="px-4 py-2 text-sm text-gray-600">Category: <%= post.category&.name %> | Tags: <%= post.tags.map(&:name).join(", ") %></td>`.
6. Make the Details button keyboard accessible: a `<button>` element is natively focusable and activates on Enter/Space — no extra work needed if you use `<button>` rather than a styled `<span>`.
7. Test at 768px–1023px in DevTools: Tags and Category columns should be hidden, Details button should appear, clicking it should reveal the sub-row.

</details>

---

## Issue 21: Deploy Cairn CMS to production on Fly.io

**Labels:** `feature`, `level:4`

**Context:**
The app is fully built. This is the graduation milestone — deploy it to production on Fly.io so it is accessible at a public URL. You will encounter real production problems: asset compilation, missing environment variables, an unmigrated database. Solving them is the point. When this ticket is done, you can share a working link.

**Acceptance criteria:**
- [ ] A `Dockerfile` exists and builds cleanly (`docker build .` succeeds locally)
- [ ] `fly.toml` is committed with the app name and region set
- [ ] Production Postgres cluster is provisioned and attached to the app
- [ ] All required secrets are set via `fly secrets set`: `SECRET_KEY_BASE`, `RAILS_MASTER_KEY`
- [ ] `rails db:migrate` has been run remotely — no pending migrations on production
- [ ] The sign-in page loads at the public Fly URL with no 500 errors
- [ ] Admin can sign in and reach the dashboard
- [ ] `.github/workflows/ci.yml` runs RSpec on every PR against a Postgres service container
- [ ] Deployed URL is recorded in README.md

**Files likely involved:**
- `Dockerfile` (new)
- `fly.toml` (new)
- `.github/workflows/ci.yml` (new)
- `config/environments/production.rb`
- `README.md`

**Note:** Install the Fly CLI before starting: `brew install flyctl` then `fly auth login`. You will need a Fly.io account (free tier covers this app).

---

**Tier 1 — Nudge:** Run `fly launch` from the project root first — it detects Rails and generates a Dockerfile and fly.toml skeleton. Read both files before pushing anything.

<details>
<summary>I've been stuck for 20+ minutes — show me Tier 2</summary>

Deployment has four independent failure modes, each with a distinct symptom:

1. **Build fails** — Dockerfile issue. Run `docker build .` locally to reproduce. The most common Rails 7 issue is missing `RAILS_MASTER_KEY` at build time — pass it as a build arg or defer asset precompilation to runtime.
2. **App crashes on start** — Missing env var or DB not connected. Check `fly logs` immediately after deploy. `DATABASE_URL` is set automatically when you attach a Fly Postgres cluster (`fly postgres attach`), but `SECRET_KEY_BASE` and `RAILS_MASTER_KEY` must be set manually via `fly secrets set SECRET_KEY_BASE=$(rails secret) RAILS_MASTER_KEY=$(cat config/master.key)`.
3. **500 on every page** — Pending migrations. Run `fly ssh console -C "bin/rails db:migrate"` to migrate production. Verify with `fly ssh console -C "bin/rails db:version"`.
4. **CI fails** — Postgres service container not configured. In `.github/workflows/ci.yml`, add a `services:` block with `postgres:15` and set `DATABASE_URL` as an env var pointing to `localhost:5432`.

Tackle these in order: build → start → migrations → CI.

</details>

<details>
<summary>I've been stuck for 45+ minutes — show me Tier 3 (full walkthrough)</summary>

**Step 1 — Fly CLI and launch**
1. Install and authenticate: `brew install flyctl && fly auth login`.
2. From the project root, run `fly launch`. Accept the detected Rails config. Choose a region close to you. Say **no** to provisioning Postgres now (you will do it separately). Say **no** to deploying now.
3. Inspect the generated `Dockerfile` and `fly.toml`. Commit both.

**Step 2 — Provision Postgres**
1. `fly postgres create --name cairn-cms-db` — create a Postgres 15 cluster. Note the connection string shown in the output.
2. `fly postgres attach cairn-cms-db` — this sets `DATABASE_URL` automatically in your app's secrets.

**Step 3 — Set remaining secrets**
```bash
fly secrets set SECRET_KEY_BASE=$(bundle exec rails secret)
fly secrets set RAILS_MASTER_KEY=$(cat config/master.key)
```

**Step 4 — Deploy**
1. `fly deploy` — this builds the Docker image and releases it. Watch the output for build errors.
2. If the build fails on asset precompilation, add `ENV RAILS_ENV=production` and `ENV SECRET_KEY_BASE=placeholder` to the Dockerfile before the `RUN bundle exec rails assets:precompile` line. The placeholder value is only used at build time for asset fingerprinting.

**Step 5 — Migrate and smoke test**
1. `fly ssh console -C "bin/rails db:migrate"` — run migrations on production.
2. `fly open` — opens the app in your browser. Sign in as admin@cairn.test / password (if you seeded) or create a user via console.
3. Check `fly logs` for any errors during the smoke test.

**Step 6 — GitHub Actions CI**
Create `.github/workflows/ci.yml`:
```yaml
name: CI
on: [pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    env:
      RAILS_ENV: test
      DATABASE_URL: postgres://postgres:postgres@localhost:5432/cairn_test
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true
      - run: bundle exec rails db:create db:schema:load
      - run: bundle exec rspec
```
Push a PR to confirm CI runs.

**Step 7 — Record the URL**
Add the Fly URL to `README.md` under a "Live Demo" heading. Commit it as your graduation entry.

</details>
