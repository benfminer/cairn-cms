class CategoriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_category, only: %i[show edit update destroy]

  skip_after_action :verify_authorized,    only: :index
  after_action      :verify_policy_scoped, only: :index

  def index
    @categories = policy_scope(Category).order(:name)
                                        .left_joins(:posts)
                                        .group(:id)
                                        .select("categories.*, COUNT(posts.id) AS posts_count")
  end

  def show
    authorize @category
  end

  def new
    @category = Category.new
    authorize @category
  end

  def create
    @category = Category.new(category_params)
    authorize @category
    if @category.save
      redirect_to categories_path, notice: "Category created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @category
  end

  def update
    authorize @category
    if @category.update(category_params)
      redirect_to categories_path, notice: "Category updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @category
    @category.destroy
    redirect_to categories_path, notice: "Category deleted."
  end

  private

  def set_category = @category = Category.find(params[:id])
  def category_params = params.require(:category).permit(:name)
end
