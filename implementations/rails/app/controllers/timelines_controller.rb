# frozen_string_literal: true

class TimelinesController < ApplicationController
  def mine
    authorize :timeline, :show?
    @timeline = Crm::TimelineFeed.for_user(profile: current_profile, filters: timeline_filters)
  end

  def team
    authorize :timeline, :team?
    @teams = accessible_teams
    @team = @teams.find { |candidate| candidate.id == params[:team_id] } || @teams.first
    @members = @team ? UserProfile.where(team_id: @team.id, active: true).order(:last_name, :first_name, :id).to_a : []
    @timeline = Crm::TimelineFeed.for_team(profile_ids: @members.map(&:id), filters: timeline_filters)
  end

  private

  def accessible_teams
    scope = Team.where(active: true).order(:name, :id)
    current_profile.role.name == "Admin" ? scope.to_a : scope.where(manager_id: current_profile.id).to_a
  end

  def timeline_filters
    params.permit(:from, :to, :event_type, :member_id, :page).to_h
  end
end
