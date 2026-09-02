# frozen_string_literal: true

class IntakeExtractionJob < ApplicationJob
  queue_as :integrations

  def perform(draft_id)
    draft = IntakeDraft.find(draft_id)
    identity = Crm::AuthorizationContext.for_profile(draft.user_profile)
    metadata = draft.metadata.to_h
    result = Crm::Intake::Extractor.new(identity:, draft:).call(kind: draft.kind, source: draft.source,
      content: metadata["content"])
    return if result.success?

    Current.set(profile: draft.user_profile) do
      draft.update!(preview: result.errors.to_sentence, metadata: {"state" => "Failed", "review_required" => true})
    end
  end
end
