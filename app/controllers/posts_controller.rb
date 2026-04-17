class PostsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post, only: %i[show edit update destroy submit_for_review publish reject archive]
  before_action :set_post_including_discarded, only: :undiscard

  # index uses policy_scope — swap verify_authorized for verify_policy_scoped
  skip_after_action :verify_authorized,    only: :index
  after_action      :verify_policy_scoped, only: :index

  def index
    @categories = policy_scope(Category).order(:name)
    @selected_category = params[:category_id]
    @posts = policy_scope(Post).with_rich_text_body
                               .with_attached_cover_image
                               .includes(:author)
                               .order(created_at: :desc)
    @posts = @posts.where(category_id: params[:category_id]) if params[:category_id].present?
  end

  def show
    authorize @post
  end

  def new
    @post = Post.new
    authorize @post
    load_form_collections
  end

  def create
    @post = Post.new(post_params)
    @post.author = current_user
    authorize @post

    if @post.save
      redirect_to @post, notice: "Post created."
    else
      load_form_collections
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @post
    load_form_collections
  end

  def update
    authorize @post

    if @post.update(post_params)
      redirect_to @post, notice: "Post updated."
    else
      load_form_collections
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @post
    @post.discard!
    redirect_to posts_path, notice: "Post discarded."
  end

  def undiscard
    authorize @post
    @post.undiscard!
    redirect_to @post, notice: "Post restored."
  end

  def submit_for_review
    authorize @post
    @post.submit_for_review!
    redirect_to @post, notice: "Post submitted for review."
  rescue Post::InvalidTransition => e
    redirect_to @post, alert: e.message
  end

  def publish
    authorize @post
    @post.publish!
    redirect_to @post, notice: "Post published."
  rescue Post::InvalidTransition => e
    redirect_to @post, alert: e.message
  end

  def reject
    authorize @post
    @post.reject!
    redirect_to @post, notice: "Post returned to draft."
  rescue Post::InvalidTransition => e
    redirect_to @post, alert: e.message
  end

  def archive
    authorize @post
    @post.archive!
    redirect_to @post, notice: "Post archived."
  rescue Post::InvalidTransition => e
    redirect_to @post, alert: e.message
  end

  private

  def set_post = @post = Post.includes(:category, :tags).find(params[:id])

  def set_post_including_discarded
    @post = Post.unscope(where: :discarded_at).includes(:category, :tags).find(params[:id])
  end

  def load_form_collections
    @form_categories = policy_scope(Category).order(:name)
    @form_tags       = policy_scope(Tag).order(:name)
  end

  def post_params
    params.require(:post).permit(:title, :body, :category_id, :cover_image, tag_ids: [])
  end
end
