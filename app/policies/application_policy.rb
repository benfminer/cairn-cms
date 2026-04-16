class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    raise Pundit::NotAuthorizedError, "must be logged in" unless user

    @user   = user
    @record = record
  end

  # All actions default to false (deny).
  # Subclasses override only what they explicitly permit.
  def index?   = false
  def show?    = false
  def new?     = false
  def create?  = false
  def edit?    = false
  def update?  = false
  def destroy? = false

  class Scope
    def initialize(user, scope)
      raise Pundit::NotAuthorizedError, "must be logged in" unless user

      @user  = user
      @scope = scope
    end

    def resolve
      raise NotImplementedError, "#{self.class} has not implemented method 'resolve'"
    end

    private

    attr_reader :user, :scope
  end

  private

  attr_reader :user, :record
end
