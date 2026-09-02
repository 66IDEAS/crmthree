# frozen_string_literal: true

class DocumentConversionsController < ApplicationController
  def create
    source = conversion_source
    authorize source, :show?
    result = Crm::Sales::DocumentConverter.new(
      source_type: source.class.name,
      source_id: source.id,
      target_type: params[:target_type],
      idempotency_key: params.require(:conversion).permit(:idempotency_key)[:idempotency_key],
      identity: pundit_user
    ).call

    if result.success?
      target = result.value.stringify_keys
      redirect_to record_path(object_type: target.fetch("target_type"), id: target.fetch("target_id")),
        notice: "#{target.fetch("target_type").underscore.humanize} created successfully."
    else
      redirect_to record_path(object_type: source.class.name, id: source.id),
        alert: result.errors.to_sentence.presence || "Document could not be created."
    end
  end

  private

  def conversion_source
    allowed = Crm::Sales::DocumentConverter::TARGETS
    source_type = params[:source_type].to_s
    source_model = Crm::Sales::Pricing::PARENT_MODELS[source_type]
    raise ActiveRecord::RecordNotFound unless allowed.key?(source_type) && source_model

    source_model.find(params[:source_id])
  end
end
