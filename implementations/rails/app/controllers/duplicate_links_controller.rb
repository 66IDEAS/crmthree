# frozen_string_literal: true

class DuplicateLinksController < ApplicationController
  before_action :load_link, only: %i[merge unlink revert]

  def index
    @links = policy_scope(DuplicateLink).includes(:merger).order(created_at: :desc).limit(200)
    authorize DuplicateLink, :index?
  end

  def analyze
    authorize DuplicateLink, :create?
    result = Crm::Duplicates::Analyzer.new(identity: pundit_user).call
    redirect_to duplicate_links_path, **(result.success? ? {notice: "Duplicate analysis complete: #{result.value} candidates added."} : {alert: result.errors.to_sentence})
  end

  def merge = perform(:merge, "Records merged. The original values remain available for reversal.")
  def unlink = perform(:false_positive, "Candidate unlinked as a false positive.")
  def revert = perform(:revert, "Merge reverted from its saved snapshot.")

  private

  def load_link = @link = policy_scope(DuplicateLink).find(params[:id])
  def perform(action, notice)
    authorize @link, :update?
    result = Crm::Duplicates::Manager.new(link: @link, identity: pundit_user).public_send(action)
    redirect_to duplicate_links_path, **(result.success? ? {notice:} : {alert: result.errors.to_sentence})
  end
end
