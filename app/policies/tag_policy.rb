class TagPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve = scope.all
  end

  def index?   = true
  def show?    = true
  def new?     = admin_or_editor?
  def create?  = admin_or_editor?
  def edit?    = admin_or_editor?
  def update?  = admin_or_editor?
  def destroy? = admin_or_editor?

  private

  def admin_or_editor? = user.admin? || user.editor?
end
