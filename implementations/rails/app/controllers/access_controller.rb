# frozen_string_literal: true

class AccessController < ApplicationController
  skip_before_action :require_authentication
  before_action :require_identity
  skip_after_action :verify_pundit_usage

  def pending
    @signed_in_email = Current.auth_user.email
  end
end
