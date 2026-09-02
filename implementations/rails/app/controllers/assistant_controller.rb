# frozen_string_literal: true

class AssistantController < ApplicationController
  def create
    authorize :search, :show?
    @outcome = Crm::AI::Assistant.new(identity: pundit_user).call(query: params[:q], conversation_id: params[:conversation_id])
    render partial: "assistant/outcome", locals: {outcome: @outcome}
  end

  def destroy
    conversation = policy_scope(AIConversation).find(params[:id])
    authorize conversation
    conversation.destroy!
    head :no_content
  end
end
