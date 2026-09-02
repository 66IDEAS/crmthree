# frozen_string_literal: true

require "test_helper"

class RelationshipLinksControllerTest < ActionDispatch::IntegrationTest
  setup do
    Rails.cache.clear
    seed_crm!
    @auth = AuthUser.create!(email: "relations-admin@example.com", password: "correct-horse-battery")
    @admin = create_profile(email: @auth.email, auth_uid: @auth.id, role: Role.find_by!(name: "Admin"))
    @account = create_account(owner: @admin, name: "Linked account")
    @contact = Current.set(profile: @admin) do
      Contact.create!(first_name: "Grace", last_name: "Hopper", owner: @admin, status: "Active")
    end
    post session_path, params: {email: @auth.email, password: "correct-horse-battery"}
  end

  test "links and unlinks an existing record through the manifest junction" do
    path_arguments = {
      object_type: "Account", id: @account.id, relationship_name: "additional_contacts"
    }

    assert_difference "ContactAccount.count", 1 do
      post record_relationship_path(**path_arguments), params: {
        related_id: @contact.id,
        junction: {role: "Decision maker", is_primary: "1"}
      }
    end
    junction = ContactAccount.find_by!(account: @account, contact: @contact)
    assert_equal "Decision maker", junction.role
    assert junction.is_primary

    assert_difference "ContactAccount.count", -1 do
      delete record_relationship_link_path(**path_arguments, related_id: @contact.id)
    end
  end
end
