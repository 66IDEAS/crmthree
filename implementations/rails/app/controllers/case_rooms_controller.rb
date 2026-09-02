# frozen_string_literal: true

class CaseRoomsController < ApplicationController
  before_action :load_ticket, only: %i[show update_status link_knowledge]

  def index
    @tickets = policy_scope(Ticket).includes(:status, :account, :assignee).order(updated_at: :desc, id: :asc)
  end

  def show
    authorize @ticket
    @statuses = TicketStatus.where(active: true).order(:sort_order, :id)
    @activities = @ticket.activities.includes(:owner).order(start_date: :desc, created_at: :desc, id: :desc)
    @comments = Comment.where(parent_type: "Ticket", parent_id: @ticket.id).includes(:author).order(:created_at, :id)
    @knowledge_articles = @ticket.ticket_knowledge_articles.includes(:article).order(linked_at: :desc, id: :desc)
    linked_ids = @ticket.knowledge_articles.select(:id)
    @knowledge_options = Pundit.policy_scope!(pundit_user, KnowledgeArticle).where(status: "Published").where.not(id: linked_ids)
      .order(:title, :id).limit(250)
  end

  def update_status
    authorize @ticket, :update?
    result = workspace_actions.update_ticket_status(@ticket, status_id: params.require(:status_id), resolution: params[:resolution])
    redirect_with_result(result, "Ticket status updated.")
  end

  def link_knowledge
    authorize @ticket, :relationship?
    result = workspace_actions.link_knowledge_article(@ticket, article_id: params.require(:article_id))
    redirect_with_result(result, "Knowledge article linked.")
  end

  private

  def load_ticket
    @ticket = Ticket.find(params[:id])
  end

  def workspace_actions
    @workspace_actions ||= Crm::Workspace::Actions.new(identity: pundit_user)
  end

  def redirect_with_result(result, notice)
    redirect_to case_room_path(@ticket), **(result.success? ? {notice:} : {alert: result.errors.to_sentence})
  end
end
