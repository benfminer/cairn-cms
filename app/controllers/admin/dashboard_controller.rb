class Admin::DashboardController < Admin::BaseController
  def show
    authorize Admin::Dashboard.new
    @user_counts  = User.group(:role).count.transform_keys { |k| User.roles.key(k) }
    @post_counts  = Post.group(:status).count.transform_keys { |k| Post.statuses[k] }
    @recent_posts = Post.unscoped.includes(:author).order(created_at: :desc).limit(10)
  end
end
