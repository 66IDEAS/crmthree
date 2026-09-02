# frozen_string_literal: true

class LineItemsController < ApplicationController
  before_action :authorize_parent

  def create
    result = manager.create(line_item_params, idempotency_key: params[:idempotency_key])
    redirect_with_result(result, success: "Line item added.")
  end

  def update
    result = manager.update(params[:id], line_item_params)
    redirect_with_result(result, success: "Line item updated.")
  end

  def destroy
    result = manager.destroy(params[:id])
    redirect_with_result(result, success: "Line item removed.")
  end

  private

  attr_reader :parent

  def authorize_parent
    parent_model = Crm::Sales::Pricing::PARENT_MODELS[params[:parent_type].to_s]
    raise ActiveRecord::RecordNotFound unless parent_model

    @parent = parent_model.find(params[:parent_id])
    authorize parent, :update?
  end

  def manager
    @manager ||= Crm::Sales::LineItemManager.new(parent_type: parent.class.name, parent_id: parent.id, identity: pundit_user)
  end

  def line_item_params
    params.require(:line_item).permit(*Crm::Sales::LineItemManager::ATTRIBUTES)
  end

  def redirect_with_result(result, success:)
    options = result.success? ? {notice: success} : {alert: result.errors.to_sentence.presence || "Line item could not be changed."}
    redirect_to record_path(object_type: parent.class.name, id: parent.id), **options
  end
end
