# frozen_string_literal: true

class BriefingsController < ApplicationController
  def create
    if params[:object_type].present?
      record = Crm::ModelRegistry.model_for(params[:object_type]).find(params[:record_id])
      authorize record, :ai_context?
      result = Crm::AI::Briefing.new(identity: pundit_user).record(object_type: params[:object_type], id: params[:record_id])
    else
      authorize :home, :show?
      snapshot = Crm::DashboardSnapshot.new(identity: pundit_user).call
      result = Crm::AI::Briefing.new(identity: pundit_user).dashboard(snapshot: snapshot.to_h)
    end
    @content = result.success? ? result.value.fetch(:content) : nil
    @error = result.errors.to_sentence if result.failure?
    render partial: "briefings/result", locals: {content: @content, error: @error,
      object_type: params[:object_type], record_id: params[:record_id]}
  end

  def coaching
    opportunity = Pundit.policy_scope!(pundit_user, Opportunity).find(params[:opportunity_id])
    authorize opportunity, :ai_context?
    result = Crm::AI::Narratives.new(identity: pundit_user).coaching(opportunity_id: opportunity.id)
    render_narrative(result, frame_id: "pipeline_coaching_#{opportunity.id}", title: "Pipeline coaching")
  end

  def performance
    profile = UserProfile.find(params.fetch(:profile_id, current_profile.id))
    authorize profile
    result = Crm::AI::Narratives.new(identity: pundit_user).performance(profile:)
    render_narrative(result, frame_id: "performance_narrative_#{profile.id}", title: "Performance narrative")
  end

  private

  def render_narrative(result, frame_id:, title:)
    render partial: "briefings/narrative", locals: {frame_id:, title:,
      content: (result.value[:content] if result.success?), error: (result.errors.to_sentence if result.failure?)}
  end
end
