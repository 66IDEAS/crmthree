# frozen_string_literal: true

namespace :crm do
  namespace :auth do
    desc "Create the first local administrator (EMAIL, FIRST_NAME, LAST_NAME, PASSWORD or PASSWORD_FILE)"
    task bootstrap: :environment do
      password = if ENV["PASSWORD_FILE"].present?
        File.read(ENV.fetch("PASSWORD_FILE")).strip
      else
        ENV["PASSWORD"]
      end

      user = Crm::FirstAdminBootstrap.call!(
        email: ENV["EMAIL"],
        first_name: ENV.fetch("FIRST_NAME", "Local"),
        last_name: ENV.fetch("LAST_NAME", "Administrator"),
        password: password
      )
      puts "Administrator ready: #{user.email}"
    rescue Crm::FirstAdminBootstrap::UnsafeState, ActiveRecord::RecordInvalid => error
      abort "Bootstrap refused: #{error.message}"
    end

    desc "Create a local password reset URL file (EMAIL)"
    task reset_link: :environment do
      user = AuthUser.find_by!(email: Crm::Email.normalize(ENV["EMAIL"]))
      Crm::PasswordReset.issue!(user)
      puts "Reset instructions written to tmp/local_password_resets/#{user.id}.txt"
    end
  end
end
