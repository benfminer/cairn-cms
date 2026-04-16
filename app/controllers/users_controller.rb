class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user

  def show   = authorize @user
  def edit   = authorize @user

  def update
    authorize @user
    if @user.update(user_params)
      redirect_to user_path(@user), notice: "Profile updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user = @user = User.find(params[:id])

  def user_params
    params.require(:user).permit(:email)
  end

  def user_not_authorized
    flash[:alert] = "You can only edit your own profile."
    redirect_to user_path(current_user)
  end
end
