# frozen_string_literal: true

class TranslationsController < ApplicationController
  before_action :load_translation, only: %i[edit update destroy ai_translate]

  def create
    translation = Translation.new(translation_identity_params.merge(labels: {}))
    authorize translation
    translation.save!
    redirect_to edit_translation_path(translation), notice: "Language added."
  rescue ActiveRecord::RecordInvalid => error
    redirect_to settings_path(anchor: "language-management"), alert: error.record.errors.full_messages.to_sentence
  end

  def edit
    authorize @translation
    @catalog = Crm::LabelCatalog.all
  end

  def update
    authorize @translation
    submitted = params.fetch(:labels, {}).permit(*Crm::LabelCatalog.all.keys).to_h
    @translation.update!(labels: @translation.labels.to_h.merge(submitted))
    redirect_to edit_translation_path(@translation), notice: "Translations saved."
  rescue ActiveRecord::RecordInvalid => error
    @catalog = Crm::LabelCatalog.all
    flash.now[:alert] = error.record.errors.full_messages.to_sentence
    render :edit, status: :unprocessable_entity
  end

  def destroy
    authorize @translation
    @translation.destroy!
    redirect_to settings_path(anchor: "language-management"), notice: "Language removed. Bundled packs will not recreate an administrator-deleted language."
  end

  def ai_translate
    authorize @translation, :update?
    result = Crm::AI::TranslationBatch.new(translation: @translation).call
    if result.success?
      redirect_to edit_translation_path(@translation), notice: "AI translated #{result.value[:translated]} missing labels."
    else
      progress = result.value.is_a?(Hash) ? " #{result.value[:translated]} labels were saved before the failure." : ""
      redirect_to edit_translation_path(@translation), alert: "#{result.errors.to_sentence}#{progress}"
    end
  end

  private

  def load_translation
    @translation = Translation.find(params[:id])
  end

  def translation_identity_params
    params.require(:translation).permit(:language_code, :language_name).tap do |values|
      values[:language_code] = values[:language_code].to_s.downcase.strip
    end
  end
end
