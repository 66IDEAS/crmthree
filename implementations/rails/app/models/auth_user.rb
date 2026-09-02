# frozen_string_literal: true

class AuthUser < ApplicationRecord
  has_secure_password

  has_many :sessions, dependent: :destroy
  has_one :profile, class_name: "UserProfile", foreign_key: :auth_uid, inverse_of: false

  before_validation :assign_uuid, on: :create
  before_validation :normalize_email

  validates :email, presence: true, length: {maximum: 241}, uniqueness: {case_sensitive: false},
    format: {with: URI::MailTo::EMAIL_REGEXP}
  validates :password, length: {minimum: 12}, if: -> { password.present? }

  def locked?
    locked_until.present? && locked_until.future?
  end

  private

  def assign_uuid
    self.id ||= SecureRandom.uuid
  end

  def normalize_email
    self.email = Crm::Email.normalize(email)
  end
end
