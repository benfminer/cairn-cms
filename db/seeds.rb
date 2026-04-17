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

puts "Seeding posts..."

posts_data = [
  {
    title: "Getting Started with Rails 7",
    status: :published,
    author: author,
    body: "<p>Rails 7 brings a fresh approach to JavaScript with Hotwire — Turbo and Stimulus replace the old asset pipeline complexity. In this post we walk through setting up a new Rails 7 app from scratch, connecting Postgres, and getting Tailwind rendering in under 10 minutes.</p><p>The <code>bin/dev</code> command is your new best friend. It runs the Rails server and the CSS watcher in parallel via Foreman, so you always have compiled styles without thinking about it.</p>"
  },
  {
    title: "Understanding Pundit Policies",
    status: :published,
    author: editor,
    body: "<p>Pundit is a minimal authorization library that puts policy logic in plain Ruby objects. Each policy class maps to a model and defines methods like <code>show?</code>, <code>update?</code>, and <code>destroy?</code> that return true or false based on the current user.</p><p>The key insight is that Pundit stays out of your way — there's no DSL to learn, just Ruby methods. That makes policies easy to test, easy to read, and easy to extend as your authorization rules grow.</p>"
  },
  {
    title: "ActionText and Trix: Rich Text in Rails",
    status: :published,
    author: author,
    body: "<p>ActionText is Rails' built-in rich text solution. It stores content in a separate <code>action_text_rich_texts</code> table and renders it through the Trix editor — a sensible, accessible WYSIWYG that ships with Rails.</p><p>The gotcha most developers hit first: always eager-load with <code>Post.with_rich_text_body</code> on index queries. Without it you get one query per post just to load the body — a classic N+1 that only shows up under real data volumes.</p>"
  },
  {
    title: "Soft Deletes with Discard",
    status: :in_review,
    author: author,
    body: "<p>Hard-deleting records is almost always the wrong call in a production app. Users expect an undo, auditors expect a trail, and foreign key constraints get painful fast. Soft deletes solve all three problems by adding a <code>discarded_at</code> timestamp instead of removing the row.</p><p>The Discard gem adds <code>discard!</code> and <code>undiscard!</code> to your models and sets up a default scope that filters out discarded records automatically. Admin trash views use <code>Post.only_discarded</code> to see what's been removed.</p>"
  },
  {
    title: "Building a Publishing Workflow",
    status: :in_review,
    author: editor,
    body: "<p>A CMS without a publishing workflow is just a fancy text editor. Real editorial teams need a way to move content through stages — draft, review, published, archived — with clear rules about who can move it where.</p><p>In Cairn we model this as a state machine directly on the Post model. Each transition is an explicit method with a guard clause. <code>publish!</code> raises <code>InvalidTransition</code> if the post isn't in review first. No jumping states, no surprise status changes.</p>"
  },
  {
    title: "Postgres Enum Columns in Rails",
    status: :draft,
    author: author,
    body: "<p>Rails integer enums are convenient but have a subtle footgun: the database stores integers, not strings. That means <code>Post.group(:status).count</code> returns <code>{ 0 => 5, 1 => 2 }</code> not <code>{ \"draft\" => 5, \"in_review\" => 2 }</code>. Always <code>transform_keys</code> when you need human-readable keys.</p>"
  },
  {
    title: "Hotwire Turbo Frames Explained",
    status: :draft,
    author: author,
    body: "<p>Turbo Frames let you update a portion of a page without a full reload — no JavaScript required. Wrap any section in a <code>&lt;turbo-frame&gt;</code> tag with an id, and any link or form inside that frame will automatically scope its response to just that region.</p><p>The mental model shift: you're not writing JavaScript to update the DOM. You're writing server-rendered HTML that Turbo replaces in place. The result is SPA-like interactions with none of the client-side state complexity.</p>"
  },
  {
    title: "Stimulus Controllers: A Practical Guide",
    status: :draft,
    author: editor,
    body: "<p>Stimulus is a lightweight JavaScript framework designed to work with server-rendered HTML. Instead of owning the DOM, Stimulus controllers connect to existing HTML via <code>data-controller</code> attributes and add behaviour on top.</p><p>A controller that toggles a menu is a few lines. A controller that handles form validation is still readable two months later. That's the point — just enough JavaScript, exactly where you need it.</p>"
  },
  {
    title: "Deploying Rails to Fly.io",
    status: :archived,
    author: admin,
    body: "<p>Fly.io has become the go-to Rails hosting platform for good reason: it runs containers close to your users, Postgres is first-class, and the CLI is genuinely pleasant. This post covers the full flow from <code>fly launch</code> to a live app with migrations running in production.</p><p>The one thing that trips everyone up: <code>SECRET_KEY_BASE</code>. Set it with <code>fly secrets set SECRET_KEY_BASE=$(rails secret)</code> before your first deploy or you'll get a cryptic 500 on the credentials endpoint.</p>"
  },
  {
    title: "Writing Readable RSpec Tests",
    status: :draft,
    author: author,
    body: "<p>RSpec tests that read like documentation are worth more than tests that just pass. Use descriptive <code>describe</code> and <code>context</code> blocks, keep each <code>it</code> block focused on one assertion, and name your FactoryBot factories to match the state they represent.</p><p>The three-part structure — arrange, act, assert — keeps tests understandable at a glance. If your arrange block is longer than five lines, you probably need a factory or a helper.</p>"
  }
]

posts_data.each do |attrs|
  body_html = attrs.delete(:body)
  post = Post.find_or_initialize_by(title: attrs[:title])
  post.assign_attributes(attrs)
  post.body = body_html if post.new_record? || post.body.to_plain_text.blank?
  post.save!
  puts "  [#{post.status}] #{post.title}"
end

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

puts "Assigning categories and tags to posts..."

assignments = {
  "Getting Started with Rails 7"      => { category: "Tutorials",    tags: %w[rails hotwire tailwind] },
  "Understanding Pundit Policies"     => { category: "Deep Dives",   tags: %w[rails pundit] },
  "ActionText and Trix: Rich Text in Rails" => { category: "Deep Dives", tags: %w[rails] },
  "Soft Deletes with Discard"         => { category: "Tips & Tricks", tags: %w[rails postgres] },
  "Building a Publishing Workflow"    => { category: "Deep Dives",   tags: %w[rails] },
  "Postgres Enum Columns in Rails"    => { category: "Tips & Tricks", tags: %w[postgres rails] },
  "Hotwire Turbo Frames Explained"    => { category: "Deep Dives",   tags: %w[hotwire rails] },
  "Stimulus Controllers: A Practical Guide" => { category: "Tutorials", tags: %w[hotwire] },
  "Deploying Rails to Fly.io"         => { category: "Deployment",   tags: %w[devops rails] },
  "Writing Readable RSpec Tests"      => { category: "Tips & Tricks", tags: %w[testing rails] }
}

assignments.each do |title, attrs|
  post = Post.find_by(title: title)
  next unless post
  cat = categories.find { |c| c.name == attrs[:category] }
  post.update!(category: cat)
  attrs[:tags].each do |tag_name|
    tag = tags.find { |t| t.name == tag_name }
    post.tags << tag unless post.tags.include?(tag)
  end
  puts "  #{title} → #{cat.name}"
end

puts "Seeds complete."
