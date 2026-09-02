# frozen_string_literal: true

require "test_helper"

class AuthorizationMatrixTest < ActiveSupport::TestCase
  setup do
    seed_crm!
    @admin = create_profile(email: "admin-policy@example.com", role: Role.find_by!(name: "Admin"))
    @manager = create_profile(email: "manager@example.com", role: Role.find_by!(name: "Manager"))
    @owner = create_profile(email: "owner@example.com")
    @teammate = create_profile(email: "teammate@example.com")
    @unrelated = create_profile(email: "unrelated@example.com")
    @inactive = create_profile(email: "inactive-policy@example.com", active: false)
    create_team(manager: @manager, members: [@owner, @teammate])
    @record = create_account(owner: @owner, name: "Protected account")
  end

  test "enforces guest inactive owner teammate manager and admin visibility" do
    refute policy(nil).show?
    refute policy(@inactive).show?
    assert policy(@owner).show?
    assert policy(@owner).update?
    refute policy(@owner).destroy?
    refute policy(@teammate).show?
    refute policy(@unrelated).show?
    assert policy(@manager).show?
    assert policy(@manager).update?
    assert policy(@admin).show?
    assert policy(@admin).destroy?
  end

  test "uses the same boundary for relationships files streams exports and AI context" do
    %i[relationship? file? stream? ai_context?].each do |capability|
      assert policy(@owner).public_send(capability), capability
      refute policy(@unrelated).public_send(capability), capability
    end
    assert policy(@owner).export?
    refute policy(@inactive).export?
  end

  test "restricts settings to administrators" do
    assert Pundit.policy!(identity(@admin), DataSourceConfig).settings?
    refute Pundit.policy!(identity(@manager), DataSourceConfig).settings?
    refute Pundit.policy!(identity(@owner), DataSourceConfig).settings?
  end

  test "applies API scopes in addition to profile permissions" do
    read_token = APIToken.new(scopes: ["read"])
    api_policy = ApplicationPolicy.new(identity(@owner, token: read_token), @record)

    assert api_policy.show?
    refute api_policy.update?
    assert api_policy.file?
  end

  test "policy scope returns owner and managed records but not teammate records" do
    teammate_record = create_account(owner: @teammate, name: "Teammate account")
    unrelated_record = create_account(owner: @unrelated, name: "Unrelated account")

    assert_equal [@record.id], Pundit.policy_scope!(identity(@owner), Account).pluck(:id)
    assert_equal [@record.id, teammate_record.id].sort,
      Pundit.policy_scope!(identity(@manager), Account).pluck(:id).sort
    assert_includes Pundit.policy_scope!(identity(@admin), Account), unrelated_record
  end

  private

  def policy(profile)
    ApplicationPolicy.new(identity(profile), @record)
  end
end
