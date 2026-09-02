# frozen_string_literal: true

class DealRoomsController < ApplicationController
  before_action :load_deal_room, only: %i[show close update_stage]

  def index
    @deal_rooms = policy_scope(DealRoom).includes(opportunity: %i[account stage], owner: :role)
      .order(status: :asc, updated_at: :desc, id: :asc)
  end

  def new
    @opportunity = Pundit.policy_scope!(pundit_user, Opportunity).find(params.require(:opportunity_id))
    @deal_room = DealRoom.new(name: @opportunity.name, opportunity: @opportunity, owner: current_profile, status: "Active")
    authorize @deal_room, :create?
  end

  def create
    @opportunity = Pundit.policy_scope!(pundit_user, Opportunity).find(params.require(:opportunity_id))
    attributes = params.require(:deal_room).permit(:name, :description).merge(
      opportunity_id: @opportunity.id, owner_id: current_profile.id, status: "Active"
    )
    @deal_room = DealRoom.new(attributes)
    authorize @deal_room, :create?
    result = Crm::Data::LocalActiveRecordAdapter.new(object_type: "DealRoom", identity: pundit_user).create(attributes)
    if result.success?
      redirect_to deal_room_path(result.value), notice: "Deal Room created."
    else
      @form_errors = result.errors
      render :new, status: result.status
    end
  end

  def show
    authorize @deal_room
    @opportunity = @deal_room.opportunity
    @stages = PipelineStage.where(active: true).order(:sort_order, :id)
    @activities = Activity.where(opportunity_id: @opportunity.id).includes(:owner).order(start_date: :desc, created_at: :desc, id: :desc)
    @comments = @deal_room.comments.includes(:author).order(created_at: :asc, id: :asc)
    @contacts = @opportunity.opportunity_contacts.includes(:contact).order(:created_at, :id)
    @documents = @deal_room.documents.includes(:uploader).order(created_at: :desc, id: :desc)
  end

  def close
    authorize @deal_room, :update?
    result = workspace_actions.close_deal_room(@deal_room)
    redirect_with_result(result, "Deal Room closed.")
  end

  def update_stage
    authorize @deal_room, :update?
    result = workspace_actions.update_deal_stage(@deal_room, stage_id: params.require(:stage_id))
    redirect_with_result(result, "Deal stage updated.")
  end

  private

  def load_deal_room
    @deal_room = DealRoom.find(params[:id])
  end

  def workspace_actions
    @workspace_actions ||= Crm::Workspace::Actions.new(identity: pundit_user)
  end

  def redirect_with_result(result, notice)
    redirect_to deal_room_path(@deal_room), **(result.success? ? {notice:} : {alert: result.errors.to_sentence})
  end
end
