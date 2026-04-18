class PostPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin? || user.editor?
        scope.unscoped
      else
        scope.where(author_id: user.id)
      end
    end
  end

  def index?   = true
  def show?    = admin_or_editor? || own_post?
  def new?     = true
  def create?  = true
  def edit?    = update?
  def update?  = admin_or_editor? || own_post?
  def destroy? = admin_or_editor? || own_post?

  def submit_for_review? = own_post? && record.draft?
  def publish?           = admin_or_editor? && record.in_review?
  def reject?            = admin_or_editor? && record.in_review?
  def archive?           = admin_or_editor? && record.published?
  def undiscard?         = user.admin?

  private

  def own_post?        = record.author_id == user.id
  def admin_or_editor? = user.admin? || user.editor?
end
