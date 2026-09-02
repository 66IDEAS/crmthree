# frozen_string_literal: true

class RelationshipLinksController < ApplicationController
  before_action :load_parent

  def create
    authorize @parent, :relationship?
    linker = relationship_linker
    permitted = params.fetch(:junction, ActionController::Parameters.new)
      .permit(*linker.junction_fields.map { |field| field.fetch("name") })
    result = linker.link(related_id: params.require(:related_id), junction_attributes: permitted)
    redirect_with_result(result, "Record linked.")
  end

  def destroy
    authorize @parent, :relationship?
    result = relationship_linker.unlink(related_id: params.require(:related_id))
    redirect_with_result(result, "Record unlinked.")
  end

  private

  def load_parent
    @parent = Crm::ModelRegistry.model_for(params[:object_type]).find(params[:id])
  end

  def relationship_linker
    @relationship_linker ||= Crm::RelationshipLinker.new(
      object_type: params[:object_type],
      record: @parent,
      relationship_name: params[:relationship_name],
      identity: pundit_user
    )
  end

  def redirect_with_result(result, success_message)
    path = record_path(object_type: params[:object_type], id: @parent.id)
    if result.success?
      redirect_to path, notice: success_message
    else
      redirect_to path, alert: result.errors.to_sentence.presence || "Relationship could not be changed."
    end
  end
end
