# frozen_string_literal: true

class IntakeDraftsController < ApplicationController
  before_action :load_draft, only: %i[show apply reject]

  def index
    @drafts = policy_scope(IntakeDraft).order(created_at: :desc).limit(100)
    authorize IntakeDraft, :create?
  end

  def create
    draft = IntakeDraft.new(user_profile: current_profile, kind: params[:kind])
    authorize draft
    content = uploaded_content || params[:content]
    Current.set(profile: current_profile) do
      draft.update!(source: params[:source].to_s.slice(0, 500), preview: "Extraction is processing…",
        metadata: {"state" => "Processing", "content" => content.to_s})
    end
    IntakeExtractionJob.perform_later(draft.id)
    redirect_to intake_draft_path(draft), notice: "Extraction queued. Nothing will be saved to CRM until you review it."
  end

  def show
    authorize @draft
  end

  def apply
    authorize @draft, :update?
    unless @draft.metadata.to_h["state"] == "Ready"
      redirect_to intake_draft_path(@draft), alert: "Extraction is not ready for confirmation yet."
      return
    end
    fields = JSON.parse(params.require(:fields_json))
    result = Crm::Intake::Applicator.new(draft: @draft, identity: pundit_user).call(fields:)
    if result.success?
      redirect_to record_path(object_type: @draft.object_type, id: result.value.id), notice: "Reviewed intake saved."
    else
      redirect_to intake_draft_path(@draft), alert: result.errors.to_sentence
    end
  rescue JSON::ParserError
    redirect_to intake_draft_path(@draft), alert: "Fields must be valid JSON."
  end

  def reject
    authorize @draft, :update?
    Current.set(profile: current_profile) { @draft.update!(status: "Rejected") }
    redirect_to intake_drafts_path, notice: "Draft rejected; no CRM record was changed."
  end

  private

  def load_draft = @draft = policy_scope(IntakeDraft).find(params[:id])

  def uploaded_content
    file = params[:file]
    return unless file
    raise ActionController::BadRequest, "File exceeds 5 MB" if file.size > 5.megabytes

    "Uploaded #{file.original_filename} (#{file.content_type}) as base64 data:\n#{Base64.strict_encode64(file.read)}"
  end
end
