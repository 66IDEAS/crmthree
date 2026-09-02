# frozen_string_literal: true

class LeaderboardsController < ApplicationController
  def show
    authorize :leaderboard, :show?
    @board = Crm::Leaderboard.new(viewer: current_profile, dimension: params[:dimension], period: params[:period]).call
  end
end
