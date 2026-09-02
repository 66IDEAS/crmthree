# frozen_string_literal: true

class ListSortSettingsController < ApplicationController
  def update
    authorize :list_sort_setting, :update?
    result = Crm::ListSort.update(
      object_type: params[:object_type],
      sort_by: params.require(:list_sort_setting).require(:sort_by),
      direction: params.require(:list_sort_setting).require(:direction),
      actor: current_profile
    )
    redirect_to settings_path, **flash_for(result)
  end

  def repair
    authorize :list_sort_setting, :update?
    result = Crm::AutoNumberRepair.call(object_type: params[:object_type], actor: current_profile)
    message = result.success? ? "Repaired #{result.value} missing numbers." : result.errors.to_sentence
    redirect_to settings_path, (result.success? ? {notice: message} : {alert: message})
  end

  private

  def flash_for(result)
    result.success? ? {notice: "List sorting updated."} : {alert: result.errors.to_sentence.presence || "List sorting could not be updated."}
  end
end
