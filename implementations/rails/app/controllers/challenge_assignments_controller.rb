# frozen_string_literal: true

class ChallengeAssignmentsController < ApplicationController
  def create
    profile = UserProfile.find(params.fetch(:profile_id, current_profile.id))
    authorize profile, :show?
    raise Pundit::NotAuthorizedError unless profile.id == current_profile.id

    result = Crm::Gamification::ChallengeAssignments.monthly_for(profile:, actor: current_profile)
    redirect_to profile_path, **(result.success? ? {notice: result.code == :existing ? "This month's mission already exists." : "Monthly mission assigned."} : {alert: result.errors.to_sentence})
  end
end
