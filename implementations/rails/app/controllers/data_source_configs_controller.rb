# frozen_string_literal: true

class DataSourceConfigsController < ApplicationController
  before_action :load_config, only: %i[update destroy]

  def create
    @config = DataSourceConfig.new(parsed_params)
    authorize @config
    save_and_return(@config, "Data source saved.")
  end

  def update
    authorize @config
    @config.assign_attributes(parsed_params)
    save_and_return(@config, "Data source updated.")
  end

  def destroy
    authorize @config
    @config.destroy!
    redirect_to settings_path(anchor: "data-sources"), notice: "Data source removed.", status: :see_other
  end

  private

  def load_config = @config = DataSourceConfig.find(params[:id])

  def parsed_params
    input = params.require(:data_source_config).permit(:object_type, :source_type, :endpoint_url, :auth_type,
      :auth_config, :field_mapping, :active).to_h
    %w[auth_config field_mapping].each do |field|
      next unless input[field].is_a?(String)
      if input[field].blank? && field == "auth_config" && @config&.persisted?
        input.delete(field)
        next
      end

      input[field] = input[field].blank? ? {} : JSON.parse(input[field])
    end
    input.delete("auth_type") if input["auth_type"].blank?
    input
  rescue JSON::ParserError
    raise ActionController::BadRequest, "Credentials and field mappings must be valid JSON"
  end

  def save_and_return(record, notice)
    if record.save
      redirect_to settings_path(anchor: "data-sources"), notice:
    else
      redirect_to settings_path(anchor: "data-sources"), alert: record.errors.full_messages.to_sentence
    end
  end
end
