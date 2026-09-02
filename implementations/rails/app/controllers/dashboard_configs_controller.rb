# frozen_string_literal: true

class DashboardConfigsController < ApplicationController
  def update
    authorize DashboardConfig, :update?
    result = Crm::DashboardPreferences.update(profile: current_profile, selected: params[:widgets])
    redirect_to root_path, **(result.success? ? {notice: "Dashboard widgets updated."} : {alert: result.errors.to_sentence})
  end
end
