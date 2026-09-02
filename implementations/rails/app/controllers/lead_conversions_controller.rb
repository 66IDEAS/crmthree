# frozen_string_literal: true

class LeadConversionsController < ApplicationController
  def create
    lead = Lead.find(params[:lead_id])
    authorize lead, :update?
    conversion = params.require(:conversion).permit(:account_name, :create_opportunity, :opportunity_name, :idempotency_key)
    result = Crm::Sales::LeadConverter.new(
      lead_id: lead.id,
      account_name: conversion[:account_name],
      create_opportunity: conversion[:create_opportunity],
      opportunity_name: conversion[:opportunity_name],
      idempotency_key: conversion[:idempotency_key],
      identity: pundit_user
    ).call

    if result.success?
      target = result.value.stringify_keys
      redirect_to record_path(object_type: target.fetch("target_type"), id: target.fetch("target_id")), notice: "Lead converted successfully."
    else
      redirect_to record_path(object_type: "Lead", id: lead.id), alert: result.errors.to_sentence.presence || "Lead could not be converted."
    end
  end
end
