# frozen_string_literal: true

class AIProviderConfigsController < ApplicationController
  before_action :load_config, only: %i[update destroy]

  def create
    @config = AIProviderConfig.new(config_params)
    authorize @config
    save_and_return(@config, "AI provider saved.")
  end

  def update
    authorize @config
    attributes = config_params
    attributes.delete("api_key") if attributes["api_key"].blank?
    @config.assign_attributes(attributes)
    save_and_return(@config, "AI provider updated.")
  end

  def destroy
    authorize @config
    @config.destroy!
    redirect_to settings_path(anchor: "ai-providers"), notice: "AI provider removed.", status: :see_other
  end

  private

  def load_config = @config = AIProviderConfig.find(params[:id])
  def config_params = params.require(:ai_provider_config).permit(:provider, :model, :api_key, :endpoint_url, :is_active).to_h

  def save_and_return(record, notice)
    if record.save
      redirect_to settings_path(anchor: "ai-providers"), notice:
    else
      redirect_to settings_path(anchor: "ai-providers"), alert: record.errors.full_messages.to_sentence
    end
  end
end
