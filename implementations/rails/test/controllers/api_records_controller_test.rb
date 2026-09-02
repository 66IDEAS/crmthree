# frozen_string_literal: true

require "test_helper"

class APIRecordsControllerTest < ActionDispatch::IntegrationTest
  setup do
    seed_crm!
    @owner = create_profile(email: "api-owner@example.com")
    @other = create_profile(email: "api-other@example.com")
    @owned = create_account(owner: @owner, name: "API owned")
    @unrelated = create_account(owner: @other, name: "API private")
    @token, @raw = Current.set(profile: @owner) do
      APIToken.issue!(profile: @owner, name: "read token", scopes: ["read"])
    end
  end

  test "requires an active bearer token" do
    get api_path(@owned)
    assert_response :unauthorized

    @token.update!(revoked_at: Time.current)
    get api_path(@owned), headers: authorization(@raw)
    assert_response :unauthorized
  end

  test "reads owned data and conceals unrelated data" do
    get api_path(@owned), headers: authorization(@raw)
    assert_response :success
    assert_equal @owned.id, response.parsed_body.fetch("id")

    get api_path(@unrelated), headers: authorization(@raw)
    assert_response :not_found
    refute_includes response.body, "API private"
  end

  test "a read-only API identity cannot mutate" do
    patch api_path(@owned), params: {record: {name1: "Changed"}}, headers: authorization(@raw), as: :json

    assert_response :not_found
    assert_equal "API owned", @owned.reload.name1
  end

  test "an update-scoped API identity uses the authorized audited adapter" do
    _token, raw = Current.set(profile: @owner) do
      APIToken.issue!(profile: @owner, name: "write token", scopes: %w[read update])
    end

    patch api_path(@owned), params: {record: {name1: "API updated"}}, headers: authorization(raw), as: :json

    assert_response :success
    assert_equal "API updated", @owned.reload.name1
    assert AuditLog.exists?(object_type: "Account", object_id: @owned.id, field_name: "name1", user_id: @owner.id)
  end

  test "lists with stable pagination metadata" do
    get "/api/v1/records/Account", params: {page: 1, limit: 1}, headers: authorization(@raw)

    assert_response :success
    assert_equal [@owned.id], response.parsed_body.fetch("data").pluck("id")
    assert_equal({"page" => 1, "limit" => 1, "total" => 1, "pages" => 1}, response.parsed_body.fetch("meta"))
  end

  test "create and delete use token scopes stable errors and the same adapter" do
    admin = create_profile(email: "api-admin@example.com", role: Role.find_by!(name: "Admin"))
    _token, raw = Current.set(profile: admin) do
      APIToken.issue!(profile: admin, name: "crud token", scopes: %w[read create delete])
    end

    post "/api/v1/records/Account", params: {record: {name1: "Created over API", owner_id: admin.id, status: "Active"}},
      headers: authorization(raw), as: :json
    assert_response :created
    id = response.parsed_body.fetch("id")
    assert Account.exists?(id:)

    post "/api/v1/records/Account", params: {record: {owner_id: admin.id}}, headers: authorization(raw), as: :json
    assert_response :unprocessable_entity
    assert_equal "validation_failed", response.parsed_body.fetch("error")

    delete "/api/v1/records/Account/#{id}", headers: authorization(raw)
    assert_response :no_content
    refute Account.exists?(id:)
  end

  test "serves the OpenAPI contract without exposing a token" do
    get "/api/v1/openapi"
    assert_response :success
    assert_includes response.body, "openapi: 3.1.0"
    assert_includes response.body, "bearerToken"
  end

  private

  def api_path(record)
    "/api/v1/records/Account/#{record.id}"
  end

  def authorization(raw)
    {"Authorization" => "Bearer #{raw}"}
  end
end
