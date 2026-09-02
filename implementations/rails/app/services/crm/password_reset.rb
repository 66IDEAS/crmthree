# frozen_string_literal: true

module Crm
  class PasswordReset
    LIFETIME = 30.minutes

    def self.issue!(auth_user)
      token = SecureRandom.urlsafe_base64(48)
      auth_user.update!(password_reset_digest: Session.digest(token), password_reset_sent_at: Time.current)
      persist_local_instructions(auth_user, token)
      token
    end

    def self.authenticate(token)
      return if token.blank?

      digest = Session.digest(token)
      candidate = AuthUser.where("password_reset_sent_at > ?", LIFETIME.ago).find_by(password_reset_digest: digest)
      candidate if candidate && ActiveSupport::SecurityUtils.secure_compare(candidate.password_reset_digest, digest)
    end

    def self.consume!(auth_user)
      auth_user.update!(password_reset_digest: nil, password_reset_sent_at: nil)
      FileUtils.rm_f(Rails.root.join("tmp/local_password_resets/#{auth_user.id}.txt"))
    end

    def self.persist_local_instructions(auth_user, token)
      directory = Rails.root.join("tmp/local_password_resets")
      FileUtils.mkdir_p(directory, mode: 0o700)
      path = directory.join("#{auth_user.id}.txt")
      path.write("Open http://localhost:3000/password/reset/#{token}\n", mode: "w", perm: 0o600)
      path
    end
    private_class_method :persist_local_instructions
  end
end
