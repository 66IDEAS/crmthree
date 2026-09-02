# frozen_string_literal: true

class RecordLocksController < ApplicationController
  before_action :load_record

  def create
    authorize @record, :update?
    render_result(Crm::RecordLocks.acquire(**lock_arguments))
  end

  def update
    authorize @record, :update?
    render_result(Crm::RecordLocks.renew(**lock_arguments))
  end

  def destroy
    authorize @record, :update?
    render_result(Crm::RecordLocks.release(**lock_arguments))
  end

  private

  def load_record
    @object_type = params[:object_type]
    @record = Crm::ModelRegistry.model_for(@object_type).find(params[:record_id])
  end

  def lock_arguments
    {object_type: @object_type, record_id: @record.id, holder: current_profile}
  end

  def render_result(result)
    if result.success?
      head :no_content
    else
      render json: {errors: result.errors}, status: result.status
    end
  end
end
