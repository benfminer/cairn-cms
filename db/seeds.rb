puts "Seeding users..."

users = [
  { email: "admin@cairn.test",  password: "password", role: :admin  },
  { email: "editor@cairn.test", password: "password", role: :editor },
  { email: "author@cairn.test", password: "password", role: :author }
].map do |attrs|
  user = User.find_or_initialize_by(email: attrs[:email])
  user.assign_attributes(
    password:              attrs[:password],
    password_confirmation: attrs[:password],
    role:                  attrs[:role]
  )
  user.save! if user.new_record? || user.changed?
  puts "  #{user.role}: #{user.email}"
  user
end

admin  = users.find(&:admin?)
editor = users.find(&:editor?)
author = users.find(&:author?)

puts "Seeding categories..."

categories = [
  "Tutorials",
  "Deep Dives",
  "Tips & Tricks",
  "Deployment"
].map do |name|
  cat = Category.find_or_create_by!(name: name)
  puts "  #{cat.name}"
  cat
end

puts "Seeding tags..."

tag_names = %w[rails ruby hotwire tailwind postgres pundit devops testing]
tags = tag_names.map do |name|
  tag = Tag.find_or_create_by!(name: name)
  puts "  #{tag.name}"
  tag
end

# Helper: find a post by title regardless of discard state
def find_post_anywhere(title)
  Post.unscoped.find_by(title: title)
end

# Helper: ensure a post ends up in the desired status.
# Creates as draft first, then transitions. Idempotent on re-runs.
def ensure_post(title:, author:, body:, target_status:, discard: false)
  post = Post.unscoped.find_or_initialize_by(title: title)

  if post.new_record?
    post.assign_attributes(author: author, status: :draft)
    post.body = body
    post.save!
  end

  # Advance to target status if not already there (or past it for discard cases)
  unless post.status.to_sym == target_status || post.discarded?
    case target_status
    when :in_review
      post.submit_for_review! if post.draft?
    when :published
      post.submit_for_review! if post.draft?
      post.publish!           if post.in_review?
    when :archived
      post.submit_for_review! if post.draft?
      post.publish!           if post.in_review?
      post.archive!           if post.published?
    end
  end

  if discard && !post.discarded?
    post.discard!
  end

  post
end

puts "Seeding posts..."

posts_data = [
  # ── 10 published ──────────────────────────────────────────────────────────
  {
    title: "Getting Started with Rails 7",
    target_status: :published,
    author: author,
    body: "<p>Rails 7 brings a fresh approach to JavaScript with Hotwire — Turbo and Stimulus replace the old asset pipeline complexity. In this post we walk through setting up a new Rails 7 app from scratch, connecting Postgres, and getting Tailwind rendering in under 10 minutes.</p><p>The <code>bin/dev</code> command is your new best friend. It runs the Rails server and the CSS watcher in parallel via Foreman, so you always have compiled styles without thinking about it.</p>"
  },
  {
    title: "Understanding Pundit Policies",
    target_status: :published,
    author: editor,
    body: "<p>Pundit is a minimal authorization library that puts policy logic in plain Ruby objects. Each policy class maps to a model and defines methods like <code>show?</code>, <code>update?</code>, and <code>destroy?</code> that return true or false based on the current user.</p><p>The key insight is that Pundit stays out of your way — there's no DSL to learn, just Ruby methods. That makes policies easy to test, easy to read, and easy to extend as your authorization rules grow.</p>"
  },
  {
    title: "ActionText and Trix: Rich Text in Rails",
    target_status: :published,
    author: author,
    body: "<p>ActionText is Rails' built-in rich text solution. It stores content in a separate <code>action_text_rich_texts</code> table and renders it through the Trix editor — a sensible, accessible WYSIWYG that ships with Rails.</p><p>The gotcha most developers hit first: always eager-load with <code>Post.with_rich_text_body</code> on index queries. Without it you get one query per post just to load the body — a classic N+1 that only shows up under real data volumes.</p>"
  },
  {
    title: "Postgres Enum Columns in Rails",
    target_status: :published,
    author: author,
    body: "<p>Rails integer enums are convenient but have a subtle footgun: the database stores integers, not strings. That means <code>Post.group(:status).count</code> returns <code>{ 0 => 5, 1 => 2 }</code> not <code>{ \"draft\" => 5, \"in_review\" => 2 }</code>. Always <code>transform_keys</code> when you need human-readable keys.</p>"
  },
  {
    title: "Hotwire Turbo Frames Explained",
    target_status: :published,
    author: author,
    body: "<p>Turbo Frames let you update a portion of a page without a full reload — no JavaScript required. Wrap any section in a <code>&lt;turbo-frame&gt;</code> tag with an id, and any link or form inside that frame will automatically scope its response to just that region.</p><p>The mental model shift: you're not writing JavaScript to update the DOM. You're writing server-rendered HTML that Turbo replaces in place. The result is SPA-like interactions with none of the client-side state complexity.</p>"
  },
  {
    title: "Writing Readable RSpec Tests",
    target_status: :published,
    author: author,
    body: "<p>RSpec tests that read like documentation are worth more than tests that just pass. Use descriptive <code>describe</code> and <code>context</code> blocks, keep each <code>it</code> block focused on one assertion, and name your FactoryBot factories to match the state they represent.</p><p>The three-part structure — arrange, act, assert — keeps tests understandable at a glance. If your arrange block is longer than five lines, you probably need a factory or a helper.</p>"
  },
  {
    title: "ActiveStorage in Practice",
    target_status: :published,
    author: editor,
    body: "<p>ActiveStorage is Rails' answer to file attachments. In development it stores files on local disk; in production you swap in a cloud adapter — S3, GCS, Azure — by changing a single line in <code>config/storage.yml</code>.</p><p>The most common mistake: forgetting <code>with_attached_cover_image</code> on index queries. Without it every rendered thumbnail fires a separate database lookup. Eager-load attachments the same way you eager-load associations.</p>"
  },
  {
    title: "Scoping Queries with Pundit",
    target_status: :published,
    author: editor,
    body: "<p>Pundit's <code>Scope</code> inner class is where you put the logic for 'what records can this user see?' rather than 'can this user act on this specific record?' The <code>policy_scope</code> helper in controllers calls <code>resolve</code> and returns a scoped relation.</p><p>Authors get their own posts. Editors and admins see everything. That one <code>case</code> statement in the scope class replaces a dozen ad-hoc <code>where</code> calls scattered across controllers.</p>"
  },
  {
    title: "Tailwind CSS Utility Classes: A Field Guide",
    target_status: :published,
    author: author,
    body: "<p>Tailwind's utility-first approach feels wrong for the first week and right for every week after. Instead of naming semantic CSS classes you compose utilities directly in HTML: <code>flex items-center gap-4 rounded-lg bg-white shadow-sm</code>.</p><p>The productivity gain shows up on a team: no more arguing over class names, no more stylesheet bloat from one-off rules, no more style collisions between components. Just utilities, composed.</p>"
  },
  {
    title: "Database Indexing Strategies for Rails Apps",
    target_status: :published,
    author: admin,
    body: "<p>Most Rails performance problems are index problems. The default Postgres sequential scan is fine at a few thousand rows and catastrophic at a million. Learn to read <code>EXPLAIN ANALYZE</code> output and you'll catch every missing index before it hits production.</p><p>Three rules: index every foreign key, index every column you filter or sort by in a query that runs on a hot path, and use composite indexes when you always filter on two columns together.</p>"
  },

  # ── 3 in_review ───────────────────────────────────────────────────────────
  {
    title: "Soft Deletes with Discard",
    target_status: :in_review,
    author: author,
    body: "<p>Hard-deleting records is almost always the wrong call in a production app. Users expect an undo, auditors expect a trail, and foreign key constraints get painful fast. Soft deletes solve all three problems by adding a <code>discarded_at</code> timestamp instead of removing the row.</p><p>The Discard gem adds <code>discard!</code> and <code>undiscard!</code> to your models and sets up a default scope that filters out discarded records automatically. Admin trash views use <code>Post.only_discarded</code> to see what's been removed.</p>"
  },
  {
    title: "Building a Publishing Workflow",
    target_status: :in_review,
    author: editor,
    body: "<p>A CMS without a publishing workflow is just a fancy text editor. Real editorial teams need a way to move content through stages — draft, review, published, archived — with clear rules about who can move it where.</p><p>In Cairn we model this as a state machine directly on the Post model. Each transition is an explicit method with a guard clause. <code>publish!</code> raises <code>InvalidTransition</code> if the post isn't in review first. No jumping states, no surprise status changes.</p>"
  },
  {
    title: "Using Pagy for Pagination",
    target_status: :in_review,
    author: author,
    body: "<p>Pagy is a fast, lightweight pagination gem that avoids the magic of older solutions. There is no patching of ActiveRecord — you pass a collection and get back a paginator object and a paginated array. Simple to reason about, easy to customize.</p><p>The killer feature is performance: Pagy benchmarks orders of magnitude faster than Kaminari or will_paginate at large page counts. For a CMS with hundreds of posts, that difference is real.</p>"
  },

  # ── 7 draft ───────────────────────────────────────────────────────────────
  {
    title: "Stimulus Controllers: A Practical Guide",
    target_status: :draft,
    author: editor,
    body: "<p>Stimulus is a lightweight JavaScript framework designed to work with server-rendered HTML. Instead of owning the DOM, Stimulus controllers connect to existing HTML via <code>data-controller</code> attributes and add behaviour on top.</p><p>A controller that toggles a menu is a few lines. A controller that handles form validation is still readable two months later. That's the point — just enough JavaScript, exactly where you need it.</p>"
  },
  {
    title: "Sidekiq and Background Jobs in Rails",
    target_status: :draft,
    author: author,
    body: "<p>Any operation that takes more than 100ms and doesn't need to block a response belongs in a background job. Sending email, resizing images, calling external APIs — all of these should be async. Sidekiq makes this straightforward with a Redis-backed queue and a clean job DSL.</p>"
  },
  {
    title: "Rails Credentials and Secret Management",
    target_status: :draft,
    author: author,
    body: "<p>Rails 5.2 introduced credentials as the replacement for the old <code>secrets.yml</code> pattern. The <code>config/credentials.yml.enc</code> file is encrypted with a master key that never gets committed. Only the encrypted file goes in version control; the key lives in the environment.</p>"
  },
  {
    title: "Writing Custom Validators in Rails",
    target_status: :draft,
    author: editor,
    body: "<p>When Rails' built-in validators don't cover your rules, write a custom validator. The pattern is a class that inherits from <code>ActiveModel::Validator</code> with a <code>validate</code> method. Keep validators small and focused — one rule per class.</p>"
  },
  {
    title: "N+1 Queries: Detection and Prevention",
    target_status: :draft,
    author: author,
    body: "<p>The N+1 query problem is the most common Rails performance issue and the easiest to avoid once you know what to look for. Every time you call an association inside a loop without eager loading, you fire a query per record. Bullet gem surfaces these in development before they reach production.</p>"
  },
  {
    title: "Caching Strategies in Rails",
    target_status: :draft,
    author: admin,
    body: "<p>Rails ships with a layered caching stack: fragment caching in views, low-level caching in models, HTTP caching at the edge. Each layer has a different granularity and a different invalidation story. Start with Russian Doll caching for views — it's the highest-impact change with the least complexity.</p>"
  },
  {
    title: "Multi-tenancy Patterns in Rails",
    target_status: :draft,
    author: editor,
    body: "<p>Multi-tenancy means one application instance serves many isolated customers. The two main approaches are row-level tenancy (a <code>tenant_id</code> column on every table) and schema-level tenancy (a separate Postgres schema per tenant). Row-level is simpler; schema-level gives stronger isolation.</p>"
  },

  # ── 5 discarded (published base state before discard) ─────────────────────
  {
    title: "Deploying Rails to Fly.io",
    target_status: :published,
    discard: true,
    author: admin,
    body: "<p>Fly.io has become the go-to Rails hosting platform for good reason: it runs containers close to your users, Postgres is first-class, and the CLI is genuinely pleasant. This post covers the full flow from <code>fly launch</code> to a live app with migrations running in production.</p><p>The one thing that trips everyone up: <code>SECRET_KEY_BASE</code>. Set it with <code>fly secrets set SECRET_KEY_BASE=$(rails secret)</code> before your first deploy or you'll get a cryptic 500 on the credentials endpoint.</p>"
  },
  {
    title: "Deprecated: ActionCable Basics",
    target_status: :published,
    discard: true,
    author: editor,
    body: "<p>ActionCable integrates WebSockets into Rails using the same conventions as the rest of the framework. Channels are the server-side abstraction; subscriptions are the client-side counterpart. This post has been superseded by a more up-to-date Hotwire guide.</p>"
  },
  {
    title: "Draft: Environment Setup Guide",
    target_status: :draft,
    discard: true,
    author: author,
    body: "<p>This draft was abandoned in favour of the updated Getting Started post. Left here for reference.</p>"
  },
  {
    title: "Old: Webpacker Configuration Tips",
    target_status: :published,
    discard: true,
    author: admin,
    body: "<p>Webpacker is no longer the recommended JavaScript bundler for Rails apps. This post is archived and has been soft-deleted to prevent it surfacing in search results.</p>"
  },
  {
    title: "Stale: Heroku Deployment Checklist",
    target_status: :published,
    discard: true,
    author: editor,
    body: "<p>This checklist was accurate for Rails 6 on Heroku but is now stale. The team has migrated to Fly.io. Kept in the trash for historical reference.</p>"
  }
]

created_posts = posts_data.map do |attrs|
  discard_after = attrs.delete(:discard) || false
  post = ensure_post(**attrs, discard: discard_after)
  label = post.discarded? ? "discarded" : post.status
  puts "  [#{label}] #{post.title}"
  post
end

puts "Assigning categories and tags to posts..."

assignments = {
  "Getting Started with Rails 7"           => { category: "Tutorials",    tags: %w[rails hotwire tailwind] },
  "Understanding Pundit Policies"          => { category: "Deep Dives",   tags: %w[rails pundit] },
  "ActionText and Trix: Rich Text in Rails" => { category: "Deep Dives",  tags: %w[rails] },
  "Soft Deletes with Discard"              => { category: "Tips & Tricks", tags: %w[rails postgres] },
  "Building a Publishing Workflow"         => { category: "Deep Dives",   tags: %w[rails] },
  "Postgres Enum Columns in Rails"         => { category: "Tips & Tricks", tags: %w[postgres rails] },
  "Hotwire Turbo Frames Explained"         => { category: "Deep Dives",   tags: %w[hotwire rails] },
  "Stimulus Controllers: A Practical Guide" => { category: "Tutorials",   tags: %w[hotwire] },
  "Deploying Rails to Fly.io"              => { category: "Deployment",   tags: %w[devops rails] },
  "Writing Readable RSpec Tests"           => { category: "Tips & Tricks", tags: %w[testing rails] },
  "ActiveStorage in Practice"              => { category: "Tutorials",    tags: %w[rails] },
  "Scoping Queries with Pundit"            => { category: "Deep Dives",   tags: %w[rails pundit] },
  "Tailwind CSS Utility Classes: A Field Guide" => { category: "Tutorials", tags: %w[tailwind] },
  "Database Indexing Strategies for Rails Apps" => { category: "Deep Dives", tags: %w[postgres rails] },
  "Using Pagy for Pagination"              => { category: "Tips & Tricks", tags: %w[rails] },
  "Sidekiq and Background Jobs in Rails"   => { category: "Deep Dives",   tags: %w[rails devops] },
  "Rails Credentials and Secret Management" => { category: "Tips & Tricks", tags: %w[rails devops] },
  "Writing Custom Validators in Rails"     => { category: "Tips & Tricks", tags: %w[rails ruby] },
  "N+1 Queries: Detection and Prevention"  => { category: "Deep Dives",   tags: %w[rails postgres] },
  "Caching Strategies in Rails"            => { category: "Tips & Tricks", tags: %w[rails] },
  "Multi-tenancy Patterns in Rails"        => { category: "Deep Dives",   tags: %w[rails postgres] },
  "Deprecated: ActionCable Basics"         => { category: "Deep Dives",   tags: %w[hotwire rails] },
  "Draft: Environment Setup Guide"         => { category: "Tutorials",    tags: %w[rails] },
  "Old: Webpacker Configuration Tips"      => { category: "Deployment",   tags: %w[rails devops] },
  "Stale: Heroku Deployment Checklist"     => { category: "Deployment",   tags: %w[devops rails] }
}

assignments.each do |title, attrs|
  post = Post.unscoped.find_by(title: title)
  next unless post
  cat = categories.find { |c| c.name == attrs[:category] }
  post.update_column(:category_id, cat.id)
  attrs[:tags].each do |tag_name|
    tag = tags.find { |t| t.name == tag_name }
    post.tags << tag unless post.tags.include?(tag)
  end
  puts "  #{title} → #{cat.name}"
end

puts ""
puts "Seed summary:"
puts "  Users:      #{User.count}"
puts "  Categories: #{Category.count}"
puts "  Tags:       #{Tag.count}"
puts "  Posts (visible):   #{Post.count}"
puts "  Posts (discarded): #{Post.unscoped.where.not(discarded_at: nil).count}"
puts "  Posts (total):     #{Post.unscoped.count}"
puts ""
puts "Seeds complete."
