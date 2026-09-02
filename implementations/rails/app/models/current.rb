# frozen_string_literal: true

class Current < ActiveSupport::CurrentAttributes
  attribute :auth_user, :profile, :session, :api_token, :translation_labels

  resets { Time.zone = nil }
end
