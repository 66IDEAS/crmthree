# frozen_string_literal: true

class KnowledgeDraftsController < ApplicationController
  def create
    opportunity = Pundit.policy_scope!(pundit_user, Opportunity).find(params[:opportunity_id])
    authorize opportunity, :ai_context?
    result = Crm::AI::KnowledgeDraft.new(identity: pundit_user).from_opportunity(id: opportunity.id)
    if result.success?
      redirect_to edit_record_path(object_type: "KnowledgeArticle", id: result.value.id), notice: "Editable AI knowledge draft created."
    else
      redirect_to record_path(object_type: "Opportunity", id: opportunity.id), alert: result.errors.to_sentence
    end
  end
end
