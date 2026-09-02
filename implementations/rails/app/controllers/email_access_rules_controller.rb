# frozen_string_literal: true

class EmailAccessRulesController < ApplicationController
  def create
    rule = EmailAccessRule.new(rule_params)
    authorize rule
    Current.set(profile: current_profile) do
      EmailAccessRule.transaction do
        rule.save!
        preserve_current_administrator_access!
      end
    end
    redirect_to settings_path(anchor: "access-control"), notice: "Access rule added."
  rescue ActiveRecord::RecordInvalid => error
    redirect_to settings_path(anchor: "access-control"), alert: error.record.errors.full_messages.to_sentence
  end

  def destroy
    rule = EmailAccessRule.find(params[:id])
    authorize rule
    rule.destroy!
    redirect_to settings_path(anchor: "access-control"), notice: "Access rule removed."
  end

  private

  def rule_params
    params.require(:email_access_rule).permit(:rule_type, :value).merge(active: true)
  end

  def preserve_current_administrator_access!
    return if Crm::EmailAccess.allowed?(current_profile.email)

    EmailAccessRule.create!(rule_type: "Email", value: current_profile.email, active: true)
  end
end
