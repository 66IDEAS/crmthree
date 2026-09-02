# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :load_profile, only: %i[update destroy]

  def create
    authorize UserProfile
    values = params.require(:user).permit(:email, :first_name, :last_name, :role_id, :password, :add_to_whitelist).to_h.symbolize_keys
    add_to_whitelist = ActiveModel::Type::Boolean.new.cast(values.delete(:add_to_whitelist))
    result = Crm::UserManagement.invite(attributes: values, actor: current_profile, add_to_whitelist:)
    redirect_with_result(result, success: result.code == :local_user_created ? "Local user created." : "User invited.")
  end

  def update
    authorize @profile
    result = if params[:role_id].present?
      Crm::UserManagement.change_role(profile: @profile, role_id: params[:role_id], actor: current_profile)
    else
      Crm::UserManagement.set_active(profile: @profile,
        active: ActiveModel::Type::Boolean.new.cast(params.require(:active)), actor: current_profile)
    end
    redirect_with_result(result, success: "User access updated.")
  end

  def destroy
    authorize @profile
    result = Crm::UserManagement.destroy(profile: @profile, actor: current_profile)
    redirect_with_result(result, success: "User deleted; their CRM records were retained.")
  end

  private

  def load_profile
    @profile = UserProfile.find(params[:id])
  end

  def redirect_with_result(result, success:)
    redirect_to settings_path(anchor: "user-management"),
      **(result.success? ? {notice: success} : {alert: result.errors.to_sentence.presence || "User could not be updated."})
  end
end
