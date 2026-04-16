class PostsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post, only: %i[show edit update destroy]

  # index uses policy_scope — swap verify_authorized for verify_policy_scoped
  skip_after_action :verify_authorized,    only: :index
  after_action      :verify_policy_scoped, only: :index

  def index
    @posts = policy_scope(Post).with_rich_text_body
                               .includes(:author)
                               .order(created_at: :desc)
  end

  def show
    authorize @post
  end

  def new
    @post = Post.new
    authorize @post
  end

  def create
    @post = Post.new(post_params)
    @post.author = current_user
    # Authors always create as draft — ignore any status in params
    @post.status = :draft unless current_user.admin? || current_user.editor?
    authorize @post

    if @post.save
      redirect_to @post, notice: "Post created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @post
  end

  def update
    authorize @post
    # Authors cannot change status — strip it from params for them
    permitted = current_user.author? ? post_params.except(:status) : post_params

    if @post.update(permitted)
      redirect_to @post, notice: "Post updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @post
    @post.destroy
    redirect_to posts_path, notice: "Post deleted."
  end

  private

  def set_post = @post = Post.find(params[:id])

  def post_params
    params.require(:post).permit(:title, :body, :status)
  end
end
