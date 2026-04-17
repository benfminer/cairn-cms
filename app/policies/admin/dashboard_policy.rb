class Admin::DashboardPolicy < ApplicationPolicy
  def show? = user.admin?
end
