# frozen_string_literal: true

class ConfigurationProposalsController < ApplicationController
  def create
    authorize ConfigurationProposal, :create?
    result = Crm::AI::ProposalBuilder.new(identity: pundit_user).call(kind: params[:kind], prompt: params[:prompt])
    redirect_to settings_path(anchor: "ai-proposals"), **message_for(result, "Proposal drafted for review.")
  end

  def approve
    proposal = ConfigurationProposal.find(params[:id])
    authorize proposal, :update?
    result = Crm::Configuration::Applicator.new(proposal:, actor: current_profile).apply
    redirect_to settings_path(anchor: "ai-proposals"), **message_for(result, "Proposal approved and versioned.")
  end

  def rollback
    proposal = ConfigurationProposal.find(params[:id])
    authorize proposal, :update?
    result = Crm::Configuration::Applicator.new(proposal:, actor: current_profile).rollback
    redirect_to settings_path(anchor: "ai-proposals"), **message_for(result, "Proposal rolled back.")
  end

  def destroy
    proposal = ConfigurationProposal.find(params[:id])
    authorize proposal
    proposal.update!(status: "Rejected")
    redirect_to settings_path(anchor: "ai-proposals"), notice: "Proposal rejected."
  end

  private

  def message_for(result, success)
    result.success? ? {notice: success} : {alert: result.errors.to_sentence}
  end
end
