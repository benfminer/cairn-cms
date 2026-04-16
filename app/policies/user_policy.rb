class UserPolicy < ApplicationPolicy
  def show?   = own_record? || user.admin?
  def edit?   = update?
  def update? = own_record? || user.admin?

  private

  def own_record? = user == record
end
