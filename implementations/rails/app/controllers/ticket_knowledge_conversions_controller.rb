# frozen_string_literal: true

class TicketKnowledgeConversionsController < ApplicationController
  def create
    ticket = Ticket.find(params[:ticket_id])
    authorize ticket, :convert_to_knowledge?
    result = Crm::Service::CaseConverter.new(
      ticket_id: ticket.id,
      idempotency_key: params.require(:conversion).permit(:idempotency_key)[:idempotency_key],
      identity: pundit_user
    ).call

    if result.success?
      article_id = result.value.stringify_keys.fetch("article_id")
      redirect_to edit_record_path(object_type: "KnowledgeArticle", id: article_id,
        return_to: record_path(object_type: "Ticket", id: ticket.id)),
        notice: "Draft knowledge article created from the resolved ticket."
    else
      redirect_to record_path(object_type: "Ticket", id: ticket.id),
        alert: result.errors.to_sentence.presence || "Knowledge article could not be created."
    end
  end
end
