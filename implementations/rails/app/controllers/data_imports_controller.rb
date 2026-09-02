# frozen_string_literal: true

class DataImportsController < ApplicationController
  before_action :load_run, only: %i[show create]

  def preview
    authorize ImportRun, :create?
    result = Crm::CSVImport.preview(
      file: params[:file], object_type: params.require(:object_type), actor: current_profile
    )
    if result.success?
      @import_run = result.value
      @definition = Crm::ModelRegistry.fetch(@import_run.object_type)
      render :preview
    else
      redirect_to settings_path(anchor: "data-import"), alert: result.errors.to_sentence
    end
  end

  def create
    authorize @import_run, :update?
    result = Crm::CSVImport.queue(run: @import_run, mapping: mapping_params)
    if result.success?
      redirect_to data_import_path(@import_run), notice: "Import queued."
    else
      @definition = Crm::ModelRegistry.fetch(@import_run.object_type)
      flash.now[:alert] = result.errors.to_sentence
      render :preview, status: result.status
    end
  end

  def show
    authorize @import_run
    respond_to do |format|
      format.html
      format.json do
        render json: @import_run.as_json(only: %i[status total_rows processed_rows created_count skipped_count error_details])
          .merge("status" => @import_run.status.humanize, "progress_percent" => @import_run.progress_percent)
      end
    end
  end

  private

  def load_run
    @import_run = ImportRun.find(params[:id])
  end

  def mapping_params
    source = params.fetch(:mapping, ActionController::Parameters.new)
    Crm::ModelRegistry.writable_fields(@import_run.object_type).to_h do |field|
      name = field.fetch("name")
      values = source.fetch(name, ActionController::Parameters.new).permit(:mode, :value).to_h
      [name, values]
    end
  end
end
