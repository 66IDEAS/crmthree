# frozen_string_literal: true

class ReplicationConfigsController < ApplicationController
  def create
    config = ReplicationConfig.new(config_params)
    authorize config
    if config.save
      redirect_to settings_path(anchor: "replication"), notice: "Replication source saved."
    else
      redirect_to settings_path(anchor: "replication"), alert: config.errors.full_messages.to_sentence
    end
  rescue JSON::ParserError
    redirect_to settings_path(anchor: "replication"), alert: "Request body, mapping, and credentials must be valid JSON."
  end

  def destroy
    config = ReplicationConfig.find(params[:id])
    authorize config
    config.destroy!
    redirect_to settings_path(anchor: "replication"), notice: "Replication source removed.", status: :see_other
  end

  def run
    config = ReplicationConfig.find(params[:id])
    authorize config, :update?
    key = params[:idempotency_key].presence || "manual-#{Time.current.strftime("%Y%m%d%H%M")}"
    existing = ReplicationRun.find_by(replication_config: config, idempotency_key: key)
    run = existing || ReplicationRun.create!(replication_config: config, user_profile: current_profile,
      status: "Queued", idempotency_key: key)
    ReplicationJob.perform_later(run.id) unless existing
    redirect_to settings_path(anchor: "replication"), notice: existing ? "This run is already queued." : "Replication queued. Refresh to see its summary."
  end

  private

  def config_params
    input = params.require(:replication_config).permit(:object_type, :endpoint_url, :key_field,
      :source_key_field, :delete_flag_field, :active, :request_body, :field_mapping, :auth_config).to_h
    %w[request_body field_mapping].each { |field| input[field] = input[field].blank? ? {} : JSON.parse(input[field]) }
    input["auth_config"] = input["auth_config"].presence && JSON.generate(JSON.parse(input["auth_config"]))
    input
  end
end
