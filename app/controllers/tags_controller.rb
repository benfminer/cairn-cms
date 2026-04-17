class TagsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_tag, only: %i[show edit update destroy]

  skip_after_action :verify_authorized,    only: :index
  after_action      :verify_policy_scoped, only: :index

  def index
    @tags = policy_scope(Tag).order(:name)
  end

  def show
    authorize @tag
  end

  def new
    @tag = Tag.new
    authorize @tag
  end

  def create
    @tag = Tag.new(tag_params)
    authorize @tag
    if @tag.save
      redirect_to tags_path, notice: "Tag created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @tag
  end

  def update
    authorize @tag
    if @tag.update(tag_params)
      redirect_to tags_path, notice: "Tag updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @tag
    @tag.destroy
    redirect_to tags_path, notice: "Tag deleted."
  end

  private

  def set_tag = @tag = Tag.find(params[:id])
  def tag_params = params.require(:tag).permit(:name)
end
