# frozen_string_literal: true

class TrendsController < ApplicationController
  def show
    authorize :home, :show?
    result = Crm::Analytics::Trends.new(identity: pundit_user).call
    raise ActiveRecord::RecordNotFound if result.failure?
    @periods = result.value.fetch(:periods)
    @metrics = result.value.fetch(:metrics)
  end
end
