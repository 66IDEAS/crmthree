# frozen_string_literal: true

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_profile

    def connect
      session_record = Session.authenticate(cookies.encrypted[Authentication::COOKIE_NAME])
      profile = session_record&.user_profile
      reject_unauthorized_connection unless profile&.active? && profile.role&.active? && Crm::EmailAccess.allowed?(profile.email)

      self.current_profile = profile
    end
  end
end
