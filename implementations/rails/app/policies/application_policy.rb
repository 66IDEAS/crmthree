# frozen_string_literal: true

class ApplicationPolicy
  ACTIONS = %w[create read read_all update delete].freeze
  OWNER_COLUMNS = %w[owner_id user_id author_id uploaded_by linked_by].freeze

  attr_reader :context, :user, :record

  def initialize(identity, record)
    @context = identity.is_a?(Crm::AuthorizationContext) ? identity : Crm::AuthorizationContext.for_profile(identity)
    @user = context.profile
    @record = record
  end

  def index? = allowed?(:read)
  def show? = allowed?(:read) && visible?
  def new? = create?
  def create? = allowed?(:create)
  def edit? = update?
  def update? = allowed?(:update) && visible?
  def destroy? = allowed?(:delete) && visible?
  def relationship? = update?
  def file? = show?
  def stream? = show?
  def export? = index?
  def ai_context? = show?
  def settings? = admin?

  def admin?
    active? && user.role&.active? && user.role.name == "Admin"
  end

  def manager?
    active? && Team.where(manager_id: user.id, active: true).exists?
  end

  def allowed?(action)
    return false unless active?
    return false unless api_scope_allows?(action)
    return true if admin?

    permissions = user.role&.permissions
    return false unless permissions.is_a?(Hash)

    object_permissions = permissions[record_class.name] || permissions["*"] || {}
    object_permissions[action.to_s] == true
  end

  def visible?
    return false unless active?
    return true if admin?
    return true unless record.respond_to?(:id)

    owner_column = self.class.owner_column(record.class)
    return true unless owner_column
    return true if record.public_send(owner_column) == user.id

    manager? && record.public_send(owner_column).in?(managed_profile_ids)
  end

  def managed_profile_ids
    @managed_profile_ids ||= UserProfile.where(team_id: Team.where(manager_id: user.id, active: true).select(:id)).pluck(:id)
  end

  def record_class
    record.is_a?(Class) ? record : record.class
  end

  def self.owner_column(model)
    OWNER_COLUMNS.find { |name| model.column_names.include?(name) } ||
      ("created_by" if model.column_names.include?("created_by"))
  end

  class Scope
    def initialize(identity, scope)
      @context = identity.is_a?(Crm::AuthorizationContext) ? identity : Crm::AuthorizationContext.for_profile(identity)
      @user = @context.profile
      @scope = scope
    end

    def resolve
      policy = ApplicationPolicy.new(context, scope)
      return scope.none unless policy.allowed?(:read)
      return scope.all if policy.admin?

      owner_column = ApplicationPolicy.owner_column(scope)
      return scope.all unless owner_column

      visible_ids = [user.id]
      visible_ids.concat(policy.managed_profile_ids) if policy.manager?
      scope.where(owner_column => visible_ids.uniq)
    end

    private

    attr_reader :context, :user, :scope
  end

  private

  def active?
    user&.active? && user.role&.active?
  end

  def api_scope_allows?(action)
    return true unless context.api?

    scopes = context.api_token.scopes
    scopes.include?("*") || scopes.include?(action.to_s) || scopes.include?("#{record_class.name}:#{action}")
  end
end
