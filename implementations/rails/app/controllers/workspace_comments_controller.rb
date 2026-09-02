# frozen_string_literal: true

class WorkspaceCommentsController < ApplicationController
  WORKSPACE_MODELS = {"DealRoom" => DealRoom, "Ticket" => Ticket}.freeze

  def create
    parent = WORKSPACE_MODELS.fetch(params.require(:workspace_type)).find(params.require(:workspace_id))
    authorize parent, :update?
    result = Crm::Workspace::Comments.create(parent:, content: params.require(:content), identity: pundit_user)
    path = parent.is_a?(DealRoom) ? deal_room_path(parent, anchor: "comments") : case_room_path(parent, anchor: "comments")
    redirect_to path, **(result.success? ? {notice: "Note posted."} : {alert: result.errors.to_sentence})
  rescue KeyError
    raise ActiveRecord::RecordNotFound
  end
end
