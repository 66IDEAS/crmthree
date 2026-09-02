# frozen_string_literal: true

class GamificationSettingsController < ApplicationController
  MODELS = {"XPEvent" => XPEvent, "LevelDefinition" => LevelDefinition, "Badge" => Badge}.freeze

  def initialize_defaults
    authorize XPEvent, :create?
    Crm::Seeds.run!
    redirect_to settings_path(anchor: "gamification"), notice: "Gamification defaults initialized."
  end

  def update
    model = MODELS.fetch(params.require(:object_type))
    record = model.find(params.require(:id))
    authorize record, :update?
    result = Crm::Data::LocalActiveRecordAdapter.new(object_type: model.name, identity: pundit_user).update(record.id, attributes_for(model))
    redirect_to settings_path(anchor: "gamification"), **(result.success? ? {notice: "Gamification setting updated."} : {alert: result.errors.to_sentence})
  rescue KeyError
    raise ActiveRecord::RecordNotFound
  rescue JSON::ParserError => error
    redirect_to settings_path(anchor: "gamification"), alert: "Gamification JSON is invalid: #{error.message}"
  end

  private

  def attributes_for(model)
    source = params.require(:setting)
    case model.name
    when "XPEvent"
      source.permit(:description, :xp_value, :active).to_h
    when "LevelDefinition"
      values = source.permit(:name, :xp_threshold, :unlocks).to_h
      values["unlocks"] = JSON.parse(values["unlocks"]) if values["unlocks"].present?
      values
    when "Badge"
      source.permit(:name, :description, :category, :criteria, :active).to_h.tap do |values|
        values["criteria"] = JSON.parse(values["criteria"]) if values["criteria"].present?
      end
    end
  end
end
